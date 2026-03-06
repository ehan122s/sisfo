-- Add indexes for foreign keys to improve performance

-- attendance_logs
CREATE INDEX IF NOT EXISTS attendance_logs_placement_id_idx ON public.attendance_logs (placement_id);
CREATE INDEX IF NOT EXISTS attendance_logs_student_id_idx ON public.attendance_logs (student_id);

-- audit_logs
CREATE INDEX IF NOT EXISTS audit_logs_actor_id_idx ON public.audit_logs (actor_id);

-- daily_journals
CREATE INDEX IF NOT EXISTS daily_journals_placement_id_idx ON public.daily_journals (placement_id);
CREATE INDEX IF NOT EXISTS daily_journals_student_id_idx ON public.daily_journals (student_id);

-- placements
CREATE INDEX IF NOT EXISTS placements_company_id_idx ON public.placements (company_id);
CREATE INDEX IF NOT EXISTS placements_student_id_idx ON public.placements (student_id);

-- supervisor_assignments
CREATE INDEX IF NOT EXISTS supervisor_assignments_company_id_idx ON public.supervisor_assignments (company_id);
