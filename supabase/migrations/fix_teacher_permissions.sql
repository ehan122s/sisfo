-- 1. Policies for Daily Journals (SELECT)
DROP POLICY IF EXISTS "Teachers and Admins can view all journals" ON public.daily_journals;

CREATE POLICY "Teachers and Admins can view all journals"
ON public.daily_journals
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('admin', 'teacher', 'supervisor')
  )
);

-- 2. Policies for Attendance Logs (SELECT) - Re-apply to ensure it exists
DROP POLICY IF EXISTS "Admins and Teachers can view all attendance" ON public.attendance_logs;

CREATE POLICY "Admins and Teachers can view all attendance"
ON public.attendance_logs
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('admin', 'teacher', 'supervisor')
  )
);

-- 3. Grant Permissions just in case (though RLS handles row access, GRANT is needed for table access)
GRANT SELECT ON public.daily_journals TO authenticated;
GRANT SELECT ON public.attendance_logs TO authenticated;
