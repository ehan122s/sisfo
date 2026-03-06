-- Allow Teachers and Admins to UPDATE daily_journals (e.g. set is_approved)
CREATE POLICY "Teachers and Admins can update journals"
ON public.daily_journals
FOR UPDATE
TO authenticated
USING (
  public.get_my_role() IN ('admin', 'teacher', 'supervisor')
)
WITH CHECK (
  public.get_my_role() IN ('admin', 'teacher', 'supervisor')
);
