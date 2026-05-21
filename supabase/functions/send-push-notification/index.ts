import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── JWT untuk FCM v1 API ──────────────────────────────────────────────────────
async function getAccessToken(): Promise<string> {
  const privateKey = Deno.env.get("FCM_PRIVATE_KEY")!.replace(/\\n/g, "\n");
  const clientEmail = Deno.env.get("FCM_CLIENT_EMAIL")!;

  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: clientEmail,
    sub: clientEmail,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  const encode = (obj: object) => btoa(JSON.stringify(obj)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

  const signingInput = `${encode(header)}.${encode(payload)}`;

  // Import private key
  const pemContents = privateKey.replace("-----BEGIN PRIVATE KEY-----", "").replace("-----END PRIVATE KEY-----", "").replace(/\s/g, "");

  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey("pkcs8", binaryDer, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);

  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", cryptoKey, new TextEncoder().encode(signingInput));

  const jwt = `${signingInput}.${btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "")}`;

  // Exchange JWT for access token
  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenRes.json();
  return tokenData.access_token;
}

// ── Kirim FCM ─────────────────────────────────────────────────────────────────
async function sendFcm(fcmToken: string, title: string, body: string, data?: Record<string, string>) {
  const projectId = Deno.env.get("FCM_PROJECT_ID")!;
  const accessToken = await getAccessToken();

  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: {
        token: fcmToken,
        notification: { title, body },
        android: {
          notification: {
            channel_id: "sip_smea_channel",
            priority: "high",
          },
        },
        data: data ?? {},
      },
    }),
  });

  return res.json();
}

// ── Main handler ──────────────────────────────────────────────────────────────
serve(async (req) => {
  try {
    const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

    const { type, userId, title, body, data } = await req.json();

    if (!userId || !title || !body) {
      return new Response(JSON.stringify({ error: "userId, title, body required" }), { status: 400 });
    }

    // Ambil FCM token dari profiles
    const { data: profile, error } = await supabase.from("profiles").select("fcm_token").eq("id", userId).single();

    if (error || !profile?.fcm_token) {
      return new Response(JSON.stringify({ error: "FCM token not found", detail: error }), { status: 404 });
    }

    const result = await sendFcm(profile.fcm_token, title, body, data);

    return new Response(JSON.stringify({ success: true, result }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
