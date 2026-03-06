-- Add new columns to profiles table for detailed student data
ALTER TABLE "public"."profiles" 
ADD COLUMN IF NOT EXISTS "nipd" text,
ADD COLUMN IF NOT EXISTS "gender" text CHECK (gender IN ('L', 'P')),
ADD COLUMN IF NOT EXISTS "birth_place" text,
ADD COLUMN IF NOT EXISTS "birth_date" date,
ADD COLUMN IF NOT EXISTS "nik" text,
ADD COLUMN IF NOT EXISTS "religion" text,
ADD COLUMN IF NOT EXISTS "address" text,
ADD COLUMN IF NOT EXISTS "father_name" text,
ADD COLUMN IF NOT EXISTS "mother_name" text;

-- Add comment to documentation
COMMENT ON COLUMN "public"."profiles"."nipd" IS 'Nomor Induk Peserta Didik';
COMMENT ON COLUMN "public"."profiles"."gender" IS 'Jenis Kelamin (L/P)';
COMMENT ON COLUMN "public"."profiles"."nik" IS 'Nomor Induk Kependudukan';
