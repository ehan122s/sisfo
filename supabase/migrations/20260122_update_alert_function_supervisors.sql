-- Function to check for violations and generate notifications
CREATE OR REPLACE FUNCTION check_attendance_violations()
RETURNS void AS $$
DECLARE
  v_student RECORD;
  v_count int;
  v_teacher_id uuid;
BEGIN
    -- 1. Check for STUDENTS with > 3 Absences
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
        -- Check if Admin notification exists
        SELECT COUNT(*) INTO v_count FROM notifications 
        WHERE title = 'Peringatan: Siswa Bolos' 
          AND message LIKE '%' || v_student.full_name || '%'
          AND user_id IN (SELECT id FROM profiles WHERE role = 'admin')
          AND created_at >= CURRENT_DATE;

        -- Notify Admins
        IF v_count = 0 THEN
            INSERT INTO notifications (user_id, title, message, type, action_link)
            SELECT id, 'Peringatan: Siswa Bolos', 'Siswa ' || v_student.full_name || ' telah bolos lebih dari 3 kali dalam seminggu terakhir.', 'alert', '/students/' || v_student.id || '/attendance'
            FROM profiles
            WHERE role = 'admin';
        END IF;

        -- Notify Supervisor (Teacher)
        -- Find teacher assigned to this student's company via placement
        SELECT t.id INTO v_teacher_id
        FROM placements p
        JOIN supervisor_assignments sa ON p.company_id = sa.company_id
        JOIN profiles t ON sa.teacher_id = t.id
        WHERE p.student_id = v_student.id AND p.status = 'active'
        LIMIT 1;

        IF v_teacher_id IS NOT NULL THEN
            -- Check duplication for teacher
            SELECT COUNT(*) INTO v_count FROM notifications 
            WHERE title = 'Peringatan: Siswa Bolos' 
              AND message LIKE '%' || v_student.full_name || '%' 
              AND user_id = v_teacher_id
              AND created_at >= CURRENT_DATE;

            IF v_count = 0 THEN
                INSERT INTO notifications (user_id, title, message, type, action_link)
                VALUES (v_teacher_id, 'Peringatan: Siswa Bolos', 'Siswa bimbingan Anda, ' || v_student.full_name || ', telah bolos lebih dari 3 kali.', 'alert', '/my-students/' || v_student.id);
            END IF;
        END IF;

    END LOOP;

    -- 2. Check for Missing Journal TODAY (Mon-Fri)
    IF EXTRACT(ISODOW FROM CURRENT_DATE) BETWEEN 1 AND 5 THEN
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
            -- Notify Admins
            SELECT COUNT(*) INTO v_count FROM notifications 
            WHERE title = 'Jurnal Belum Diisi' 
              AND message LIKE '%' || v_student.full_name || '%' 
              AND user_id IN (SELECT id FROM profiles WHERE role = 'admin')
              AND created_at >= CURRENT_DATE;

            IF v_count = 0 THEN
                INSERT INTO notifications (user_id, title, message, type, action_link)
                SELECT id, 'Jurnal Belum Diisi', 'Siswa ' || v_student.full_name || ' belum mengisi jurnal hari ini.', 'warning', '/students/' || v_student.id || '/journals'
                FROM profiles
                WHERE role = 'admin';
            END IF;

            -- Notify Supervisor (Teacher)
            SELECT t.id INTO v_teacher_id
            FROM placements p
            JOIN supervisor_assignments sa ON p.company_id = sa.company_id
            JOIN profiles t ON sa.teacher_id = t.id
            WHERE p.student_id = v_student.id AND p.status = 'active'
            LIMIT 1;

            IF v_teacher_id IS NOT NULL THEN
                SELECT COUNT(*) INTO v_count FROM notifications 
                WHERE title = 'Jurnal Belum Diisi' 
                  AND message LIKE '%' || v_student.full_name || '%' 
                  AND user_id = v_teacher_id
                  AND created_at >= CURRENT_DATE;

                IF v_count = 0 THEN
                    INSERT INTO notifications (user_id, title, message, type, action_link)
                    VALUES (v_teacher_id, 'Jurnal Belum Diisi', 'Siswa bimbingan Anda, ' || v_student.full_name || ', belum mengisi jurnal hari ini.', 'warning', '/my-students/' || v_student.id);
                END IF;
            END IF;
       END LOOP;
    END IF;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
