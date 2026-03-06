import XLSX from 'xlsx';
import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';
import * as path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load .env.local
dotenv.config({ path: path.join(__dirname, '..', '.env.local') });

const supabaseUrl = process.env.VITE_SUPABASE_URL!;
const serviceRoleKey = process.env.SERVICE_ROLE_KEY!;

const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false }
});

const EMAIL_DOMAIN = 'pkl.com';
const PKL_START_DATE = '2025-01-13';
const PKL_END_DATE = '2025-04-30';

interface StudentRow {
    no: number;
    class_name: string;
    full_name: string;
    company_name: string;
}

async function updateProfiles() {
    console.log('🔄 Updating profiles dan placements untuk auth users yang sudah ada...\n');

    // Read Excel file
    const xlsxPath = '/Users/suhendararyadi/Documents/Belajar Coding/E-PKL/DATA PKL TEI 2025 V.5.xlsx';
    const workbook = XLSX.readFile(xlsxPath);
    const sheet = workbook.Sheets[workbook.SheetNames[0]];
    const rows = XLSX.utils.sheet_to_json(sheet, { header: 1 }) as (string | number)[][];

    const students: StudentRow[] = rows.slice(1)
        .filter(row => row[0] && row[2])
        .map(row => ({
            no: Number(row[0]),
            class_name: String(row[1]).trim(),
            full_name: String(row[2]).trim(),
            company_name: String(row[3]).trim(),
        }));

    console.log(`📋 ${students.length} siswa dalam file\n`);

    // Get company mapping
    const { data: companies } = await supabase.from('companies').select('id, name');
    const companyMap = new Map(companies?.map(c => [c.name.toLowerCase(), c.id]) || []);

    // Get all auth users with their emails
    const { data: authUsers } = await supabase.auth.admin.listUsers();
    const userMap = new Map(authUsers?.users.map(u => [u.email?.toLowerCase() || '', u.id]) || []);

    console.log(`👥 ${userMap.size} auth users di database\n`);

    let successCount = 0;
    let errorCount = 0;

    for (const student of students) {
        const nisn = `PKL${String(student.no).padStart(3, '0')}`;
        const email = `${nisn.toLowerCase()}@${EMAIL_DOMAIN}`;
        const userId = userMap.get(email);

        if (!userId) {
            console.log(`⏭️  Skip: ${student.full_name} (email ${email} tidak ditemukan)`);
            continue;
        }

        try {
            // Update profile
            const { error: profileError } = await supabase
                .from('profiles')
                .upsert({
                    id: userId,
                    full_name: student.full_name,
                    class_name: student.class_name,
                    nisn: nisn,
                    role: 'student',
                    status: 'active'
                }, { onConflict: 'id' });

            if (profileError) {
                console.error(`❌ Profile Error: ${student.full_name} - ${profileError.message}`);
                errorCount++;
                continue;
            }

            // Create placement
            const companyId = companyMap.get(student.company_name.toLowerCase());
            if (companyId) {
                // Check existing placement
                const { data: existingPlacement } = await supabase
                    .from('placements')
                    .select('id')
                    .eq('student_id', userId)
                    .single();

                if (!existingPlacement) {
                    await supabase.from('placements').insert({
                        student_id: userId,
                        company_id: companyId,
                        start_date: PKL_START_DATE,
                        end_date: PKL_END_DATE
                    });
                }
            } else {
                console.warn(`⚠️  Company "${student.company_name}" tidak ditemukan`);
            }

            console.log(`✅ Updated: ${student.full_name} → ${student.company_name}`);
            successCount++;

        } catch (err) {
            console.error(`❌ Error: ${student.full_name} -`, err);
            errorCount++;
        }
    }

    console.log('\n' + '='.repeat(50));
    console.log('📊 RINGKASAN UPDATE');
    console.log('='.repeat(50));
    console.log(`✅ Berhasil : ${successCount}`);
    console.log(`❌ Error    : ${errorCount}`);
    console.log('='.repeat(50));
}

updateProfiles().catch(console.error);
