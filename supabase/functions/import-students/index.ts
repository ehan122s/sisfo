import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface StudentData {
    nama: string;
    nisn: string;
    kelas: string;
    password?: string;
    company_id?: number;
    phone_number?: string;
    parent_phone_number?: string;
    nipd?: string;
    gender?: "L" | "P";
    birth_place?: string;
    birth_date?: string;
    nik?: string;
    religion?: string;
    address?: string;
    father_name?: string;
    mother_name?: string;
}

interface ImportResult {
    success: boolean;
    nisn: string;
    nama: string;
    error?: string;
}

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
    // Handle CORS preflight
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        // Get auth header
        const authHeader = req.headers.get("Authorization");
        if (!authHeader) {
            return new Response(
                JSON.stringify({ error: "Missing Authorization header" }),
                { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        // Create admin client with service role
        const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
        const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

        const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
            auth: { autoRefreshToken: false, persistSession: false },
        });

        // Extract JWT and get user info using admin client
        const jwt = authHeader.replace("Bearer ", "");
        const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(jwt);

        if (userError || !user) {
            console.error("Auth Error:", userError); // Debug log
            console.log("Has Service Key:", !!supabaseServiceKey); // Debug log

            return new Response(
                JSON.stringify({ error: "Invalid or expired token", details: userError }),
                { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        // Check admin role using service role client
        const { data: profile, error: profileError } = await supabaseAdmin
            .from("profiles")
            .select("role")
            .eq("id", user.id)
            .single();

        if (profileError || profile?.role !== "admin") {
            return new Response(
                JSON.stringify({ error: "Admin access required" }),
                { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        // --- Rate Limiting Check ---
        // Importing dynamically or relatively.
        // Assuming _shared is at ../_shared/rate-limit.ts relative to import-students/index.ts
        const { checkRateLimit } = await import("../_shared/rate-limit.ts");

        // Limit: 20 requests per 1 minute per user
        const limitCheck = await checkRateLimit(supabaseAdmin, `import_students:${user.id}`, 20, 60);

        if (limitCheck.blocked) {
            return new Response(
                JSON.stringify({
                    error: "Rate limit exceeded. Please try again later.",
                    resetTime: limitCheck.resetTime
                }),
                { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }
        // ---------------------------

        // Parse request body
        const body = await req.json();

        // --- Validation ---
        const { importRequestSchema } = await import("../_shared/schemas.ts");
        const validation = importRequestSchema.safeParse(body);

        if (!validation.success) {
            return new Response(
                JSON.stringify({
                    error: "Validation failed",
                    issues: validation.error.format()
                }),
                { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        const { students } = validation.data;
        // ------------------

        const results: ImportResult[] = [];
        const defaultPassword = "siswapkl2026";

        for (const student of students) {
            const { nama, nisn, kelas, password, company_id } = student;
            const email = `${nisn}@siswa.com`;
            // Password must meet complexity: min 8, Upper, Lower, Number in total with NISN
            const strongDefaultPassword = `${nisn}Sip`;

            try {
                // 1. Create auth user with Admin API
                const { data: authData, error: createUserError } = await supabaseAdmin.auth.admin.createUser({
                    email,
                    password: password || strongDefaultPassword,  // Use strong default
                    email_confirm: true,
                    user_metadata: {
                        full_name: nama,
                        nisn,
                        class_name: kelas,
                        phone_number: student.phone_number,
                        nipd: student.nipd,
                        gender: student.gender,
                    },
                });

                if (createUserError) {
                    results.push({ success: false, nisn, nama, error: createUserError.message });
                    continue;
                }

                const userId = authData.user.id;

                // 2. Upsert profile (trigger might create it, so we update)
                const { error: profileError } = await supabaseAdmin
                    .from("profiles")
                    .upsert({
                        id: userId,
                        full_name: nama,
                        nisn,
                        class_name: kelas,
                        phone_number: student.phone_number,
                        parent_phone_number: student.parent_phone_number,
                        role: "student",
                        status: "active",
                        nipd: student.nipd,
                        gender: student.gender,
                        birth_place: student.birth_place,
                        birth_date: student.birth_date,
                        nik: student.nik,
                        religion: student.religion,
                        address: student.address,
                        father_name: student.father_name,
                        mother_name: student.mother_name,
                    }, { onConflict: "id" });

                if (profileError) {
                    results.push({ success: false, nisn, nama, error: `Profile: ${profileError.message}` });
                    continue;
                }

                // 3. Insert placement if company_id provided
                if (company_id) {
                    const { error: placementError } = await supabaseAdmin
                        .from("placements")
                        .insert({
                            student_id: userId,
                            company_id,
                        });

                    if (placementError) {
                        // Placement error is non-fatal, user is still created
                        results.push({
                            success: true,
                            nisn,
                            nama,
                            error: `Warning: Placement failed - ${placementError.message}`
                        });
                        continue;
                    }
                }

                results.push({ success: true, nisn, nama });
            } catch (err) {
                results.push({
                    success: false,
                    nisn,
                    nama,
                    error: err instanceof Error ? err.message : "Unknown error"
                });
            }
        }

        const successCount = results.filter(r => r.success).length;
        const failureCount = results.filter(r => !r.success).length;

        return new Response(
            JSON.stringify({
                message: `Import completed: ${successCount} success, ${failureCount} failed`,
                successCount,
                failureCount,
                results,
            }),
            { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    } catch (error) {
        // Importing dynamically to avoid top-level await issues if any
        const { logger } = await import("../_shared/logger.ts");
        logger.error("Edge Function error:", error);

        return new Response(
            JSON.stringify({ error: error instanceof Error ? error.message : "Internal server error" }),
            { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }
});
