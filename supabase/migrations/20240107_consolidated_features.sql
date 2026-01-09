-- ==========================================
-- 1. PUBLIC PROFILES
-- ==========================================
create table if not exists profiles (
    id uuid references auth.users(id) on delete cascade primary key,
    full_name text,
    role text default 'user',
    avatar_url text,
    updated_at timestamptz
);
alter table profiles enable row level security;
create policy "Public profiles are viewable by everyone" on profiles for
select using (true);
create policy "Users can insert their own profile" on profiles for
insert with check (auth.uid() = id);
create policy "Users can update their own profile" on profiles for
update using (auth.uid() = id);
-- Trigger to create profile on signup
create or replace function public.handle_new_user() returns trigger as $$ begin
insert into public.profiles (id, full_name, role)
values (
        new.id,
        new.raw_user_meta_data->>'full_name',
        'doctor'
    );
-- default role
return new;
end;
$$ language plpgsql security definer;
create or replace trigger on_auth_user_created
after
insert on auth.users for each row execute procedure public.handle_new_user();
-- ==========================================
-- 2. CHAT & MESSAGING
-- ==========================================
create table if not exists conversations (
    id uuid primary key default gen_random_uuid(),
    name text,
    is_group boolean default false,
    created_at timestamptz default now()
);
create table if not exists conversation_members (
    conversation_id uuid references conversations(id) on delete cascade not null,
    user_id uuid references auth.users(id) not null,
    joined_at timestamptz default now(),
    primary key (conversation_id, user_id)
);
create table if not exists messages (
    id uuid primary key default gen_random_uuid(),
    conversation_id uuid references conversations(id) on delete cascade not null,
    sender_id uuid references auth.users(id) not null,
    body text not null,
    created_at timestamptz default now()
);
alter table conversations enable row level security;
alter table conversation_members enable row level security;
alter table messages enable row level security;
-- Policies
create policy "View my conversations" on conversations for
select using (
        exists (
            select 1
            from conversation_members
            where conversation_id = id
                and user_id = auth.uid()
        )
    );
create policy "View my members" on conversation_members for
select using (
        exists (
            select 1
            from conversation_members cm
            where cm.conversation_id = conversation_id
                and cm.user_id = auth.uid()
        )
    );
create policy "View my messages" on messages for
select using (
        exists (
            select 1
            from conversation_members
            where conversation_id = messages.conversation_id
                and user_id = auth.uid()
        )
    );
create policy "Send messages" on messages for
insert with check (
        exists (
            select 1
            from conversation_members
            where conversation_id = messages.conversation_id
                and user_id = auth.uid()
        )
    );
-- ==========================================
-- 3. NOTIFICATIONS
-- ==========================================
create table if not exists notifications (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users(id) not null,
    title text not null,
    body text not null,
    read boolean default false,
    created_at timestamptz default now()
);
alter table notifications enable row level security;
create policy "View my notifications" on notifications for
select using (auth.uid() = user_id);
create policy "Update my notifications" on notifications for
update using (auth.uid() = user_id);