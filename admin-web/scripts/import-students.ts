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

if (!serviceRoleKey) {
    console.error('❌ SERVICE_ROLE_KEY tidak ditemukan di .env.local');
    process.exit(1);
}

// Create Supabase Admin client with service role key
const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
        autoRefreshToken: false,
        persistSession: false
    }
});

// Config
const EMAIL_DOMAIN = 'pkl.com';
const DEFAULT_PASSWORD = 'siswapkl2026';
const PKL_START_DATE = '2025-01-13';
const PKL_END_DATE = '2025-04-30';

interface StudentRow {
    no: number;
    class_name: string;
    full_name: string;
    company_name: string;
    supervisor: string;
    address: string;
}

async function importStudents() {
    console.log('🚀 Memulai import siswa PKL...\n');

    // Read Excel file
    const xlsxPath = '/Users/suhendararyadi/Documents/Belajar Coding/E-PKL/DATA PKL TEI 2025 V.5.xlsx';
    const workbook = XLSX.readFile(xlsxPath);
    const sheet = workbook.Sheets[workbook.SheetNames[0]];
    const rows = XLSX.utils.sheet_to_json(sheet, { header: 1 }) as (string | number)[][];

    // Parse rows (skip header)
    const students: StudentRow[] = rows.slice(1)
        .filter(row => row[0] && row[2]) // Filter empty rows
        .map(row => ({
            no: Number(row[0]),
            class_name: String(row[1]).trim(),
            full_name: String(row[2]).trim(),
            company_name: String(row[3]).trim(),
            supervisor: String(row[4] || '').trim(),
            address: String(row[5] || '').trim(),
        }));

    console.log(`📋 Ditemukan ${students.length} siswa dalam file Excel\n`);

    // Get company mapping
    const { data: companies } = await supabase.from('companies').select('id, name');
    const companyMap = new Map(companies?.map(c => [c.name.toLowerCase(), c.id]) || []);

    console.log(`🏢 Ditemukan ${companyMap.size} perusahaan di database\n`);

    // Stats
    let successCount = 0;
    let skipCount = 0;
    let errorCount = 0;
    const results: { nisn: string; email: string; name: string; status: string }[] = [];

    for (const student of students) {
        // Generate NISN from row number (you can adjust this logic)
        const nisn = `PKL${String(student.no).padStart(3, '0')}`;
        const email = `${nisn.toLowerCase()}@${EMAIL_DOMAIN}`;

        // Check if user already exists
        const { data: existingProfile } = await supabase
            .from('profiles')
            .select('id')
            .eq('nisn', nisn)
            .single();

        if (existingProfile) {
            console.log(`⏭️  Skip: ${student.full_name} (sudah ada)`);
            skipCount++;
            results.push({ nisn, email, name: student.full_name, status: 'SKIP - Sudah ada' });
            continue;
        }

        try {
            // Step 1: Create Auth User
            const { data: authData, error: authError } = await supabase.auth.admin.createUser({
                email: email,
                password: DEFAULT_PASSWORD,
                email_confirm: true, // Auto confirm email
                user_metadata: {
                    full_name: student.full_name,
                    class_name: student.class_name,
                    nisn: nisn
                }
            });

            if (authError) {
                if (authError.message.includes('already been registered')) {
                    console.log(`⏭️  Skip: ${student.full_name} (email sudah terdaftar)`);
                    skipCount++;
                    results.push({ nisn, email, name: student.full_name, status: 'SKIP - Email sudah ada' });
                } else {
                    console.error(`❌ Error Auth: ${student.full_name} - ${authError.message}`);
                    errorCount++;
                    results.push({ nisn, email, name: student.full_name, status: `ERROR - ${authError.message}` });
                }
                continue;
            }

            const userId = authData.user?.id;
            if (!userId) {
                console.error(`❌ Error: User ID tidak didapat untuk ${student.full_name}`);
                errorCount++;
                continue;
            }

            // Step 2: Update Profile (upsert to handle trigger-created profiles)
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
                console.error(`❌ Error Profile: ${student.full_name} - ${profileError.message}`);
                errorCount++;
                results.push({ nisn, email, name: student.full_name, status: `ERROR - ${profileError.message}` });
                continue;
            }

            // Step 3: Create Placement
            const companyId = companyMap.get(student.company_name.toLowerCase());
            if (companyId) {
                await supabase
                    .from('placements')
                    .insert({
                        student_id: userId,
                        company_id: companyId,
                        start_date: PKL_START_DATE,
                        end_date: PKL_END_DATE
                    });
            } else {
                console.warn(`⚠️  Warning: Company "${student.company_name}" tidak ditemukan`);
            }

            console.log(`✅ Import: ${student.full_name} → ${student.company_name}`);
            successCount++;
            results.push({ nisn, email, name: student.full_name, status: 'SUCCESS' });

        } catch (err) {
            console.error(`❌ Error: ${student.full_name} -`, err);
            errorCount++;
            results.push({ nisn, email, name: student.full_name, status: `ERROR - ${err}` });
        }
    }

    // Summary
    console.log('\n' + '='.repeat(60));
    console.log('📊 RINGKASAN IMPORT');
    console.log('='.repeat(60));
    console.log(`Total siswa dalam file : ${students.length}`);
    console.log(`✅ Berhasil import     : ${successCount}`);
    console.log(`⏭️  Dilewati (sudah ada): ${skipCount}`);
    console.log(`❌ Error               : ${errorCount}`);
    console.log('='.repeat(60));
    console.log(`\n📧 Format Login:`);
    console.log(`   Email    : [NISN]@${EMAIL_DOMAIN}`);
    console.log(`   Password : ${DEFAULT_PASSWORD}`);
    console.log(`   Contoh   : pkl001@${EMAIL_DOMAIN}`);
    console.log('='.repeat(60));

    // Export results to CSV for reference
    const csvContent = 'NISN,Email,Nama,Status\n' +
        results.map(r => `${r.nisn},${r.email},"${r.name}",${r.status}`).join('\n');

    const fs = await import('fs');
    fs.writeFileSync(path.join(__dirname, 'import-results.csv'), csvContent);
    console.log(`\n📄 Hasil import disimpan di: scripts/import-results.csv`);
}

importStudents().catch(console.error);
