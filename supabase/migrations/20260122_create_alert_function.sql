-- Function to check for violations and generate notifications
CREATE OR REPLACE FUNCTION check_attendance_violations()
RETURNS void AS $$
DECLARE
  v_student RECORD;
  v_admin_id uuid;
  v_count int;
BEGIN
    -- Get an Admin ID to assign/notify (optimally all admins, but for now we pick one or just rely on RLS logic if notifications are public to admins)
    -- Wait, notifications table logic is: user_id is the recipient.
    -- We need to insert a notification for EACH admin.
    
    -- 1. Check for STUDENTS with > 3 Absences (Alpha/Tanpa Keterangan)
    -- This is a simplified check: Students who have >= 3 'alpha' records in the last 7 days.
    FOR v_student IN
        SELECT s.id, s.full_name
        FROM profiles s
        JOIN attendance_logs a ON s.id = a.student_id
        WHERE s.role = 'student'
          AND a.status = 'alpha'
          AND a.date >= (CURRENT_DATE - INTERVAL '7 days')
        GROUP BY s.id, s.full_name
        HAVING COUNT(*) >= 3
    LOOP
        -- Check if notification already exists for today to avoid spam
        SELECT COUNT(*) INTO v_count FROM notifications 
        WHERE title = 'Peringatan: Siswa Bolos' 
          AND message LIKE '%' || v_student.full_name || '%'
          AND created_at >= CURRENT_DATE;

        -- Notify all admins
        IF v_count = 0 THEN
            INSERT INTO notifications (user_id, title, message, type, action_link)
            SELECT id, 'Peringatan: Siswa Bolos', 'Siswa ' || v_student.full_name || ' telah bolos lebih dari 3 kali dalam seminggu terakhir.', 'alert', '/students/' || v_student.id || '/attendance'
            FROM profiles
            WHERE role = 'admin';
        END IF;
    END LOOP;

    -- 2. Check for Missing Journal TODAY (if working day)
    -- Only run if today is Monday-Friday
    IF EXTRACT(ISODOW FROM CURRENT_DATE) BETWEEN 1 AND 5 THEN
       -- Find students with placement (active) who haven't submitted journal today
       -- Skipping for now to keep it simple, or implement if requested. 
       -- Let's stick to the user's specific request "Siswa Bolos > 3 hari" first as priority.
       
       -- Actually, user asked for "Jurnal belum diisi" too.
       -- Logic: Active student in placement, no journal entry for today, and it's past 16:00 (for example).
       -- For testing, we won't restrict time, just check if missing.
       
       FOR v_student IN
          SELECT s.id, s.full_name
          FROM profiles s
          JOIN placements p ON s.id = p.student_id AND p.status = 'active'
          WHERE s.role = 'student'
            AND NOT EXISTS (
                SELECT 1 FROM daily_journals j 
                WHERE j.student_id = s.id AND j.date = CURRENT_DATE
            )
       LOOP
            -- Check duplication
            SELECT COUNT(*) INTO v_count FROM notifications 
            WHERE title = 'Jurnal Belum Diisi' 
              AND message LIKE '%' || v_student.full_name || '%' 
              AND created_at >= CURRENT_DATE;

            IF v_count = 0 THEN
                INSERT INTO notifications (user_id, title, message, type, action_link)
                SELECT id, 'Jurnal Belum Diisi', 'Siswa ' || v_student.full_name || ' belum mengisi jurnal hari ini.', 'warning', '/students/' || v_student.id || '/journals'
                FROM profiles
                WHERE role = 'admin';
            END IF;
       END LOOP;
    END IF;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
