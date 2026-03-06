-- ============================================================
-- E-PKL Database Setup — Step 3: RLS Policies
-- ============================================================
-- Row Level Security policies for all tables.
-- Run after 02_tables.sql.
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- HELPER: get_my_role() — used by many policies to avoid
-- RLS recursion when checking the caller's role.
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_role text;
BEGIN
  SELECT role INTO user_role
  FROM public.profiles
  WHERE id = auth.uid();
  RETURN user_role;
END;
$$;

-- ============================================================
-- PROFILES
-- ============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Admin full access
CREATE POLICY "Admins have full access to profiles"
ON public.profiles FOR ALL TO authenticated
USING (public.get_my_role() = 'admin')
WITH CHECK (public.get_my_role() = 'admin');

-- Users can read their own profile
CREATE POLICY "Users can view own profile"
ON public.profiles FOR SELECT TO authenticated
USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- ============================================================
-- COMPANIES
-- ============================================================
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;

-- Admin full access
CREATE POLICY "Admins can manage companies"
ON public.companies FOR ALL TO authenticated
USING (public.get_my_role() = 'admin')
WITH CHECK (public.get_my_role() = 'admin');

-- All authenticated users can view companies
CREATE POLICY "Authenticated users can view companies"
ON public.companies FOR SELECT TO authenticated
USING (true);

-- ============================================================
-- PLACEMENTS
-- ============================================================
ALTER TABLE public.placements ENABLE ROW LEVEL SECURITY;

-- Admin full access
CREATE POLICY "Admins can manage placements"
ON public.placements FOR ALL TO authenticated
USING (public.get_my_role() = 'admin')
WITH CHECK (public.get_my_role() = 'admin');

-- Students can view their own placements
CREATE POLICY "Students can view own placements"
ON public.placements FOR SELECT TO authenticated
USING (auth.uid() = student_id);

-- Teachers can view placements for their assigned companies
CREATE POLICY "Teachers can view assigned placements"
ON public.placements FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.supervisor_assignments sa
    WHERE sa.company_id = placements.company_id
    AND sa.teacher_id = auth.uid()
  )
);

-- ============================================================
-- ATTENDANCE_LOGS
-- ============================================================
ALTER TABLE public.attendance_logs ENABLE ROW LEVEL SECURITY;

-- Students can insert their own attendance
CREATE POLICY "Students can insert own attendance"
ON public.attendance_logs FOR INSERT TO authenticated
WITH CHECK (auth.uid() = student_id);

-- Students can view their own attendance
CREATE POLICY "Students can view own attendance"
ON public.attendance_logs FOR SELECT TO authenticated
USING (auth.uid() = student_id);

-- Students can update their own attendance (for check-out)
CREATE POLICY "Students can update own attendance"
ON public.attendance_logs FOR UPDATE TO authenticated
USING (auth.uid() = student_id)
WITH CHECK (auth.uid() = student_id);

-- Admins and Teachers can view all attendance
CREATE POLICY "Admins and Teachers can view all attendance"
ON public.attendance_logs FOR SELECT TO authenticated
USING (
  public.get_my_role() IN ('admin', 'teacher', 'supervisor')
);

-- Admins can manage all attendance
CREATE POLICY "Admins can manage all attendance"
ON public.attendance_logs FOR ALL TO authenticated
USING (public.get_my_role() = 'admin')
WITH CHECK (public.get_my_role() = 'admin');

-- ============================================================
-- DAILY_JOURNALS
-- ============================================================
ALTER TABLE public.daily_journals ENABLE ROW LEVEL SECURITY;

-- Students can insert their own journals
CREATE POLICY "Students can insert own journals"
ON public.daily_journals FOR INSERT TO authenticated
WITH CHECK (auth.uid() = student_id);

-- Students can view their own journals
CREATE POLICY "Students can view own journals"
ON public.daily_journals FOR SELECT TO authenticated
USING (auth.uid() = student_id);

-- Students can update their own journals
CREATE POLICY "Students can update own journals"
ON public.daily_journals FOR UPDATE TO authenticated
USING (auth.uid() = student_id)
WITH CHECK (auth.uid() = student_id);

-- Admins and Teachers view all journals
CREATE POLICY "Admins and Teachers can view all journals"
ON public.daily_journals FOR SELECT TO authenticated
USING (
  public.get_my_role() IN ('admin', 'teacher', 'supervisor')
);

-- Teachers and Admins can update journals (approve)
CREATE POLICY "Teachers and Admins can update journals"
ON public.daily_journals FOR UPDATE TO authenticated
USING (public.get_my_role() IN ('admin', 'teacher', 'supervisor'))
WITH CHECK (public.get_my_role() IN ('admin', 'teacher', 'supervisor'));

-- Admins can manage all journals
CREATE POLICY "Admins can manage all journals"
ON public.daily_journals FOR ALL TO authenticated
USING (public.get_my_role() = 'admin')
WITH CHECK (public.get_my_role() = 'admin');

-- ============================================================
-- SUPERVISOR_ASSIGNMENTS
-- ============================================================
ALTER TABLE public.supervisor_assignments ENABLE ROW LEVEL SECURITY;

-- Teachers can view their own assignments
CREATE POLICY "Teachers can view own assignments"
ON public.supervisor_assignments FOR SELECT TO authenticated
USING (auth.uid() = teacher_id);

-- Admins can manage supervisor assignments
CREATE POLICY "Admins can manage supervisor assignments"
ON public.supervisor_assignments FOR ALL TO authenticated
USING (public.get_my_role() = 'admin')
WITH CHECK (public.get_my_role() = 'admin');

-- ============================================================
-- ANNOUNCEMENTS
-- ============================================================
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

-- Admins can manage announcements
CREATE POLICY "Admins can manage announcements"
ON public.announcements FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
  )
);

-- Users can view active announcements targeting them
CREATE POLICY "Users can view active announcements"
ON public.announcements FOR SELECT TO authenticated
USING (
  is_active = true
  AND (
    target_role = 'all'
    OR target_role = (SELECT role FROM public.profiles WHERE id = auth.uid())
  )
);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Users can view their own notifications
CREATE POLICY "Users can view their own notifications"
ON public.notifications FOR SELECT
USING (auth.uid() = user_id);

-- Users can update (mark as read) their own notifications
CREATE POLICY "Users can update their own notifications"
ON public.notifications FOR UPDATE
USING (auth.uid() = user_id);

-- ============================================================
-- APP_CONFIG
-- ============================================================
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view config"
ON public.app_config FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
  )
);

CREATE POLICY "Admins can update config"
ON public.app_config FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
  )
);

CREATE POLICY "Admins can insert config"
ON public.app_config FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
  )
);

-- ============================================================
-- AUDIT_LOGS
-- ============================================================
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Admins can view all audit logs
CREATE POLICY "Admins can view audit logs"
ON public.audit_logs FOR SELECT TO authenticated
USING (public.get_my_role() = 'admin');

-- Authenticated users can insert audit logs
CREATE POLICY "Authenticated users can insert audit logs"
ON public.audit_logs FOR INSERT TO authenticated
WITH CHECK (auth.uid() = actor_id);
