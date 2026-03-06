-- =============================================================
-- RLS POLICIES — Admin & Profile Management
-- =============================================================

-- 1. COMPANIES (DUDI)
-- Allow authenticated users (Admin) to Insert, Update, Delete companies

create policy "Authenticated users can insert companies" on public.companies
  for insert with check (auth.role() = 'authenticated');

create policy "Authenticated users can update companies" on public.companies
  for update using (auth.role() = 'authenticated');

create policy "Authenticated users can delete companies" on public.companies
  for delete using (auth.role() = 'authenticated');


-- 2. PLACEMENTS
-- Allow authenticated users (Admin) to manage placements

create policy "Authenticated users can insert placements" on public.placements
  for insert with check (auth.role() = 'authenticated');

create policy "Authenticated users can update placements" on public.placements
  for update using (auth.role() = 'authenticated');

create policy "Authenticated users can delete placements" on public.placements
  for delete using (auth.role() = 'authenticated');

-- 3. PROFILES (For Delete Student & Admin update)

create policy "Authenticated users can delete profiles" on public.profiles
  for delete using (auth.role() = 'authenticated');

create policy "Authenticated users can update any profile" on public.profiles
  for update using (auth.role() = 'authenticated');


-- =============================================================
-- PROFILE STATUS COLUMN
-- =============================================================

-- Add 'status' column with check constraint
alter table public.profiles
add column status text default 'pending' check (status in ('active', 'pending', 'rejected', 'suspended'));

-- Update existing users to 'active' (so current users don't get locked out)
update public.profiles set status = 'active' where status = 'pending';
