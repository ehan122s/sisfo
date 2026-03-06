-- 1. Create Storage Bucket 'attendances'
insert into storage.buckets (id, name, public) 
values ('attendances', 'attendances', true)
on conflict (id) do nothing;

-- 2. Create Storage Bucket 'journal_evidence'
insert into storage.buckets (id, name, public) 
values ('journal_evidence', 'journal_evidence', true)
on conflict (id) do nothing;

-- 3. Security Policies for Storage
-- Enable RLS on storage.objects (if not enabled)
alter table storage.objects enable row level security;

-- Policy: Allow authenticated uploads to 'attendances' bucket
create policy "Allow authenticated uploads to attendances"
on storage.objects for insert
with check (
  bucket_id = 'attendances' and
  auth.role() = 'authenticated'
);

-- Policy: Allow public read access to 'attendances' (required for displaying images)
create policy "Allow public view attendances"
on storage.objects for select
using ( bucket_id = 'attendances' );

-- Policy: Allow authenticated uploads to 'journal_evidence' bucket
create policy "Allow authenticated uploads to journal_evidence"
on storage.objects for insert
with check (
  bucket_id = 'journal_evidence' and
  auth.role() = 'authenticated'
);

-- Policy: Allow public read access to 'journal_evidence'
create policy "Allow public view journal_evidence"
on storage.objects for select
using ( bucket_id = 'journal_evidence' );
