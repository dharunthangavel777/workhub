-- ============================================================================
-- RPC: Approve Bid (Creates Project, Contract, Milestones)
-- ============================================================================
create or replace function approve_bid(
  p_post_id uuid,
  p_worker_id uuid,
  p_worker_name text,
  p_owner_id uuid,
  p_title text,
  p_description text,
  p_mode text,
  p_budget numeric,
  p_milestones jsonb default '[]'::jsonb
)
returns uuid as $$
declare
  v_project_id uuid;
  v_contract_id uuid;
  v_milestone record;
begin
  -- 1. Validate Post Status
  if exists (select 1 from public.job_posts where id = p_post_id and status = 'filled') then
    raise exception 'Post already filled';
  end if;

  -- 2. Create Project
  insert into public.projects (
    job_id, worker_id, owner_id, worker_name, title, description,
    mode, budget, status, created_at
  ) values (
    p_post_id, p_worker_id, p_owner_id, p_worker_name, p_title, p_description,
    p_mode, p_budget, 'ongoing', now()
  ) returning id into v_project_id;

  -- 3. Create Contract
  insert into public.contracts (
    project_id, agreed_budget, start_date, expected_completion, 
    payment_type, platform_fee, owner_accepted, worker_accepted
  ) values (
    v_project_id, p_budget, now(), now() + interval '30 days',
    case when p_mode = 'hourly' then 'hourly' else 'fixed' end,
    10.0, false, false
  ) returning id into v_contract_id;

  -- 4. Create Milestones
  -- Extract from JSON array and insert
  -- Assuming p_milestones is like: '[{"title": "M1", "amount": 100, "deadline": "iso-date"}]'
  if jsonb_array_length(p_milestones) > 0 then
    insert into public.milestones (
      project_id, title, description, amount, deadline, status
    )
    select 
      v_project_id,
      (m->>'title'),
      (m->>'description'),
      (m->>'amount')::numeric,
      (m->>'deadline')::timestamptz,
      'pending'
    from jsonb_array_elements(p_milestones) as m;
  end if;

  -- 5. Update Job Post Status
  update public.job_posts 
  set status = 'filled', applicants = jsonb_set(applicants, ('{' || p_worker_id || ',status}')::text[], '"approved"')
  where id = p_post_id;

  return v_project_id;
end;
$$ language plpgsql security definer;


-- ============================================================================
-- RPC: Deposit to Escrow
-- ============================================================================
create or replace function deposit_to_escrow(
  p_project_id uuid,
  p_amount numeric,
  p_user_id uuid,
  p_session_id text
)
returns void as $$
begin
  -- Update Project Balance
  update public.projects
  set escrow_balance = escrow_balance + p_amount
  where id = p_project_id;

  -- Create Transaction Record
  insert into public.transactions (
    project_id, user_id, amount, type, description, metadata
  ) values (
    p_project_id, p_user_id, p_amount, 'escrow_deposit', 'Escrow Deposit', jsonb_build_object('paymentSessionId', p_session_id)
  );
end;
$$ language plpgsql security definer;

-- ============================================================================
-- RPC: Append Applicant (JSONB array support)
-- ============================================================================
create or replace function append_applicant(
  p_post_id uuid,
  p_user_id uuid,
  p_data jsonb,
  p_table text
)
returns void as $$
declare
  v_query text;
begin
  if p_table not in ('job_posts', 'project_posts') then
     raise exception 'Invalid table name';
  end if;

  execute format('
    update public.%I
    set applicants = jsonb_set(
       coalesce(applicants, ''{}''), 
       ''{%s}'', 
       ''%s''
    )
    where id = %L', 
    p_table, 
    p_user_id, 
    p_data, 
    p_post_id
  );
end;
$$ language plpgsql security definer;


-- ============================================================================
-- RPC: Update Applicant Status
-- ============================================================================
create or replace function update_applicant_status(
  p_post_id uuid,
  p_user_id uuid,
  p_status text,
  p_table text
)
returns void as $$
begin
  if p_table not in ('job_posts', 'project_posts') then
     raise exception 'Invalid table name';
  end if;

  execute format('
    update public.%I
    set applicants = jsonb_set(
       applicants, 
       ''{%s, status}'', 
       ''"%s"''
    )
    where id = %L', 
    p_table, 
    p_user_id, 
    p_status, 
    p_post_id
  );
end;
$$ language plpgsql security definer;


-- ============================================================================
-- RPC: Release Payment (Manual/Ad-hoc)
-- ============================================================================
create or replace function release_payment(
  p_project_id uuid,
  p_amount numeric
)
returns void as $$
begin
  -- 1. Deduct from Escrow
  update public.projects
  set escrow_balance = escrow_balance - p_amount
  where id = p_project_id;
  
  -- 2. NOTE: We need worker_id to credit. 
  -- Looking up worker_id from project:
  
  update public.profiles
  set wallet_balance = wallet_balance + p_amount
  where id = (select worker_id from public.projects where id = p_project_id);

  -- 3. Create Transaction
   insert into public.transactions (
    project_id, user_id, amount, type, description
  ) 
  select 
    p_project_id, 
    worker_id, 
    p_amount, 
    'payout', 
    'Manual Release'
  from public.projects where id = p_project_id;
end;
$$ language plpgsql security definer;


-- ============================================================================
-- RPC: Approve Milestone
-- ============================================================================
create or replace function approve_milestone(
  p_project_id uuid,
  p_milestone_id uuid
)
returns void as $$
declare
  v_amount numeric;
  v_worker_id uuid;
  v_owner_id uuid;
  v_platform_fee numeric;
  v_net_payout numeric;
  v_fee_amount numeric;
begin
  -- 1. Get Milestone Info
  select amount into v_amount from public.milestones where id = p_milestone_id;
  
  -- 2. Get Project Info
  select worker_id, owner_id into v_worker_id, v_owner_id 
  from public.projects where id = p_project_id;
  
  -- 3. Calculate Fee (Hardcoded 10% for now, or fetch from settings)
  v_platform_fee := 10.0;
  v_fee_amount := v_amount * (v_platform_fee / 100);
  v_net_payout := v_amount - v_fee_amount;
  
  -- 4. Update Project Balance
  update public.projects
  set escrow_balance = escrow_balance - v_amount
  where id = p_project_id;
  
  -- 5. Update Worker Wallet
  update public.profiles
  set wallet_balance = wallet_balance + v_net_payout
  where id = v_worker_id;
  
  -- 6. Update Milestone Status
  update public.milestones
  set status = 'approved', approved_at = now()
  where id = p_milestone_id;
  
  -- 7. Log Transaction
  insert into public.transactions (
    project_id, user_id, amount, type, description
  ) values (
    p_project_id, v_worker_id, v_net_payout, 'payout', 'Milestone Payout'
  );

end;
$$ language plpgsql security definer;


-- ============================================================================
-- RPC: DB Append Array (Generic Helper)
-- ============================================================================
create or replace function db_append_array(
  p_table_name text,
  p_col_name text,
  p_row_id uuid,
  p_new_item jsonb
)
returns void as $$
begin
  -- Only allow specific tables
  if p_table_name not in ('projects') then
     raise exception 'Invalid table';
  end if;

  execute format('
    update public.%I
    set %I = coalesce(%I, ''[]''::jsonb) || ''%s''::jsonb
    where id = %L',
    p_table_name, p_col_name, p_col_name, p_new_item, p_row_id
  );
end;
$$ language plpgsql security definer;


-- ============================================================================
-- RPC: Request Withdrawal
-- ============================================================================
create or replace function request_withdrawal(
  p_user_id uuid,
  p_amount numeric,
  p_bank_details jsonb
)
returns void as $$
begin
  -- 1. Check Balance (?) - Logic depends on if we trust client or verify balance in DB.
  -- Assuming balance check is done or we let it go negative for now/handled by constraint.
  
  -- 2. Insert Request
  insert into public.withdrawals (
    user_id, amount, status, bank_details, created_at
  ) values (
    p_user_id, p_amount, 'pending', p_bank_details, now()
  );
  
  -- 3. Deduct from wallet
  update public.profiles 
  set wallet_balance = wallet_balance - p_amount 
  where id = p_user_id;
end;
$$ language plpgsql security definer;

-- ============================================================================
-- RPC: Send Message (Atomic: Insert Message + Update Chat)
-- ============================================================================
create or replace function send_message(
  p_chat_id uuid,
  p_sender_id uuid,
  p_text text
)
returns void as $$
begin
  -- 1. Insert Message
  insert into public.messages (
    chat_id, sender_id, text, created_at
  ) values (
    p_chat_id, p_sender_id, p_text, now()
  );

  -- 2. Update Chat (Last Message & Timestamp)
  update public.chats
  set last_message = p_text,
      last_message_at = now(),
      updated_at = now()
  where id = p_chat_id;
end;
$$ language plpgsql security definer;
