-- Allow Admins and Teachers to view all attendance logs
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
