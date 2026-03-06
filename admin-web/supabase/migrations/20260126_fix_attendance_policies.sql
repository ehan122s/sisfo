-- Enable RLS (already enabled, but good practice to ensure)
ALTER TABLE attendance_logs ENABLE ROW LEVEL SECURITY;

-- Policy for Admins to have full access (SELECT, INSERT, UPDATE, DELETE)
CREATE POLICY "Admins can manage all attendance logs"
ON attendance_logs
FOR ALL
USING (
  (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin' OR
  (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
);

-- Optional: Allow teachers to manage attendance?
-- For now, let's fix the reported error which is likely an Admin user.
-- If needed, we can add a more complex policy for Teachers later.
