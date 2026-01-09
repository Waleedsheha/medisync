-- Enable RLS
alter table notifications enable row level security;
-- Notifications Table
create table if not exists notifications (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users(id) not null,
    title text not null,
    body text not null,
    read boolean default false,
    created_at timestamptz default now()
);
-- Policies
create policy "Users can view their own notifications" on notifications for
select using (auth.uid() = user_id);
create policy "Users can update their own notifications" on notifications for
update using (auth.uid() = user_id);
-- Only system/triggers should insert notifications usually, but for now allow self-insert for testing
create policy "Users can insert their own notifications" on notifications for
insert with check (auth.uid() = user_id);