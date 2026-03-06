-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  type text CHECK (type IN ('alert', 'info', 'success', 'warning')) DEFAULT 'info',
  is_read boolean DEFAULT false,
  action_link text,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Policy: Users can see their own notifications
CREATE POLICY "Users can view their own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can update (mark as read) their own notifications
CREATE POLICY "Users can update their own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- Function to notify admins when a new student registers
CREATE OR REPLACE FUNCTION notify_admins_of_new_student()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if the new profile is a student and status is pending (optional, based on flow)
  IF NEW.role = 'student' THEN
    INSERT INTO notifications (user_id, title, message, type, action_link)
    SELECT id, 'Siswa Baru Terdaftar', 'Siswa baru ' || COALESCE(NEW.full_name, 'Siswa') || ' menunggu persetujuan.', 'info', '/students'
    FROM profiles
    WHERE role = 'admin';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new student
DROP TRIGGER IF EXISTS on_new_student_registered ON profiles;
CREATE TRIGGER on_new_student_registered
  AFTER INSERT ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION notify_admins_of_new_student();
