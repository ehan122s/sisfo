-- Fix RLS Recursion by using get_my_role() function

-- 1. Update Supervisor Assignments Policy
DROP POLICY IF EXISTS "Admins can manage supervisor assignments" ON public.supervisor_assignments;

CREATE POLICY "Admins can manage supervisor assignments"
ON public.supervisor_assignments
FOR ALL
TO authenticated
USING (
  public.get_my_role() = 'admin'
)
WITH CHECK (
  public.get_my_role() = 'admin'
);

-- 2. Update Attendance Logs Policy (Safety optimization)
DROP POLICY IF EXISTS "Admins and Teachers can view all attendance" ON public.attendance_logs;

CREATE POLICY "Admins and Teachers can view all attendance"
ON public.attendance_logs
FOR SELECT
TO authenticated
USING (
  public.get_my_role() IN ('admin', 'teacher', 'supervisor')
);
