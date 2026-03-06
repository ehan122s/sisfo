-- Create View for Managed Students (Fixed: removed missing email column)
CREATE OR REPLACE VIEW managed_students_view AS
SELECT 
  p.id as student_id,
  p.full_name,
  p.nisn,
  p.class_name,
  p.avatar_url,
  -- p.email, -- Column removed as it doesn't exist yet
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
