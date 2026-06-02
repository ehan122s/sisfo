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

const SUPERVISOR_MESSAGES: Record<string, (name: string) => string> = {
    absent: (name) => `❌ *PKL Alert*\n\nYth. Bapak/Ibu Pembimbing,\n\nSiswa *${name}* *tidak hadir* hari ini tanpa keterangan.\n\nMohon perhatiannya 🙏`,
    sakit: (name) => `🏥 *PKL Alert*\n\nYth. Bapak/Ibu Pembimbing,\n\nSiswa *${name}* *tidak hadir karena sakit* hari ini.\n\nTerima kasih 🙏`,
    izin: (name) => `📋 *PKL Alert*\n\nYth. Bapak/Ibu Pembimbing,\n\nSiswa *${name}* *tidak hadir karena izin* hari ini.\n\nTerima kasih 🙏`,
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
        const record = body.record
        if (!record) throw new Error('Payload Webhook kosong')

        student_id = record.student_id
        const status_absen = record.status?.toLowerCase()

        if (!student_id) throw new Error('student_id tidak ditemukan')

        if (status_absen === 'hadir') notification_type = 'on_time'
        else if (status_absen === 'terlambat') notification_type = 'late'
        else if (status_absen === 'alpa' || status_absen === 'mangkir') notification_type = 'absent'
        else if (status_absen === 'sakit') notification_type = 'sakit'
        else if (status_absen === 'izin') notification_type = 'izin'
        else notification_type = 'absent'

        const { data: configData } = await supabase
            .from('app_config')
            .select('key, value')
            .in('key', ['WA_GATEWAY_URL', 'WA_API_KEY'])

        const gatewayUrl = configData?.find(c => c.key === 'WA_GATEWAY_URL')?.value ?? 'https://api.fonnte.com/send'
        const apiKey = configData?.find(c => c.key === 'WA_API_KEY')?.value

        if (!apiKey) throw new Error('API Key belum diisi di app_config')

        const { data: student } = await supabase
            .from('profiles')
            .select('full_name, parent_phone_number')
            .eq('id', student_id)
            .single()

        if (!student?.parent_phone_number) throw new Error('Nomor HP orang tua tidak tersedia')

        message = NOTIFICATION_MESSAGES[notification_type]?.(student.full_name)
            ?? `Notifikasi PKL untuk ${student.full_name}`

        phone = student.parent_phone_number.replace(/\D/g, '')
        if (phone.startsWith('0')) phone = '62' + phone.slice(1)
        else if (phone.startsWith('8')) phone = '62' + phone
        else if (!phone.startsWith('62')) phone = '62' + phone

        const fonnteResponse = await fetch(gatewayUrl, {
            method: 'POST',
            headers: {
                'Authorization': apiKey,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ target: phone, message: message }),
        })

        const fonnteResult = await fonnteResponse.json()
        isSuccess = fonnteResult.status === true || fonnteResult.status === 'true' || fonnteResult.process === true

        if (['absent', 'sakit', 'izin'].includes(notification_type)) {
            try {
                const { data: placement } = await supabase
                    .from('placements')
                    .select('company_id')
                    .eq('student_id', student_id)
                    .single()

                if (placement?.company_id) {
                    const { data: supervisors } = await supabase
                        .from('supervisor_assignments')
                        .select('teacher_id')
                        .eq('company_id', placement.company_id)

                    if (supervisors && supervisors.length > 0) {
                        for (const supervisor of supervisors) {
                            const { data: teacher } = await supabase
                                .from('profiles')
                                .select('full_name, phone_number')
                                .eq('id', supervisor.teacher_id)
                                .single()

                            if (!teacher?.phone_number) continue

                            const supervisorMessage = SUPERVISOR_MESSAGES[notification_type]?.(student.full_name)
                                ?? `Siswa ${student.full_name} tidak hadir hari ini`

                            let teacherPhone = teacher.phone_number.replace(/\D/g, '')
                            if (teacherPhone.startsWith('0')) teacherPhone = '62' + teacherPhone.slice(1)
                            else if (teacherPhone.startsWith('8')) teacherPhone = '62' + teacherPhone
                            else if (!teacherPhone.startsWith('62')) teacherPhone = '62' + teacherPhone

                            await fetch(gatewayUrl, {
                                method: 'POST',
                                headers: {
                                    'Authorization': apiKey,
                                    'Content-Type': 'application/json',
                                },
                                body: JSON.stringify({ target: teacherPhone, message: supervisorMessage }),
                            })
                        }
                    }
                }
            } catch (supervisorErr) {
                console.error('supervisor error:', supervisorErr.message)
            }
        }

    } catch (error) {
        console.error('error:', error.message)
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
            if (insertError) console.error('insert error:', JSON.stringify(insertError))
        }
    } catch (insertErr) {
        console.error('insert exception:', insertErr.message)
    }

    return new Response(JSON.stringify({ success: isSuccess }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
})