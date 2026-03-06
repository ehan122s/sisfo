-- Create announcements table
CREATE TABLE public.announcements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    target_role TEXT DEFAULT 'all' CHECK (target_role IN ('student', 'teacher', 'all')),
    author_id UUID REFERENCES public.profiles(id) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

-- Policies
-- 1. Admins can do EVERYTHING
CREATE POLICY "Admins can manage announcements" ON public.announcements
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
        )
    );

-- 2. Students and Teachers can VIEW active announcements targeting them
CREATE POLICY "Users can view active announcements" ON public.announcements
    FOR SELECT
    TO authenticated
    USING (
        is_active = true
        AND (
            target_role = 'all'
            OR
            target_role = (SELECT role FROM public.profiles WHERE id = auth.uid())
        )
    );
