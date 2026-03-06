-- Fix Supervisor/Teacher Access to Students

-- 1. Allow Teachers to view their own assignments (Crucial, currently only Admins can view)
-- This is necessary for the next policy to work.
DROP POLICY IF EXISTS "Teachers can view own assignments" ON public.supervisor_assignments;

CREATE POLICY "Teachers can view own assignments"
ON public.supervisor_assignments
FOR SELECT
TO authenticated
USING (
  teacher_id = auth.uid()
);

-- 2. Allow Teachers to view their assigned students (profiles)
-- This links Teachers -> Assignments -> Companies -> Placements -> Students
DROP POLICY IF EXISTS "Teachers can view assigned students" ON public.profiles;

CREATE POLICY "Teachers can view assigned students"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  -- Allow if the profile is a student assigned to a company managed by the teacher
  EXISTS (
    SELECT 1 FROM public.placements pl
    JOIN public.supervisor_assignments sa ON sa.company_id = pl.company_id
    WHERE pl.student_id = profiles.id
    AND sa.teacher_id = auth.uid()
  )
);
