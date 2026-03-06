-- ============================================================
-- E-PKL Database Setup — Step 4: Functions & Triggers
-- ============================================================
-- All PostgreSQL functions, RPC endpoints, and triggers.
-- Run after 03_rls_policies.sql.
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. handle_new_user() — Trigger on auth.users INSERT
--    Creates a profile automatically when a user signs up.
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data ->> 'full_name',
    NEW.raw_user_meta_data ->> 'avatar_url'
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ────────────────────────────────────────────────────────────
-- 2. notify_admins_of_new_student() — Trigger on profiles INSERT
--    Sends a notification to all admins when a student registers.
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION notify_admins_of_new_student()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role = 'student' THEN
    INSERT INTO notifications (user_id, title, message, type, action_link)
    SELECT id,
           'Siswa Baru Terdaftar',
           'Siswa baru ' || COALESCE(NEW.full_name, 'Siswa') || ' menunggu persetujuan.',
           'info',
           '/students'
    FROM profiles
    WHERE role = 'admin';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_new_student_registered ON profiles;
CREATE TRIGGER on_new_student_registered
  AFTER INSERT ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION notify_admins_of_new_student();

-- ────────────────────────────────────────────────────────────
-- 3. create_teacher_user(email, password, full_name) — RPC
--    Admin-only function to create teacher/supervisor accounts.
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION create_teacher_user(
  email text,
  password text,
  full_name text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  new_id uuid;
  encrypted_pw text;
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access Denied: Only admins can create accounts.';
  END IF;

  -- Check if email exists
  IF EXISTS (SELECT 1 FROM auth.users WHERE auth.users.email = create_teacher_user.email) THEN
    RAISE EXCEPTION 'Email already registered.';
  END IF;

  -- Hash password
  encrypted_pw := crypt(password, gen_salt('bf'));

  -- Insert into auth.users
  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, recovery_sent_at, last_sign_in_at,
    raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at,
    confirmation_token, email_change, email_change_token_new, recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated', 'authenticated',
    email, encrypted_pw,
    now(), null, null,
    '{"provider": "email", "providers": ["email"]}',
    jsonb_build_object('full_name', full_name),
    now(), now(),
    '', '', '', ''
  )
  RETURNING id INTO new_id;

  -- Update profile role to teacher
  UPDATE profiles
  SET role = 'teacher', nisn = NULL
  WHERE id = new_id;

  RETURN new_id;
END;
$$;

-- ────────────────────────────────────────────────────────────
-- 4. check_attendance_violations() — RPC
--    Checks for students with > 3 absences and missing journals.
--    Notifies admins + assigned teachers + sends WhatsApp.
-- ────────────────────────────────────────────────────────────
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
    payload JSONB;
BEGIN
    -- 1. Students with > 3 Absences this month
    FOR student_record IN
        SELECT
            p.id as student_id, p.full_name, p.class_name, p.phone_number,
            COUNT(al.id) as alpha_count
        FROM profiles p
        JOIN attendance_logs al ON p.id = al.student_id
        WHERE p.role = 'student'
        AND al.status = 'Alpha'
        AND date_trunc('month', al.created_at) = date_trunc('month', CURRENT_DATE)
        GROUP BY p.id, p.full_name, p.class_name, p.phone_number
        HAVING COUNT(al.id) > 3
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM notifications
            WHERE title = 'Peringatan: Siswa Bolos > 3 Hari'
            AND message LIKE '%' || student_record.full_name || '%'
            AND created_at::date = CURRENT_DATE
        ) THEN
            violation_title := 'Peringatan: Siswa Bolos > 3 Hari';
            violation_message := 'Siswa ' || student_record.full_name || ' (' || student_record.class_name || ') telah bolos sebanyak ' || student_record.alpha_count || ' hari bulan ini.';

            -- Notify all admins
            FOR admin_record IN SELECT id FROM profiles WHERE role = 'admin'
            LOOP
                INSERT INTO notifications (user_id, title, message, type, is_read)
                VALUES (admin_record.id, violation_title, violation_message, 'alert', false);
            END LOOP;

            -- Notify assigned teacher
            SELECT sa.teacher_id INTO teacher_record
            FROM placements pl
            JOIN supervisor_assignments sa ON pl.company_id = sa.company_id
            WHERE pl.student_id = student_record.student_id
            LIMIT 1;

            IF FOUND THEN
                INSERT INTO notifications (user_id, title, message, type, is_read)
                VALUES (teacher_record.teacher_id, violation_title, violation_message, 'alert', false);
            END IF;

            -- Send WhatsApp via Edge Function (requires pg_net)
            IF student_record.phone_number IS NOT NULL AND length(student_record.phone_number) > 5 THEN
                payload := jsonb_build_object(
                    'phoneNumber', student_record.phone_number,
                    'message', violation_title || E'\n' || violation_message
                );
                -- NOTE: Update URL below to match your Supabase project URL
                PERFORM net.http_post(
                    url := 'https://<YOUR_PROJECT_ID>.supabase.co/functions/v1/send-whatsapp',
                    body := payload,
                    headers := '{"Content-Type": "application/json"}'::jsonb
                );
            END IF;
        END IF;
    END LOOP;

    -- 2. Missing Journal today
    FOR student_record IN
        SELECT p.id as student_id, p.full_name, p.class_name, p.phone_number
        FROM profiles p
        JOIN attendance_logs al ON p.id = al.student_id
        WHERE p.role = 'student'
        AND al.created_at::date = CURRENT_DATE
        AND al.check_in_time IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 FROM daily_journals dj
            WHERE dj.student_id = p.id AND dj.created_at::date = CURRENT_DATE
        )
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM notifications
            WHERE title = 'Peringatan: Jurnal Belum Diisi'
            AND message LIKE '%' || student_record.full_name || '%'
            AND created_at::date = CURRENT_DATE
        ) THEN
            violation_title := 'Peringatan: Jurnal Belum Diisi';
            violation_message := 'Siswa ' || student_record.full_name || ' (' || student_record.class_name || ') hadir tapi belum mengisi jurnal hari ini.';

            FOR admin_record IN SELECT id FROM profiles WHERE role = 'admin'
            LOOP
                INSERT INTO notifications (user_id, title, message, type, is_read)
                VALUES (admin_record.id, violation_title, violation_message, 'warning', false);
            END LOOP;

            SELECT sa.teacher_id INTO teacher_record
            FROM placements pl
            JOIN supervisor_assignments sa ON pl.company_id = sa.company_id
            WHERE pl.student_id = student_record.student_id
            LIMIT 1;

            IF FOUND THEN
                INSERT INTO notifications (user_id, title, message, type, is_read)
                VALUES (teacher_record.teacher_id, violation_title, violation_message, 'warning', false);
            END IF;

            IF student_record.phone_number IS NOT NULL AND length(student_record.phone_number) > 5 THEN
                payload := jsonb_build_object(
                    'phoneNumber', student_record.phone_number,
                    'message', violation_title || E'\n' || violation_message
                );
                PERFORM net.http_post(
                    url := 'https://<YOUR_PROJECT_ID>.supabase.co/functions/v1/send-whatsapp',
                    body := payload,
                    headers := '{"Content-Type": "application/json"}'::jsonb
                );
            END IF;
        END IF;
    END LOOP;
END;
$$;

-- ────────────────────────────────────────────────────────────
-- 5. count_attendance_by_grade(start_time, end_time, grade_filter) — RPC
--    Dashboard: Returns attendance counts by status for a date range.
--    grade_filter = 'X-XI' excludes class XII.
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION count_attendance_by_grade(
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  grade_filter TEXT DEFAULT 'X-XI'
)
RETURNS TABLE(status TEXT, count BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT al.status, COUNT(*)::BIGINT
  FROM attendance_logs al
  JOIN profiles p ON al.student_id = p.id
  WHERE al.created_at >= start_time
    AND al.created_at <= end_time
    AND p.role = 'student'
    AND (
      grade_filter IS NULL
      OR grade_filter = ''
      OR (grade_filter = 'X-XI' AND p.class_name NOT LIKE 'XII%')
    )
  GROUP BY al.status;
END;
$$;

-- ────────────────────────────────────────────────────────────
-- 6. get_attendance_trend_by_grade(start_time, end_time, grade_filter) — RPC
--    Dashboard: Returns daily attendance trend grouped by date & status.
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_attendance_trend_by_grade(
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  grade_filter TEXT DEFAULT 'X-XI'
)
RETURNS TABLE(log_date TEXT, status TEXT, count BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    TO_CHAR(al.created_at AT TIME ZONE 'Asia/Jakarta', 'YYYY-MM-DD') as log_date,
    al.status,
    COUNT(*)::BIGINT
  FROM attendance_logs al
  JOIN profiles p ON al.student_id = p.id
  WHERE al.created_at >= start_time
    AND al.created_at <= end_time
    AND p.role = 'student'
    AND (
      grade_filter IS NULL
      OR grade_filter = ''
      OR (grade_filter = 'X-XI' AND p.class_name NOT LIKE 'XII%')
    )
  GROUP BY log_date, al.status
  ORDER BY log_date;
END;
$$;

-- ────────────────────────────────────────────────────────────
-- 7. get_class_attendance_summary(target_date) — RPC
--    Dashboard: Returns attendance breakdown per class for a date.
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_class_attendance_summary(
  target_date TEXT
)
RETURNS TABLE(
  class_name TEXT,
  hadir BIGINT,
  terlambat BIGINT,
  sakit BIGINT,
  izin BIGINT,
  alpa BIGINT,
  total BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  start_ts TIMESTAMPTZ;
  end_ts TIMESTAMPTZ;
BEGIN
  start_ts := (target_date || 'T00:00:00')::TIMESTAMPTZ;
  end_ts := (target_date || 'T23:59:59.999')::TIMESTAMPTZ;

  RETURN QUERY
  SELECT
    p.class_name,
    COUNT(*) FILTER (WHERE al.status = 'Hadir')::BIGINT as hadir,
    COUNT(*) FILTER (WHERE al.status = 'Terlambat')::BIGINT as terlambat,
    COUNT(*) FILTER (WHERE al.status = 'Sakit')::BIGINT as sakit,
    COUNT(*) FILTER (WHERE al.status = 'Izin')::BIGINT as izin,
    COUNT(*) FILTER (WHERE al.status = 'Alpa')::BIGINT as alpa,
    COUNT(*)::BIGINT as total
  FROM attendance_logs al
  JOIN profiles p ON al.student_id = p.id
  WHERE al.created_at >= start_ts
    AND al.created_at <= end_ts
    AND p.role = 'student'
  GROUP BY p.class_name
  ORDER BY p.class_name;
END;
$$;

-- ────────────────────────────────────────────────────────────
-- 8. get_students_by_attendance_status(...) — RPC
--    Attendance page: Returns students with their attendance
--    status for a given date, with pagination.
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_students_by_attendance_status(
  target_date TEXT,
  status_filter TEXT DEFAULT NULL,
  class_filter TEXT DEFAULT NULL,
  search_term TEXT DEFAULT NULL,
  page_offset INT DEFAULT 0,
  page_limit INT DEFAULT 50
)
RETURNS TABLE(
  id UUID,
  full_name TEXT,
  class_name TEXT,
  avatar_url TEXT,
  company_name TEXT,
  attendance_status TEXT,
  check_in_time TIMESTAMPTZ,
  check_out_time TIMESTAMPTZ,
  total_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  start_ts TIMESTAMPTZ;
  end_ts TIMESTAMPTZ;
BEGIN
  start_ts := (target_date || 'T00:00:00')::TIMESTAMPTZ;
  end_ts := (target_date || 'T23:59:59.999')::TIMESTAMPTZ;

  RETURN QUERY
  SELECT
    p.id,
    p.full_name,
    p.class_name,
    p.avatar_url,
    c.name as company_name,
    al.status as attendance_status,
    al.check_in_time,
    al.check_out_time,
    COUNT(*) OVER()::BIGINT as total_count
  FROM profiles p
  LEFT JOIN placements pl ON p.id = pl.student_id AND pl.status = 'active'
  LEFT JOIN companies c ON pl.company_id = c.id
  LEFT JOIN attendance_logs al ON al.student_id = p.id
    AND al.created_at >= start_ts
    AND al.created_at <= end_ts
  WHERE p.role = 'student'
    AND p.status = 'active'
    AND (status_filter IS NULL OR al.status = status_filter)
    AND (class_filter IS NULL OR p.class_name = class_filter)
    AND (search_term IS NULL OR p.full_name ILIKE '%' || search_term || '%')
  ORDER BY p.class_name, p.full_name
  LIMIT page_limit
  OFFSET page_offset;
END;
$$;

-- ────────────────────────────────────────────────────────────
-- 9. get_distinct_classes() — RPC
--    Returns list of unique class names from profiles table.
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_distinct_classes()
RETURNS TABLE(class_name TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT p.class_name
  FROM profiles p
  WHERE p.role = 'student'
    AND p.class_name IS NOT NULL
    AND p.class_name != ''
  ORDER BY p.class_name;
END;
$$;
