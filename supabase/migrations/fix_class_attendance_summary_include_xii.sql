-- Fix: get_class_attendance_summary — include ALL classes (X, XI, XII)
-- Uses LEFT JOIN so classes without attendance records still appear (as alpa).
-- Only TEXT overload kept (DATE overload dropped to avoid PostgREST PGRST203).

DROP FUNCTION IF EXISTS get_class_attendance_summary(date);

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
BEGIN
  RETURN QUERY
  WITH class_students AS (
    SELECT
      p.id as student_id,
      p.class_name
    FROM profiles p
    WHERE p.role = 'student'
      AND p.status = 'active'
  ),
  day_attendance AS (
    SELECT
      al.student_id,
      al.status
    FROM attendance_logs al
    WHERE al.created_at >= (target_date || 'T00:00:00')::TIMESTAMPTZ
      AND al.created_at <= (target_date || 'T23:59:59.999')::TIMESTAMPTZ
  )
  SELECT
    cs.class_name::TEXT,
    COUNT(CASE WHEN da.status = 'Hadir' THEN 1 END)::BIGINT as hadir,
    COUNT(CASE WHEN da.status = 'Terlambat' THEN 1 END)::BIGINT as terlambat,
    COUNT(CASE WHEN da.status = 'Sakit' THEN 1 END)::BIGINT as sakit,
    COUNT(CASE WHEN da.status = 'Izin' THEN 1 END)::BIGINT as izin,
    COUNT(CASE WHEN da.status = 'Alpa' OR da.status IS NULL THEN 1 END)::BIGINT as alpa,
    COUNT(*)::BIGINT as total
  FROM class_students cs
  LEFT JOIN day_attendance da ON da.student_id = cs.student_id
  GROUP BY cs.class_name
  ORDER BY cs.class_name;
END;
$$;
