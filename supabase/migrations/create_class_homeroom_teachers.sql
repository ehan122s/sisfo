-- Migration: create_class_homeroom_teachers
-- Tabel untuk menyimpan assignment wali kelas per kelas/rombel

CREATE TABLE IF NOT EXISTS class_homeroom_teachers (
  id BIGSERIAL PRIMARY KEY,
  class_name TEXT NOT NULL UNIQUE,
  teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_class_homeroom_teachers_teacher_id
  ON class_homeroom_teachers(teacher_id);

-- RLS
ALTER TABLE class_homeroom_teachers ENABLE ROW LEVEL SECURITY;

-- Semua authenticated user bisa baca
CREATE POLICY "Public read homeroom teachers"
  ON class_homeroom_teachers FOR SELECT
  USING (true);

-- Admin & teacher bisa manage
CREATE POLICY "Admins can manage homeroom teachers"
  ON class_homeroom_teachers FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
        AND role IN ('admin', 'teacher')
    )
  );
