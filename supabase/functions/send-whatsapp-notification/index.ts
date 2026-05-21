import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const NOTIFICATION_MESSAGES: Record<string, (name: string) => string> = {
    on_time: (name) => `✅ *PKL Update*\n\nYth. Orang Tua/Wali ${name},\n\nPutra/Putri Anda telah *hadir tepat waktu* hari ini.\n\nTerima kasih 🙏`,
    late: (name) => `⚠️ *PKL Update*\n\nYth. Orang Tua/Wali ${name},\n\nPutra/Putri Anda *terlambat hadir* hari ini.\n\nMohon perhatiannya 🙏`,
    absent: (name) => `❌ *PKL Update*\n\nYth. Orang Tua/Wali ${name},\n\nPutra/Putri Anda *tidak hadir* hari ini tanpa keterangan.\n\nMohon segera menghubungi pihak sekolah 🙏`,
    no_journal: (name) => `📝 *PKL Update*\n\nYth. Orang Tua/Wali ${name},\n\nPutra/Putri Anda *belum mengisi jurnal PKL* hari ini.\n\nMohon ingatkan untuk segera mengisi 🙏`,
    sakit: (name) => `🏥 *PKL Update*\n\nYth. Orang Tua/Wali ${name},\n\nPutra/Putri Anda *tidak hadir karena sakit* hari ini.\n\nSemoga lekas sembuh 🙏`,
    izin: (name) => `📋 *PKL Update*\n\nYth. Orang Tua/Wali ${name},\n\nPutra/Putri Anda *tidak hadir karena izin* hari ini.\n\nTerima kasih 🙏`,
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    const supabase = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    let student_id = ''
    let notification_type = 'absent'
    let message = ''
    let phone = ''
    let isSuccess = false

    try {
        const body = await req.json()
        console.log('Payload diterima:', JSON.stringify(body))

        const record = body.record
        if (!record) throw new Error('Payload Webhook kosong')

        student_id = record.student_id
        const status_absen = record.status?.toLowerCase()

        console.log('student_id:', student_id)
        console.log('status_absen:', status_absen)

        if (!student_id) throw new Error('student_id tidak ditemukan')

        if (status_absen === 'hadir') notification_type = 'on_time'
        else if (status_absen === 'terlambat') notification_type = 'late'
        else if (status_absen === 'alpa' || status_absen === 'mangkir') notification_type = 'absent'
        else if (status_absen === 'sakit') notification_type = 'sakit'
        else if (status_absen === 'izin') notification_type = 'izin'
        else notification_type = 'absent'

        const { data: configData, error: configError } = await supabase
            .from('app_config')
            .select('key, value')
            .in('key', ['WA_GATEWAY_URL', 'WA_API_KEY'])

        console.log('Config:', JSON.stringify(configData), 'Error:', configError)

        const gatewayUrl = configData?.find(c => c.key === 'WA_GATEWAY_URL')?.value ?? 'https://api.fonnte.com/send'
        const apiKey = configData?.find(c => c.key === 'WA_API_KEY')?.value

        if (!apiKey) throw new Error('API Key belum diisi di app_config')

        const { data: student, error: studentError } = await supabase
            .from('profiles')
            .select('full_name, parent_phone_number')
            .eq('id', student_id)
            .single()

        console.log('Student:', JSON.stringify(student), 'Error:', studentError)

        if (!student?.parent_phone_number) throw new Error('Nomor HP orang tua tidak tersedia')

        message = NOTIFICATION_MESSAGES[notification_type]?.(student.full_name)
            ?? `Notifikasi PKL untuk ${student.full_name}`

        phone = student.parent_phone_number.replace(/\D/g, '')
        if (phone.startsWith('0')) phone = '62' + phone.slice(1)
        else if (phone.startsWith('8')) phone = '62' + phone
        else if (!phone.startsWith('62')) phone = '62' + phone

        console.log('Kirim WA ke:', phone)

        const fonnteResponse = await fetch(gatewayUrl, {
            method: 'POST',
            headers: {
                'Authorization': apiKey,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ target: phone, message: message }),
        })

        const fonnteResult = await fonnteResponse.json()
        console.log('Fonnte result:', JSON.stringify(fonnteResult))

        isSuccess = fonnteResult.status === true || fonnteResult.status === 'true' || fonnteResult.process === true

    } catch (error) {
        console.error('Error sebelum insert:', error.message)
        isSuccess = false
    }

    try {
        if (student_id) {
            const { error: insertError } = await supabase.from('notification_logs').insert({
                student_id,
                notification_type,
                status: isSuccess ? 'sent' : 'failed',
                message,
                phone_number: phone || null,
            })
            if (insertError) {
                console.error('Gagal insert notification_logs:', JSON.stringify(insertError))
            } else {
                console.log('Berhasil insert notification_logs')
            }
        }
    } catch (insertErr) {
        console.error('Exception saat insert:', insertErr.message)
    }

    return new Response(JSON.stringify({ success: isSuccess }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
})