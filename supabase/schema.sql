-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ============================================================================
-- 1. PROFILES (replaces users collection)
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
  skills text[], -- Array of strings
  badges text[],
  portfolio jsonb, -- Map
  experiences jsonb, -- List of maps
  
  -- Wallet & Subscription
  wallet_balance numeric default 0.0,
  subscription_tier text default 'Free',
  active_mode text default 'job',
  
  -- Worker Fields
  hourly_rate numeric,
  expected_salary numeric,
  rating numeric default 0.0,
  completed_projects integer default 0,
  
  -- Metadata
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- RLS: Profiles
alter table public.profiles enable row level security;

create policy "Public profiles are viewable by everyone."
  on public.profiles for select
  using ( true );

create policy "Users can insert their own profile."
  on public.profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update own profile."
  on public.profiles for update
  using ( auth.uid() = id );

-- Trigger: Create Profile on Signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, display_name)
  values (new.id, new.email, new.raw_user_meta_data->>'full_name');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
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
  
  -- Applicants (using JSONB for simple migration, ideally separate table)
  applicants jsonb default '{}'::jsonb,
  
  created_at timestamptz default now()
);

alter table public.job_posts enable row level security;

create policy "Job posts are viewable by everyone."
  on public.job_posts for select
  using ( true );

create policy "Owners can update their own job posts."
  on public.job_posts for update
  using ( auth.uid() = owner_id );

create policy "Owners can insert job posts."
  on public.job_posts for insert
  with check ( auth.uid() = owner_id );


-- ============================================================================
-- 3. PROJECTS (Milestone-based Work)
-- ============================================================================
create table public.projects (
  id uuid default uuid_generate_v4() primary key,
  title text not null,
  description text,
  owner_id uuid references public.profiles(id) not null,
  worker_id uuid references public.profiles(id),
  
  status text default 'ongoing', -- ongoing, completed, etc
  budget numeric default 0,
  escrow_balance numeric default 0,
  
  progress numeric default 0.0,
  
  created_at timestamptz default now()
);

alter table public.projects enable row level security;

create policy "Projects viewable by owner and assigned worker."
  on public.projects for select
  using ( auth.uid() = owner_id or auth.uid() = worker_id );

create policy "Owners can update their projects."
  on public.projects for update
  using ( auth.uid() = owner_id );


-- ============================================================================
-- 4. TRANSACTIONS
-- ============================================================================
create table public.transactions (
  id uuid default uuid_generate_v4() primary key,
  project_id uuid references public.projects(id),
  user_id uuid references public.profiles(id) not null,
  payer_id uuid references public.profiles(id),
  
  amount numeric not null,
  type text not null, -- escrow_deposit, release, refund
  status text default 'completed',
  
  created_at timestamptz default now()
);

alter table public.transactions enable row level security;

create policy "Users can see transactions they are involved in."
  on public.transactions for select
  using ( auth.uid() = user_id or auth.uid() = payer_id );


-- ============================================================================
-- 5. WITHDRAWAL REQUESTS
-- ============================================================================
create table public.withdrawal_requests (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) not null,
  amount numeric not null,
  status text default 'pending',
  bank_details jsonb,
  
  created_at timestamptz default now()
);

alter table public.withdrawal_requests enable row level security;

create policy "Users can see their own requests."
  on public.withdrawal_requests for select
  using ( auth.uid() = user_id );

-- Only admins should be able to update status, handled via Service Role or specific admin policy

-- ============================================================================
-- 6. FUNCTIONS (Replacing Cloud Functions logic)
-- ============================================================================

-- Function: Release Payment
create or replace function release_payment(project_id uuid, amount numeric)
returns void as $$
declare
  proj record;
  worker_id uuid;
begin
  -- Get project and lock row
  select * from public.projects where id = project_id for update into proj;
  
  -- Check Owner
  if proj.owner_id != auth.uid() then
    raise exception 'Permission denied';
  end if;
  
  -- Check Balance
  if proj.escrow_balance < amount then
    raise exception 'Insufficient escrow balance';
  end if;
  
  worker_id := proj.worker_id;
  
  -- Update Project Escrow
  update public.projects 
  set escrow_balance = escrow_balance - amount
  where id = project_id;
  
  -- Update Worker Wallet
  update public.profiles
  set wallet_balance = wallet_balance + amount
  where id = worker_id;
  
  -- Create Transaction Record
  insert into public.transactions (project_id, user_id, payer_id, amount, type)
  values (project_id, worker_id, auth.uid(), amount, 'milestone_payment');
  
end;
$$ language plpgsql security definer;

-- ============================================================================
-- 7. CAROUSEL SLIDES (Admin Managed)
-- ============================================================================
create table public.carousel_slides (
  id uuid default uuid_generate_v4() primary key,
  image_url text not null,
  nav_type text not null, -- 'internal', 'external'
  nav_url text, -- route name or external link
  order_index integer default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);

alter table public.carousel_slides enable row level security;

create policy "Carousel slides are viewable by everyone."
  on public.carousel_slides for select
  using ( true );

-- Policy for ADMINs to manage slides (requires specific admin role or verify via email/metadata)
-- For this MVP, we will allow authenticated users to insert/update if they are marked as 'admin' in profiles
-- OR for simplicity during development, allow all authenticated users (User needs to secure this later)
create policy "Authenticated users can manage slides."
  on public.carousel_slides for all
  using ( auth.role() = 'authenticated' );

