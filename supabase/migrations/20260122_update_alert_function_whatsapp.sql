-- Enable pg_net extension to make HTTP requests
CREATE EXTENSION IF NOT EXISTS "pg_net";

CREATE OR REPLACE FUNCTION check_attendance_violations()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    student_record RECORD;
    admin_record RECORD;
    teacher_record RECORD;
    violation_title TEXT;
    violation_message TEXT;
    notif_id UUID;
    student_phone TEXT;
    payload JSONB;
    request_id INTEGER;
BEGIN
    -- 1. Scan for Students with > 3 Absences
    -- (Logic: Count 'Alpha' in attendance_logs for the current month)
    FOR student_record IN
        SELECT
            p.id as student_id,
            p.full_name,
            p.class_name,
            p.phone_number,
            COUNT(al.id) as alpha_count
        FROM profiles p
        JOIN attendance_logs al ON p.id = al.student_id
        WHERE p.role = 'student'
        AND al.status = 'Alpha'
        AND date_trunc('month', al.created_at) = date_trunc('month', CURRENT_DATE)
        GROUP BY p.id, p.full_name, p.class_name, p.phone_number
        HAVING COUNT(al.id) > 3
    LOOP
        -- Check if we already notified for this student today (to avoid spam)
        -- (Simple check: look for notification created today with specific title)
        IF NOT EXISTS (
            SELECT 1 FROM notifications
            WHERE user_id IN (SELECT id FROM profiles WHERE role = 'admin')
            AND title = 'Peringatan: Siswa Bolos > 3 Hari'
            AND message LIKE '%' || student_record.full_name || '%'
            AND created_at::date = CURRENT_DATE
        ) THEN
            violation_title := 'Peringatan: Siswa Bolos > 3 Hari';
            violation_message := 'Siswa ' || student_record.full_name || ' (' || student_record.class_name || ') telah bolos sebanyak ' || student_record.alpha_count || ' hari bulan ini.';

            -- A. Notify All Admins
            FOR admin_record IN SELECT id FROM profiles WHERE role = 'admin'
            LOOP
                INSERT INTO notifications (user_id, title, message, type, is_read)
                VALUES (admin_record.id, violation_title, violation_message, 'alert', false);
            END LOOP;

            -- B. Notify Assigned Teacher (Supervisor)
            -- Find teacher assigned to this student via placement -> company -> supervisor_assignment
            SELECT sa.teacher_id INTO teacher_record
            FROM placements pl
            JOIN supervisor_assignments sa ON pl.company_id = sa.company_id
            WHERE pl.student_id = student_record.student_id
            LIMIT 1;

            IF FOUND THEN
                 INSERT INTO notifications (user_id, title, message, type, is_read)
                 VALUES (teacher_record.teacher_id, violation_title, violation_message, 'alert', false);
            END IF;

            -- C. Send WhatsApp Notification (New Feature)
            IF student_record.phone_number IS NOT NULL AND length(student_record.phone_number) > 5 THEN
                payload := jsonb_build_object(
                    'phoneNumber', student_record.phone_number,
                    'message', violation_title || E'\n' || violation_message
                );

                -- Call Edge Function via pg_net
                -- URL is hardcoded here, but could be fetched from app_config if needed.
                -- We use net.http_post.
                PERFORM net.http_post(
                    url := 'https://gawpkafgndtqmaoamxdk.supabase.co/functions/v1/send-whatsapp',
                    body := payload,
                    headers := '{"Content-Type": "application/json"}'::jsonb
                );
            END IF;

        END IF;
    END LOOP;

    -- 2. Scan for Missing Journals (Today)
    -- (Logic: Check if student has checked in but NOT filled journal by 16:00)
    -- This specific check usually runs at end of day.
    -- For demonstration, we check if check_in exists but journal doesn't.
    
    FOR student_record IN
        SELECT
            p.id as student_id,
            p.full_name,
            p.class_name,
            p.phone_number
        FROM profiles p
        JOIN attendance_logs al ON p.id = al.student_id
        WHERE p.role = 'student'
        AND al.created_at::date = CURRENT_DATE
        AND al.check_in_time IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 FROM daily_journals dj
            WHERE dj.student_id = p.id
            AND dj.created_at::date = CURRENT_DATE
        )
    LOOP
         -- Check if notified today
        IF NOT EXISTS (
            SELECT 1 FROM notifications
            WHERE user_id IN (SELECT id FROM profiles WHERE role = 'admin')
            AND title = 'Peringatan: Jurnal Belum Diisi'
            AND message LIKE '%' || student_record.full_name || '%'
            AND created_at::date = CURRENT_DATE
        ) THEN
            violation_title := 'Peringatan: Jurnal Belum Diisi';
            violation_message := 'Siswa ' || student_record.full_name || ' (' || student_record.class_name || ') hadir tapi belum mengisi jurnal hari ini.';

            -- Notify Admins
            FOR admin_record IN SELECT id FROM profiles WHERE role = 'admin'
            LOOP
                INSERT INTO notifications (user_id, title, message, type, is_read)
                VALUES (admin_record.id, violation_title, violation_message, 'warning', false);
            END LOOP;
            
             -- Notify Teacher
            SELECT sa.teacher_id INTO teacher_record
            FROM placements pl
            JOIN supervisor_assignments sa ON pl.company_id = sa.company_id
            WHERE pl.student_id = student_record.student_id
            LIMIT 1;

            IF FOUND THEN
                 INSERT INTO notifications (user_id, title, message, type, is_read)
                 VALUES (teacher_record.teacher_id, violation_title, violation_message, 'warning', false);
            END IF;
            
             -- Send WhatsApp Notification (Optional for Journal, maybe less critical? But requested.)
            IF student_record.phone_number IS NOT NULL AND length(student_record.phone_number) > 5 THEN
                payload := jsonb_build_object(
                    'phoneNumber', student_record.phone_number,
                    'message', violation_title || E'\n' || violation_message
                );

                PERFORM net.http_post(
                    url := 'https://gawpkafgndtqmaoamxdk.supabase.co/functions/v1/send-whatsapp',
                    body := payload,
                    headers := '{"Content-Type": "application/json"}'::jsonb
                );
            END IF;

        END IF;
    END LOOP;

END;
$$;
