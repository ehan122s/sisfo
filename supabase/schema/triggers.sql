-- 1. Create Function to handle new user
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, nisn)
  values (
    new.id, 
    coalesce(new.raw_user_meta_data ->> 'full_name', 'Siswa Baru'),
    coalesce(new.raw_user_meta_data ->> 'nisn', 'NISN-' || floor(random() * 100000)::text) -- Temporary NISN
  );
  return new;
end;
$$;

-- 2. Create Trigger
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 3. MANUAL FIX: Insert missing profiles for existing users
insert into public.profiles (id, full_name, nisn)
select 
  id, 
  'Siswa Baru', 
  'NISN-' || floor(random() * 100000)::text
from auth.users 
where id not in (select id from public.profiles);
