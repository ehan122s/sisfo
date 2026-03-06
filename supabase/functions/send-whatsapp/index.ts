import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { phoneNumber, message } = await req.json()

    if (!phoneNumber || !message) {
      throw new Error('Missing phoneNumber or message')
    }

    // Format phone number: 08xx -> 628xx
    let formattedPhone = phoneNumber.toString().replace(/\D/g, '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '62' + formattedPhone.slice(1);
    }

    // 1. Get Config from Database
    const { data: config, error: configError } = await supabaseClient
      .from('app_config')
      .select('key, value')
      .in('key', ['WA_GATEWAY_URL', 'WA_API_KEY'])

    if (configError) throw configError

    const gatewayUrl = config.find(c => c.key === 'WA_GATEWAY_URL')?.value
    const apiKey = config.find(c => c.key === 'WA_API_KEY')?.value

    if (!gatewayUrl || !apiKey) {
      console.error('Missing WA Config')
      return new Response(JSON.stringify({ error: 'WA Config Not Found' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500
      })
    }

    // --- Authentication Check ---
    const authHeader = req.headers.get("Authorization");
    const internalSecret = req.headers.get("x-internal-secret");
    let isAuthenticated = false;

    // A. Check for Internal Secret (Bypass for System Calls)
    if (internalSecret && internalSecret === apiKey) {
      console.log("Authenticated via Internal Secret");
      isAuthenticated = true;
    }
    // B. Check for User JWT (For Admin Web calls)
    else if (authHeader) {
      const jwt = authHeader.replace("Bearer ", "");
      const { data: { user }, error: userError } = await supabaseClient.auth.getUser(jwt); // Use supabaseAdmin for getUser? NO, we used createClient above which is supabaseClient
      // Actually we need to be careful. The `createClient` above uses Service Role Key?
      // Yes: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
      // So `supabaseClient` IS `supabaseAdmin`.

      if (!userError && user) {
        const { data: profile } = await supabaseClient
          .from("profiles")
          .select("role")
          .eq("id", user.id)
          .single();

        if (profile?.role === "admin") {
          isAuthenticated = true;
        }
      }
    }

    if (!isAuthenticated) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    // ---------------------------

    // 2. Send to WhatsApp Gateway (Generic Fonnte/Wablas Style)
    // Fonnte prefers FormData or JSON with specific structure. switching to FormData.
    console.log(`Sending WA to ${formattedPhone} via ${gatewayUrl}`)

    const form = new FormData();
    form.append('target', formattedPhone);
    form.append('message', message);
    form.append('countryCode', '62');

    const response = await fetch(gatewayUrl, {
      method: 'POST',
      headers: {
        'Authorization': apiKey,
        // Content-Type is set automatically for FormData
      },
      body: form,
    })

    const result = await response.text()
    console.log('WA Gateway Response:', result)

    return new Response(JSON.stringify({ success: true, result }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    console.error(error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
