-- ============================================================================
-- WORK HUB SUPABASE SCHEMA (COMPLETE)
-- ============================================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ============================================================================
-- 1. PROFILES
-- ============================================================================
create table public.profiles (
  id uuid references auth.users(id) on delete cascade not null primary key,
  email text not null,
  role text default 'worker',
  display_name text,
  photo_url text,
  username text unique,
  bio text,
  location text,
  job_category text,
  skills text[],
  badges text[],
  portfolio jsonb,
  experiences jsonb,
  
  wallet_balance numeric default 0.0,
  subscription_tier text default 'Free',
  active_mode text default 'job',
  
  hourly_rate numeric,
  expected_salary numeric,
  rating numeric default 0.0,
  completed_projects integer default 0,
  
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "Public profiles are viewable by everyone." on public.profiles for select using (true);
create policy "Users can update own profile." on public.profiles for update using (auth.uid() = id);
create policy "Users can insert own profile." on public.profiles for insert with check (auth.uid() = id);

-- Trigger: Create Profile on Signup
create or replace function public.handle_new_user() returns trigger as $$
begin
  insert into public.profiles (id, email, display_name)
  values (new.id, new.email, new.raw_user_meta_data->>'full_name');
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================================
-- 2. JOB POSTS
-- ============================================================================
create table public.job_posts (
  id uuid default uuid_generate_v4() primary key,
  owner_id uuid references public.profiles(id) not null,
  job_title text not null,
  job_category text not null,
  job_summary text,
  status text default 'open',
  budget_min numeric,
  budget_max numeric,
  applicants jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

alter table public.job_posts enable row level security;
create policy "Job posts are viewable by everyone." on public.job_posts for select using (true);
create policy "Owners can update their own job posts." on public.job_posts for update using (auth.uid() = owner_id);
create policy "Owners can insert job posts." on public.job_posts for insert with check (auth.uid() = owner_id);

-- ============================================================================
-- 3. PROJECT POSTS (For Freelancers)
-- ============================================================================
create table public.project_posts (
  id uuid default uuid_generate_v4() primary key,
  owner_id uuid references public.profiles(id) not null,
  title text not null,
  description text,
  category text,
  budget numeric,
  status text default 'open',
  applicants jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

alter table public.project_posts enable row level security;
create policy "Project posts are viewable by everyone." on public.project_posts for select using (true);
create policy "Owners can update their own project posts." on public.project_posts for update using (auth.uid() = owner_id);
create policy "Owners can insert project posts." on public.project_posts for insert with check (auth.uid() = owner_id);


-- ============================================================================
-- 4. PROJECTS (Ongoing Work)
-- ============================================================================
create table public.projects (
  id uuid default uuid_generate_v4() primary key,
  title text not null,
  description text,
  owner_id uuid references public.profiles(id) not null,
  worker_id uuid references public.profiles(id),
  job_id uuid, -- Optional link to job post
  worker_name text,
  mode text, -- hourly, fixed
  
  status text default 'ongoing',
  budget numeric default 0,
  escrow_balance numeric default 0,
  progress numeric default 0.0,
  
  shared_files jsonb default '[]'::jsonb,
  
  created_at timestamptz default now()
);

alter table public.projects enable row level security;
create policy "Projects viewable by owner and worker." on public.projects for select using (auth.uid() = owner_id or auth.uid() = worker_id);
create policy "Owners can update their projects." on public.projects for update using (auth.uid() = owner_id);

-- ============================================================================
-- 5. CONTRACTS
-- ============================================================================
create table public.contracts (
  id uuid default uuid_generate_v4() primary key,
  project_id uuid references public.projects(id) not null,
  agreed_budget numeric,
  platform_fee numeric default 10.0,
  payment_type text, -- hourly, fixed
  start_date timestamptz,
  expected_completion timestamptz,
  
  owner_accepted boolean default false,
  worker_accepted boolean default false,
  status text default 'draft', -- draft, active, terminated, completed
  
  terms text,
  
  created_at timestamptz default now()
);

alter table public.contracts enable row level security;
create policy "Contracts viewable by project members." on public.contracts for select using (
  exists (select 1 from public.projects where id = project_id and (owner_id = auth.uid() or worker_id = auth.uid()))
);
create policy "Updates by project members." on public.contracts for update using (
  exists (select 1 from public.projects where id = project_id and (owner_id = auth.uid() or worker_id = auth.uid()))
);


-- ============================================================================
-- 6. MILESTONES
-- ============================================================================
create table public.milestones (
  id uuid default uuid_generate_v4() primary key,
  project_id uuid references public.projects(id) not null,
  title text not null,
  description text,
  amount numeric not null,
  deadline timestamptz,
  status text default 'pending', -- pending, submitted, approved, paid, revision_requested
  
  submission_note text,
  revision_note text,
  attachments text[], -- List of URLs
  
  approved_at timestamptz,
  submitted_at timestamptz,
  created_at timestamptz default now()
);

alter table public.milestones enable row level security;
create policy "Milestones viewable by project members." on public.milestones for select using (
  exists (select 1 from public.projects where id = project_id and (owner_id = auth.uid() or worker_id = auth.uid()))
);
create policy "Updates by project members." on public.milestones for update using (
  exists (select 1 from public.projects where id = project_id and (owner_id = auth.uid() or worker_id = auth.uid()))
);
create policy "Inserts by project members." on public.milestones for insert with check (
  exists (select 1 from public.projects where id = project_id and (owner_id = auth.uid() or worker_id = auth.uid()))
);


-- ============================================================================
-- 7. TRANSACTIONS
-- ============================================================================
create table public.transactions (
  id uuid default uuid_generate_v4() primary key,
  project_id uuid references public.projects(id),
  user_id uuid references public.profiles(id) not null, -- person receiving or related
  amount numeric not null,
  type text not null, -- escrow_deposit, payout, refund
  description text,
  status text default 'completed',
  metadata jsonb,
  
  created_at timestamptz default now()
);

alter table public.transactions enable row level security;
create policy "View own transactions." on public.transactions for select using (auth.uid() = user_id);


-- ============================================================================
-- 8. WITHDRAWALS (Aligned with SupabaseJobRepository)
-- ============================================================================
create table public.withdrawals (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) not null,
  amount numeric not null,
  status text default 'pending',
  bank_details jsonb,
  failure_reason text,
  transaction_id text,
  
  processed_at timestamptz,
  created_at timestamptz default now()
);

alter table public.withdrawals enable row level security;
create policy "View own withdrawals." on public.withdrawals for select using (auth.uid() = user_id);
-- Inserts strictly via RPC suggested, but allowing insert for now:
create policy "Insert own withdrawals." on public.withdrawals for insert with check (auth.uid() = user_id);


-- ============================================================================
-- 9. CHATS & MESSAGES
-- ============================================================================
create table public.chats (
  id uuid default uuid_generate_v4() primary key,
  participants text[], -- array of user_ids as strings (or uuids)
  last_message text,
  last_message_at timestamptz default now(),
  updated_at timestamptz default now(),
  created_at timestamptz default now()
);

create table public.messages (
  id uuid default uuid_generate_v4() primary key,
  chat_id uuid references public.chats(id) not null,
  sender_id uuid references public.profiles(id) not null,
  text text,
  created_at timestamptz default now()
);

alter table public.chats enable row level security;
create policy "View chats participant." on public.chats for select using (auth.uid()::text = any(participants));
create policy "Insert chats participant." on public.chats for insert with check (auth.uid()::text = any(participants));
create policy "Update chats participant." on public.chats for update using (auth.uid()::text = any(participants));

alter table public.messages enable row level security;
create policy "View messages in own chats." on public.messages for select using (
  exists (select 1 from public.chats where id = chat_id and auth.uid()::text = any(participants))
);
create policy "Insert messages in own chats." on public.messages for insert with check (
  exists (select 1 from public.chats where id = chat_id and auth.uid()::text = any(participants))
);


-- ============================================================================
-- 10. RATINGS
-- ============================================================================
create table public.ratings (
  id uuid default uuid_generate_v4() primary key,
  project_id uuid references public.projects(id),
  reviewer_id uuid references public.profiles(id),
  reviewee_id uuid references public.profiles(id),
  rating numeric not null,
  comment text,
  rater_role text, -- owner, worker
  created_at timestamptz default now()
);

alter table public.ratings enable row level security;
create policy "View ratings." on public.ratings for select using (true);
create policy "Insert ratings." on public.ratings for insert with check (auth.uid() = reviewer_id);


-- ============================================================================
-- 11. TIME ENTRIES
-- ============================================================================
create table public.time_entries (
  id uuid default uuid_generate_v4() primary key,
  project_id uuid references public.projects(id) not null,
  worker_id uuid references public.profiles(id) not null,
  description text,
  start_time timestamptz,
  end_time timestamptz,
  duration_minutes integer,
  status text default 'pending', -- pending, approved, rejected
  rejection_reason text,
  
  created_at timestamptz default now()
);

alter table public.time_entries enable row level security;
create policy "View time entries project members." on public.time_entries for select using (
  exists (select 1 from public.projects where id = project_id and (owner_id = auth.uid() or worker_id = auth.uid()))
);
create policy "Insert time entries worker." on public.time_entries for insert with check (auth.uid() = worker_id);
create policy "Update time entries project members." on public.time_entries for update using (
  exists (select 1 from public.projects where id = project_id and (owner_id = auth.uid() or worker_id = auth.uid()))
);


-- ============================================================================
-- 12. DISPUTES
-- ============================================================================
create table public.disputes (
  id uuid default uuid_generate_v4() primary key,
  project_id uuid references public.projects(id) not null,
  raised_by_id uuid references public.profiles(id) not null,
  reason text,
  description text,
  status text default 'raised', -- raised, resolver_assigned, resolved
  admin_id uuid,
  resolution text,
  evidence_files text[],
  
  created_at timestamptz default now(),
  resolved_at timestamptz
);

alter table public.disputes enable row level security;
create policy "View disputes project members." on public.disputes for select using (
  exists (select 1 from public.projects where id = project_id and (owner_id = auth.uid() or worker_id = auth.uid()))
);
create policy "Insert disputes project members." on public.disputes for insert with check (
  exists (select 1 from public.projects where id = project_id and (owner_id = auth.uid() or worker_id = auth.uid()))
);
