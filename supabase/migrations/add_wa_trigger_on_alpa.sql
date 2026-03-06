-- Trigger: Send WhatsApp notification to parent when student is marked 'Alpa'
-- Uses existing send-whatsapp Edge Function and app_config for WA credentials

CREATE OR REPLACE FUNCTION send_wa_on_alpa()
RETURNS TRIGGER AS $func$
DECLARE
    v_parent_phone TEXT;
    v_student_name TEXT;
    v_class_name TEXT;
    v_wa_url TEXT;
    v_wa_key TEXT;
    v_msg_template TEXT;
    v_final_message TEXT;
BEGIN
    IF NEW.status = 'Alpa' THEN
        -- Get student info
        SELECT p.parent_phone_number, p.full_name, p.class_name
        INTO v_parent_phone, v_student_name, v_class_name
        FROM profiles p WHERE p.id = NEW.student_id;

        -- Get WA config from app_config
        SELECT value INTO v_wa_url FROM app_config WHERE key = 'WA_GATEWAY_URL';
        SELECT value INTO v_wa_key FROM app_config WHERE key = 'WA_API_KEY';

        -- Get absent message template
        SELECT message_template INTO v_msg_template
        FROM message_templates WHERE template_key = 'absent' AND is_active = true LIMIT 1;

        -- Replace template variables
        v_final_message := replace(
            coalesce(v_msg_template, 'Siswa {student_name} ({class_name}) tidak hadir hari ini.'),
            '{student_name}', coalesce(v_student_name, '-')
        );
        v_final_message := replace(v_final_message, '{class_name}', coalesce(v_class_name, '-'));

        -- Only send if parent phone is configured and WA gateway is set up
        IF v_parent_phone IS NOT NULL AND length(v_parent_phone) > 5 AND v_wa_url IS NOT NULL THEN
            -- Send via Edge Function using pg_net
            PERFORM net.http_post(
                url := 'https://gawpkafgndtqmaoamxdk.supabase.co/functions/v1/send-whatsapp',
                body := jsonb_build_object(
                    'phoneNumber', v_parent_phone,
                    'message', v_final_message
                ),
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'x-internal-secret', coalesce(v_wa_key, '')
                )
            );

            -- Log the notification
            INSERT INTO notification_logs (student_id, parent_phone_number, notification_type, message_sent, status, sent_at)
            VALUES (NEW.student_id, v_parent_phone, 'absent', v_final_message, 'sent', NOW())
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    RETURN NEW;
END;
$func$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger first to avoid duplicates
DROP TRIGGER IF EXISTS trigger_wa_on_alpa ON attendance_logs;

-- Create trigger that fires after each attendance_log INSERT
CREATE TRIGGER trigger_wa_on_alpa
    AFTER INSERT ON attendance_logs
    FOR EACH ROW
    EXECUTE FUNCTION send_wa_on_alpa();
