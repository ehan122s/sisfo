-- ============================================================
-- E-PKL Database Setup — Step 5: Views & Indexes
-- ============================================================
-- Run after 04_functions_triggers.sql.
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- VIEW: managed_students_view
-- Used by teachers to see students assigned to their companies.
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW managed_students_view AS
SELECT
  p.id as student_id,
  p.full_name,
  p.nisn,
  p.class_name,
  p.avatar_url,
  c.id as company_id,
  c.name as company_name,
  c.address as company_address,
  sa.teacher_id
FROM profiles p
JOIN placements pl ON p.id = pl.student_id
JOIN companies c ON pl.company_id = c.id
JOIN supervisor_assignments sa ON sa.company_id = c.id
WHERE p.role = 'student';

GRANT SELECT ON managed_students_view TO authenticated;

-- ────────────────────────────────────────────────────────────
-- INDEXES: Foreign key indexes for query performance
-- ────────────────────────────────────────────────────────────

-- attendance_logs
CREATE INDEX IF NOT EXISTS attendance_logs_placement_id_idx ON public.attendance_logs (placement_id);
CREATE INDEX IF NOT EXISTS attendance_logs_student_id_idx ON public.attendance_logs (student_id);
CREATE INDEX IF NOT EXISTS attendance_logs_created_at_idx ON public.attendance_logs (created_at);

-- audit_logs
CREATE INDEX IF NOT EXISTS audit_logs_actor_id_idx ON public.audit_logs (actor_id);
CREATE INDEX IF NOT EXISTS audit_logs_created_at_idx ON public.audit_logs (created_at);

-- daily_journals
CREATE INDEX IF NOT EXISTS daily_journals_placement_id_idx ON public.daily_journals (placement_id);
CREATE INDEX IF NOT EXISTS daily_journals_student_id_idx ON public.daily_journals (student_id);

-- placements
CREATE INDEX IF NOT EXISTS placements_company_id_idx ON public.placements (company_id);
CREATE INDEX IF NOT EXISTS placements_student_id_idx ON public.placements (student_id);

-- supervisor_assignments
CREATE INDEX IF NOT EXISTS supervisor_assignments_company_id_idx ON public.supervisor_assignments (company_id);

-- profiles
CREATE INDEX IF NOT EXISTS profiles_role_idx ON public.profiles (role);
CREATE INDEX IF NOT EXISTS profiles_class_name_idx ON public.profiles (class_name);

-- ────────────────────────────────────────────────────────────
-- REALTIME: Enable for attendance_logs
-- ────────────────────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE attendance_logs;
