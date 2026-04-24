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

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
        const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

        const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
            auth: { 
                autoRefreshToken: false, 
                persistSession: false,
                detectSessionInUrl: false,
            },
            db: {
                schema: 'public',
            },
            global: {
                headers: {
                    Authorization: `Bearer ${supabaseServiceKey}`,
                },
            },
        });

        const body = await req.json();
        const { students } = body;

        if (!students || !Array.isArray(students) || students.length === 0) {
            return new Response(
                JSON.stringify({ error: "Data siswa tidak boleh kosong" }),
                { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        const results = [];

        for (const student of students as StudentData[]) {
            const { nama, nisn, kelas, password, company_id } = student;

            if (!nama || !nisn || !kelas) {
                results.push({ success: false, nisn: nisn || '', nama: nama || '', error: "Nama, NISN, dan Kelas wajib diisi" });
                continue;
            }

            const email = `${nisn}@siswa.com`;
            const defaultPassword = `${nisn}Sip`;

            try {
                // 1. Buat auth user
                const { data: authData, error: createUserError } = await supabaseAdmin.auth.admin.createUser({
                    email,
                    password: password || defaultPassword,
                    email_confirm: true,
                    user_metadata: {
                        full_name: nama,
                        nisn,
                        class_name: kelas,
                    },
                });

                if (createUserError) {
                    results.push({ success: false, nisn, nama, error: createUserError.message });
                    continue;
                }

                const userId = authData.user.id;

                // 2. Upsert profile
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

                // 3. Insert placement jika ada company_id
                if (company_id) {
                    await supabaseAdmin.from("placements").insert({
                        student_id: userId,
                        company_id,
                    });
                }

                results.push({ success: true, nisn, nama, id: userId });

            } catch (err) {
                results.push({
                    success: false,
                    nisn,
                    nama,
                    error: err instanceof Error ? err.message : "Unknown error"
                });
            }
        }

        const successCount = results.filter((r: any) => r.success).length;
        const failureCount = results.filter((r: any) => !r.success).length;

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
        return new Response(
            JSON.stringify({ error: error instanceof Error ? error.message : "Internal server error" }),
            { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }
});