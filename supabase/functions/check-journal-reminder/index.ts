import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    const supabase = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    try {
        const today = new Date().toISOString().split('T')[0]
        console.log('Cek jurnal untuk tanggal:', today)

        // Ambil semua siswa yang hadir hari ini
        const { data: hadir, error: hadirError } = await supabase
            .from('attendance_logs')
            .select('student_id, date, created_at')
            .in('status', ['Hadir', 'Terlambat', 'hadir', 'terlambat'])
            .or(`date.eq.${today},created_at.gte.${today}T00:00:00,created_at.lte.${today}T23:59:59`)

        if (hadirError) throw new Error('Gagal ambil data absensi: ' + hadirError.message)
        console.log('Siswa hadir hari ini:', hadir?.length)

        if (!hadir || hadir.length === 0) {
            return new Response(JSON.stringify({ message: 'Tidak ada siswa hadir hari ini' }), {
                status: 200,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            })
        }

        // Deduplicate student_id
        const uniqueStudents = [...new Map(hadir.map(a => [a.student_id, a])).values()]

        // Ambil siswa yang sudah isi jurnal hari ini
        const { data: sudahJurnal, error: jurnalError } = await supabase
            .from('daily_journals')
            .select('student_id')
            .eq('date', today)

        if (jurnalError) throw new Error('Gagal ambil data jurnal: ' + jurnalError.message)

        const sudahJurnalIds = new Set(sudahJurnal?.map(j => j.student_id) ?? [])
        console.log('Siswa sudah isi jurnal:', sudahJurnalIds.size)

        // Filter siswa yang hadir tapi belum isi jurnal
        const belumJurnal = uniqueStudents.filter(a => !sudahJurnalIds.has(a.student_id))
        console.log('Siswa belum isi jurnal:', belumJurnal.length)

        if (belumJurnal.length === 0) {
            return new Response(JSON.stringify({ message: 'Semua siswa sudah isi jurnal' }), {
                status: 200,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            })
        }

        // Ambil config WA
        const { data: configData } = await supabase
            .from('app_config')
            .select('key, value')
            .in('key', ['WA_GATEWAY_URL', 'WA_API_KEY'])

        const gatewayUrl = configData?.find(c => c.key === 'WA_GATEWAY_URL')?.value ?? 'https://api.fonnte.com/send'
        const apiKey = configData?.find(c => c.key === 'WA_API_KEY')?.value

        if (!apiKey) throw new Error('API Key belum diisi di app_config')

        let berhasil = 0
        let gagal = 0

        for (const siswa of belumJurnal) {
            try {
                const { data: profile } = await supabase
                    .from('profiles')
                    .select('full_name, phone_number')
                    .eq('id', siswa.student_id)
                    .single()

                if (!profile?.phone_number) {
                    console.log('Skip siswa', siswa.student_id, '- no HP tidak ada')
                    continue
                }

                const message = `📝 *PKL Reminder*\n\nHai ${profile.full_name}! 👋\n\nKamu *belum mengisi jurnal PKL* hari ini.\n\nJangan lupa segera isi ya sebelum terlambat! 🙏`

                let phone = profile.phone_number.replace(/\D/g, '')
                if (phone.startsWith('0')) phone = '62' + phone.slice(1)
                else if (phone.startsWith('8')) phone = '62' + phone
                else if (!phone.startsWith('62')) phone = '62' + phone

                const fonnteResponse = await fetch(gatewayUrl, {
                    method: 'POST',
                    headers: {
                        'Authorization': apiKey,
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ target: phone, message }),
                })

                const fonnteResult = await fonnteResponse.json()
                console.log('Fonnte result untuk', profile.full_name, ':', JSON.stringify(fonnteResult))

                const isSuccess = fonnteResult.status === true || fonnteResult.status === 'true' || fonnteResult.process === true

                await supabase.from('notification_logs').insert({
                    student_id: siswa.student_id,
                    notification_type: 'no_journal',
                    status: isSuccess ? 'sent' : 'failed',
                    message,
                    phone_number: phone,
                })

                if (isSuccess) berhasil++
                else gagal++

            } catch (err) {
                console.error('Error untuk siswa', siswa.student_id, ':', err.message)
                gagal++
            }
        }

        console.log(`Selesai: ${berhasil} berhasil, ${gagal} gagal`)

        return new Response(JSON.stringify({ success: true, berhasil, gagal }), {
            status: 200,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })

    } catch (error) {
        console.error('Error:', error.message)
        return new Response(JSON.stringify({ error: error.message }), {
            status: 200,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
    }
})