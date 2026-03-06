-- Seeding script for Multi-DUDI Scenario (Using Existing Data)
-- 1. Teacher: Aryadi (Existing)
-- 2. Companies: PT Inti (ID 10), PT Layung (ID 9)
-- 3. Assignments: Aryadi -> PT Inti (Should exist already), Aryadi -> PT Layung (New)
-- 4. Students cleanup:
--    - Suhendar (03f...) -> Only in PT Inti (10). Remove from 9.
--    - Suhendar Aryadi (60f...) -> Only in PT Layung (9).

DO $$
DECLARE
  v_teacher_id UUID;
BEGIN
  -- 1. Find Teacher (Aryadi)
  SELECT id INTO v_teacher_id FROM profiles WHERE full_name ILIKE '%aryadi%' AND role = 'teacher' LIMIT 1;
  
  IF v_teacher_id IS NULL THEN
     v_teacher_id := '49778431-1c8a-4383-9973-b2bc7c8c44c8';
  END IF;

  RAISE NOTICE 'Using Teacher ID: %', v_teacher_id;

  -- 2. Assign Teacher to PT Inti (10)
  INSERT INTO supervisor_assignments (teacher_id, company_id)
  VALUES (v_teacher_id, 10)
  ON CONFLICT (teacher_id, company_id) DO NOTHING;

  -- 3. Assign Teacher to PT Layung (9)
  INSERT INTO supervisor_assignments (teacher_id, company_id)
  VALUES (v_teacher_id, 9)
  ON CONFLICT (teacher_id, company_id) DO NOTHING;

  -- 4. Clean up Suhendar (03f...) - Remove from 9, Keep in 10
  DELETE FROM placements 
  WHERE student_id = '03f20c75-e003-493f-9a80-a47d7a9bdd8e' 
  AND company_id = 9;

  -- 5. Ensure Suhendar Aryadi (60f...) is in 9
  PERFORM 1 FROM placements WHERE student_id = '60fc28fb-5be8-493d-ba1b-993ff55bc1e0' AND company_id = 9;
  IF NOT FOUND THEN
      INSERT INTO placements (student_id, company_id)
      VALUES ('60fc28fb-5be8-493d-ba1b-993ff55bc1e0', 9);
  END IF;

  RAISE NOTICE 'Multi-DUDI Setup Complete!';
END $$;
