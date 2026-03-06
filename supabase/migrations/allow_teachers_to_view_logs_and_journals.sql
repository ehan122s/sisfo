-- Fix Supervisor/Teacher Access to Attendance and Journals

-- 1. ATTENDANCE LOGS
-- Allow Teachers to view attendance of students assigned to their companies
DROP POLICY IF EXISTS "Admins and Teachers can view all attendance" ON public.attendance_logs;
DROP POLICY IF EXISTS "Teachers can view assigned students attendance" ON public.attendance_logs;

CREATE POLICY "Teachers can view assigned students attendance"
ON public.attendance_logs
FOR SELECT
TO authenticated
USING (
  -- Admin can view all (keep this check simple or use get_my_role if preferred, but explicit is reliable)
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
  OR
  -- Teachers can view if the log belongs to a student they supervise
  EXISTS (
    SELECT 1 FROM public.placements pl
    JOIN public.supervisor_assignments sa ON sa.company_id = pl.company_id
    WHERE pl.id = attendance_logs.placement_id -- Best to link via placement_id if populated
    AND sa.teacher_id = auth.uid()
  )
  OR
  -- Fallback: Link via student_id if placement_id is null (older data?)
  EXISTS (
    SELECT 1 FROM public.placements pl
    JOIN public.supervisor_assignments sa ON sa.company_id = pl.company_id
    WHERE pl.student_id = attendance_logs.student_id
    AND sa.teacher_id = auth.uid()
  )
);

-- 2. DAILY JOURNALS
-- Allow Teachers to view journals of students assigned to their companies
DROP POLICY IF EXISTS "Teachers and Admins can view all journals" ON public.daily_journals;
DROP POLICY IF EXISTS "Teachers can view assigned students journals" ON public.daily_journals;

CREATE POLICY "Teachers can view assigned students journals"
ON public.daily_journals
FOR SELECT
TO authenticated
USING (
  -- Admin check
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
  OR
  -- Teacher check linked to assignment
  EXISTS (
    SELECT 1 FROM public.placements pl
    JOIN public.supervisor_assignments sa ON sa.company_id = pl.company_id
    WHERE pl.id = daily_journals.placement_id
    AND sa.teacher_id = auth.uid()
  )
  OR
  -- Fallback via student_id
  EXISTS (
    SELECT 1 FROM public.placements pl
    JOIN public.supervisor_assignments sa ON sa.company_id = pl.company_id
    WHERE pl.student_id = daily_journals.student_id
    AND sa.teacher_id = auth.uid()
  )
);
