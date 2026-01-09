-- ============================================================
-- 1. Create PROFILES Table
-- ============================================================
-- secure profile data linked to auth.users
create table public.profiles (
    id uuid not null references auth.users(id) on delete cascade,
    email text,
    full_name text,
    avatar_url text,
    role text check (role in ('doctor', 'nurse', 'admin', 'patient')) default 'patient',
    -- Metadata
    created_at timestamptz default now(),
    updated_at timestamptz default now(),
    primary key (id)
);
-- ============================================================
-- 2. Row Level Security (RLS)
-- ============================================================
-- Enable security
alter table public.profiles enable row level security;
-- Policy: Anyone can view profiles (needed for sharing avatars/names)
create policy "Public profiles are viewable by everyone." on profiles for
select using (true);
-- Policy: Users can insert their own profile
create policy "Users can insert their own profile." on profiles for
insert with check (auth.uid() = id);
-- Policy: Users can update own profile
create policy "Users can update own profile." on profiles for
update using (auth.uid() = id);
-- ============================================================
-- 3. Automation (Triggers)
-- ============================================================
-- Function to handle new user signup
create or replace function public.handle_new_user() returns trigger as $$ begin
insert into public.profiles (id, email, full_name, avatar_url)
values (
        new.id,
        new.email,
        new.raw_user_meta_data->>'full_name',
        new.raw_user_meta_data->>'avatar_url'
    );
return new;
end;
$$ language plpgsql security definer;
-- Trigger to call the function on every new auth.user
create or replace trigger on_auth_user_created
after
insert on auth.users for each row execute procedure public.handle_new_user();