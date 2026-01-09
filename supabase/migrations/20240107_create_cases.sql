create table if not exists cases (
    id uuid primary key default gen_random_uuid(),
    author_id uuid references auth.users(id) not null,
    title text not null,
    body text,
    images text [],
    created_at timestamptz default now()
);
-- Comments Table
create table if not exists case_comments (
    id uuid primary key default gen_random_uuid(),
    case_id uuid references cases(id) on delete cascade not null,
    author_id uuid references auth.users(id) not null,
    body text not null,
    created_at timestamptz default now()
);

-- Enable RLS
alter table cases enable row level security;
alter table case_comments enable row level security;
-- Policies for Cases
create policy "Cases are viewable by everyone" on cases for
select using (true);
create policy "Users can insert their own cases" on cases for
insert with check (auth.uid() = author_id);
create policy "Users can update their own cases" on cases for
update using (auth.uid() = author_id);
-- Policies for Comments
create policy "Comments are viewable by everyone" on case_comments for
select using (true);
create policy "Users can insert their own comments" on case_comments for
insert with check (auth.uid() = author_id);