-- Enable RLS
alter table conversations enable row level security;
alter table conversation_members enable row level security;
alter table messages enable row level security;
-- Conversations Table
create table if not exists conversations (
    id uuid primary key default gen_random_uuid(),
    name text,
    -- null for 1-on-1, set for groups
    is_group boolean default false,
    created_at timestamptz default now()
);
-- Members Table (Who is in which chat)
create table if not exists conversation_members (
    conversation_id uuid references conversations(id) on delete cascade not null,
    user_id uuid references auth.users(id) not null,
    joined_at timestamptz default now(),
    primary key (conversation_id, user_id)
);
-- Messages Table
create table if not exists messages (
    id uuid primary key default gen_random_uuid(),
    conversation_id uuid references conversations(id) on delete cascade not null,
    sender_id uuid references auth.users(id) not null,
    body text not null,
    created_at timestamptz default now()
);
-- Policies for Conversations
create policy "Users can view conversations they are members of" on conversations for
select using (
        exists (
            select 1
            from conversation_members
            where conversation_id = conversations.id
                and user_id = auth.uid()
        )
    );
-- Policies for Members
create policy "Users can view members of their conversations" on conversation_members for
select using (
        exists (
            select 1
            from conversation_members cm
            where cm.conversation_id = conversation_members.conversation_id
                and cm.user_id = auth.uid()
        )
    );
-- Policies for Messages
create policy "Users can view messages in their conversations" on messages for
select using (
        exists (
            select 1
            from conversation_members
            where conversation_id = messages.conversation_id
                and user_id = auth.uid()
        )
    );
create policy "Users can insert messages in their conversations" on messages for
insert with check (
        auth.uid() = sender_id
        and exists (
            select 1
            from conversation_members
            where conversation_id = messages.conversation_id
                and user_id = auth.uid()
        )
    );