-- ReLearn MVP schema
-- Apply with: supabase db reset (local) / supabase db push (remote)

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
do $$ begin
  create type public.user_role as enum ('admin', 'collector');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.beneficiary_type as enum ('pupil', 'teacher');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.material_unit as enum ('kg', 'piece');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.ledger_type as enum ('earn', 'redeem', 'adjust', 'void');
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create sequence if not exists public.beneficiary_seq start 1;

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- Alphabet excludes 0/O and 1/I to keep IDs readable on printed cards.
create or replace function public.id_alphabet()
returns text language sql immutable as $$
  select '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'::text;
$$;

create or replace function public.check_char(p_body text)
returns text language plpgsql immutable as $$
declare
  alphabet text := public.id_alphabet();
  h int := 0;
  i int;
begin
  for i in 1..length(p_body) loop
    h := (h * 31 + ascii(substr(p_body, i, 1))) % length(alphabet);
  end loop;
  return substr(alphabet, h + 1, 1);
end $$;

create or replace function public.next_public_id()
returns text language plpgsql security definer set search_path = public as $$
declare
  alphabet text := public.id_alphabet();
  n bigint := nextval('public.beneficiary_seq');
  body text;
  rnd text := '';
  i int;
begin
  for i in 1..3 loop
    rnd := rnd || substr(alphabet, 1 + (get_byte(gen_random_bytes(1), 0) % length(alphabet)), 1);
  end loop;
  body := lpad(n::text, 4, '0') || '-' || rnd;
  return 'RL-' || body || public.check_char(body);
end $$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and active
  );
$$;

create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and active
  );
$$;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------
create table if not exists public.schools (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text,
  contact_name text,
  contact_phone text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null default '',
  role public.user_role not null default 'collector',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.beneficiaries (
  id uuid primary key default gen_random_uuid(),
  public_id text not null unique default public.next_public_id(),
  school_id uuid not null references public.schools (id),
  full_name text not null,
  type public.beneficiary_type not null,
  class text,
  guardian_phone text,
  active boolean not null default true,
  card_blocked boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pupil_class_required check (type <> 'pupil' or class is not null)
);

create table if not exists public.materials (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  unit public.material_unit not null,
  points_per_unit numeric(10, 2) not null check (points_per_unit >= 0),
  allowed boolean not null default true,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.collections (
  id uuid primary key default gen_random_uuid(),
  beneficiary_id uuid not null references public.beneficiaries (id),
  collector_id uuid not null references public.profiles (id),
  school_id uuid not null references public.schools (id),
  idempotency_key text not null unique,
  note text,
  voided boolean not null default false,
  voided_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.collection_items (
  id uuid primary key default gen_random_uuid(),
  collection_id uuid not null references public.collections (id) on delete cascade,
  material_id uuid not null references public.materials (id),
  quantity numeric(10, 3) not null check (quantity > 0),
  rate_snapshot numeric(10, 2) not null check (rate_snapshot >= 0),
  points integer not null check (points >= 0)
);

create table if not exists public.rewards (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  points_cost integer not null check (points_cost > 0),
  stock integer not null default 0 check (stock >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.redemptions (
  id uuid primary key default gen_random_uuid(),
  beneficiary_id uuid not null references public.beneficiaries (id),
  reward_id uuid not null references public.rewards (id),
  qty integer not null check (qty > 0),
  points_spent integer not null check (points_spent > 0),
  collector_id uuid not null references public.profiles (id),
  idempotency_key text not null unique,
  voided boolean not null default false,
  voided_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.points_ledger (
  id bigserial primary key,
  beneficiary_id uuid not null references public.beneficiaries (id),
  type public.ledger_type not null,
  points integer not null check (points <> 0),
  ref_id uuid,
  note text,
  actor_id uuid references public.profiles (id),
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
create index if not exists beneficiaries_school_idx on public.beneficiaries (school_id);
create index if not exists beneficiaries_search_idx on public.beneficiaries (lower(full_name));
create index if not exists collections_beneficiary_idx on public.collections (beneficiary_id, created_at desc);
create index if not exists collections_collector_idx on public.collections (collector_id, created_at desc);
create index if not exists redemptions_beneficiary_idx on public.redemptions (beneficiary_id, created_at desc);
create index if not exists ledger_beneficiary_idx on public.points_ledger (beneficiary_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Append-only ledger
-- ---------------------------------------------------------------------------
create or replace function public.forbid_ledger_mutation()
returns trigger language plpgsql as $$
begin
  raise exception 'points_ledger is append-only; post a void or adjust entry instead';
end $$;

drop trigger if exists points_ledger_append_only on public.points_ledger;
create trigger points_ledger_append_only
  before update or delete on public.points_ledger
  for each row execute function public.forbid_ledger_mutation();

drop trigger if exists schools_touch on public.schools;
create trigger schools_touch before update on public.schools
  for each row execute function public.touch_updated_at();

drop trigger if exists beneficiaries_touch on public.beneficiaries;
create trigger beneficiaries_touch before update on public.beneficiaries
  for each row execute function public.touch_updated_at();

drop trigger if exists materials_touch on public.materials;
create trigger materials_touch before update on public.materials
  for each row execute function public.touch_updated_at();

drop trigger if exists rewards_touch on public.rewards;
create trigger rewards_touch before update on public.rewards
  for each row execute function public.touch_updated_at();

drop trigger if exists profiles_touch on public.profiles;
create trigger profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- Balance view
-- ---------------------------------------------------------------------------
create or replace view public.beneficiary_balances
with (security_invoker = true) as
select b.id as beneficiary_id,
       coalesce(sum(l.points), 0)::bigint as balance
from public.beneficiaries b
left join public.points_ledger l on l.beneficiary_id = b.id
group by b.id;

-- ---------------------------------------------------------------------------
-- RPC: record a collection
-- ---------------------------------------------------------------------------
create or replace function public.record_collection(
  p_beneficiary_id uuid,
  p_items jsonb,
  p_idempotency_key text,
  p_note text default null
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_actor uuid := auth.uid();
  v_beneficiary public.beneficiaries%rowtype;
  v_collection_id uuid;
  v_item jsonb;
  v_material public.materials%rowtype;
  v_qty numeric(10, 3);
  v_points integer;
  v_total integer := 0;
  v_existing public.collections%rowtype;
  v_balance bigint;
begin
  if not public.is_staff() then
    raise exception 'not authorised';
  end if;
  if p_idempotency_key is null or length(p_idempotency_key) < 8 then
    raise exception 'idempotency key required';
  end if;

  select * into v_existing from public.collections where idempotency_key = p_idempotency_key;
  if found then
    select coalesce(sum(points), 0) into v_balance
      from public.points_ledger where beneficiary_id = v_existing.beneficiary_id;
    return jsonb_build_object(
      'collection_id', v_existing.id,
      'beneficiary_id', v_existing.beneficiary_id,
      'points', (select coalesce(sum(points), 0) from public.collection_items where collection_id = v_existing.id),
      'balance', v_balance,
      'duplicate', true
    );
  end if;

  select * into v_beneficiary from public.beneficiaries where id = p_beneficiary_id for share;
  if not found then raise exception 'beneficiary not found'; end if;
  if not v_beneficiary.active then raise exception 'beneficiary is inactive'; end if;
  if v_beneficiary.card_blocked then raise exception 'card is blocked'; end if;
  if p_items is null or jsonb_array_length(p_items) = 0 then
    raise exception 'at least one material line is required';
  end if;

  insert into public.collections (beneficiary_id, collector_id, school_id, idempotency_key, note)
  values (p_beneficiary_id, v_actor, v_beneficiary.school_id, p_idempotency_key, p_note)
  returning id into v_collection_id;

  for v_item in select * from jsonb_array_elements(p_items) loop
    select * into v_material from public.materials where id = (v_item->>'material_id')::uuid;
    if not found then raise exception 'material not found'; end if;
    if not v_material.allowed then raise exception 'material % is not accepted', v_material.name; end if;
    if not v_material.active then raise exception 'material % is inactive', v_material.name; end if;

    v_qty := (v_item->>'quantity')::numeric;
    if v_qty is null or v_qty <= 0 then raise exception 'quantity must be greater than zero'; end if;

    v_points := round(v_qty * v_material.points_per_unit)::integer;
    insert into public.collection_items (collection_id, material_id, quantity, rate_snapshot, points)
    values (v_collection_id, v_material.id, v_qty, v_material.points_per_unit, v_points);
    v_total := v_total + v_points;
  end loop;

  insert into public.points_ledger (beneficiary_id, type, points, ref_id, actor_id)
  values (p_beneficiary_id, 'earn', v_total, v_collection_id, v_actor);

  select coalesce(sum(points), 0) into v_balance
    from public.points_ledger where beneficiary_id = p_beneficiary_id;

  return jsonb_build_object(
    'collection_id', v_collection_id,
    'beneficiary_id', p_beneficiary_id,
    'points', v_total,
    'balance', v_balance,
    'duplicate', false
  );
end $$;

-- ---------------------------------------------------------------------------
-- RPC: redeem a reward
-- ---------------------------------------------------------------------------
create or replace function public.redeem_reward(
  p_beneficiary_id uuid,
  p_reward_id uuid,
  p_qty integer,
  p_idempotency_key text
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_actor uuid := auth.uid();
  v_beneficiary public.beneficiaries%rowtype;
  v_reward public.rewards%rowtype;
  v_cost integer;
  v_balance bigint;
  v_redemption public.redemptions%rowtype;
begin
  if not public.is_staff() then raise exception 'not authorised'; end if;
  if p_qty is null or p_qty <= 0 then raise exception 'quantity must be greater than zero'; end if;
  if p_idempotency_key is null or length(p_idempotency_key) < 8 then
    raise exception 'idempotency key required';
  end if;

  select * into v_redemption from public.redemptions where idempotency_key = p_idempotency_key;
  if found then
    select coalesce(sum(points), 0) into v_balance
      from public.points_ledger where beneficiary_id = v_redemption.beneficiary_id;
    return jsonb_build_object(
      'redemption_id', v_redemption.id,
      'beneficiary_id', v_redemption.beneficiary_id,
      'points', -v_redemption.points_spent,
      'balance', v_balance,
      'duplicate', true
    );
  end if;

  select * into v_beneficiary from public.beneficiaries where id = p_beneficiary_id for share;
  if not found then raise exception 'beneficiary not found'; end if;
  if not v_beneficiary.active then raise exception 'beneficiary is inactive'; end if;
  if v_beneficiary.card_blocked then raise exception 'card is blocked'; end if;

  -- Serialise redemptions per beneficiary so two devices cannot spend the same points.
  perform pg_advisory_xact_lock(hashtext(p_beneficiary_id::text));

  select * into v_reward from public.rewards where id = p_reward_id for update;
  if not found then raise exception 'reward not found'; end if;
  if not v_reward.active then raise exception 'reward is inactive'; end if;
  if v_reward.stock < p_qty then raise exception 'insufficient stock'; end if;

  v_cost := v_reward.points_cost * p_qty;
  select coalesce(sum(points), 0) into v_balance
    from public.points_ledger where beneficiary_id = p_beneficiary_id;
  if v_balance < v_cost then raise exception 'insufficient points'; end if;

  update public.rewards set stock = stock - p_qty where id = p_reward_id;

  insert into public.redemptions (beneficiary_id, reward_id, qty, points_spent, collector_id, idempotency_key)
  values (p_beneficiary_id, p_reward_id, p_qty, v_cost, v_actor, p_idempotency_key)
  returning * into v_redemption;

  insert into public.points_ledger (beneficiary_id, type, points, ref_id, actor_id)
  values (p_beneficiary_id, 'redeem', -v_cost, v_redemption.id, v_actor);

  return jsonb_build_object(
    'redemption_id', v_redemption.id,
    'beneficiary_id', p_beneficiary_id,
    'points', -v_cost,
    'balance', v_balance - v_cost,
    'duplicate', false
  );
end $$;

-- ---------------------------------------------------------------------------
-- RPC: admin adjustment
-- ---------------------------------------------------------------------------
create or replace function public.adjust_points(
  p_beneficiary_id uuid,
  p_points integer,
  p_reason text
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_balance bigint;
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if p_points is null or p_points = 0 then raise exception 'adjustment cannot be zero'; end if;
  if p_reason is null or length(trim(p_reason)) < 5 then
    raise exception 'a reason of at least 5 characters is required';
  end if;

  perform pg_advisory_xact_lock(hashtext(p_beneficiary_id::text));

  insert into public.points_ledger (beneficiary_id, type, points, note, actor_id)
  values (p_beneficiary_id, 'adjust', p_points, p_reason, auth.uid());

  select coalesce(sum(points), 0) into v_balance
    from public.points_ledger where beneficiary_id = p_beneficiary_id;

  return jsonb_build_object('beneficiary_id', p_beneficiary_id, 'points', p_points, 'balance', v_balance);
end $$;

-- ---------------------------------------------------------------------------
-- RPC: void a collection or redemption (admin only)
-- ---------------------------------------------------------------------------
create or replace function public.void_transaction(
  p_kind text,
  p_id uuid,
  p_reason text
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_points integer;
  v_beneficiary uuid;
  v_already boolean;
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if p_reason is null or length(trim(p_reason)) < 5 then
    raise exception 'a reason of at least 5 characters is required';
  end if;

  if p_kind = 'collection' then
    select voided, beneficiary_id into v_already, v_beneficiary
      from public.collections where id = p_id for update;
    if not found then raise exception 'collection not found'; end if;
    if v_already then raise exception 'already voided'; end if;
    select coalesce(sum(points), 0) into v_points
      from public.collection_items where collection_id = p_id;
    update public.collections set voided = true, voided_at = now() where id = p_id;
    v_points := -v_points;
  elsif p_kind = 'redemption' then
    select voided, beneficiary_id, points_spent into v_already, v_beneficiary, v_points
      from public.redemptions where id = p_id for update;
    if not found then raise exception 'redemption not found'; end if;
    if v_already then raise exception 'already voided'; end if;
    update public.redemptions set voided = true, voided_at = now() where id = p_id;
  else
    raise exception 'kind must be collection or redemption';
  end if;

  insert into public.points_ledger (beneficiary_id, type, points, ref_id, note, actor_id)
  values (v_beneficiary, 'void', v_points, p_id, p_reason, auth.uid());

  return jsonb_build_object('beneficiary_id', v_beneficiary, 'points', v_points);
end $$;

-- ---------------------------------------------------------------------------
-- Create a profile automatically for new auth users
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    coalesce((new.raw_user_meta_data->>'role')::public.user_role, 'collector')
  )
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table public.schools enable row level security;
alter table public.profiles enable row level security;
alter table public.beneficiaries enable row level security;
alter table public.materials enable row level security;
alter table public.collections enable row level security;
alter table public.collection_items enable row level security;
alter table public.rewards enable row level security;
alter table public.redemptions enable row level security;
alter table public.points_ledger enable row level security;

-- profiles
drop policy if exists profiles_self_read on public.profiles;
create policy profiles_self_read on public.profiles
  for select using (id = auth.uid() or public.is_admin());

drop policy if exists profiles_admin_write on public.profiles;
create policy profiles_admin_write on public.profiles
  for all using (public.is_admin()) with check (public.is_admin());

-- schools: staff read, admins write
drop policy if exists schools_read on public.schools;
create policy schools_read on public.schools
  for select using (public.is_staff());

drop policy if exists schools_admin_write on public.schools;
create policy schools_admin_write on public.schools
  for all using (public.is_admin()) with check (public.is_admin());

-- beneficiaries: staff read, admins write
drop policy if exists beneficiaries_read on public.beneficiaries;
create policy beneficiaries_read on public.beneficiaries
  for select using (public.is_staff());

drop policy if exists beneficiaries_admin_write on public.beneficiaries;
create policy beneficiaries_admin_write on public.beneficiaries
  for all using (public.is_admin()) with check (public.is_admin());

-- materials: staff read, admins write
drop policy if exists materials_read on public.materials;
create policy materials_read on public.materials
  for select using (public.is_staff());

drop policy if exists materials_admin_write on public.materials;
create policy materials_admin_write on public.materials
  for all using (public.is_admin()) with check (public.is_admin());

-- rewards: staff read, admins write (stock changes via RPC)
drop policy if exists rewards_read on public.rewards;
create policy rewards_read on public.rewards
  for select using (public.is_staff());

drop policy if exists rewards_admin_write on public.rewards;
create policy rewards_admin_write on public.rewards
  for all using (public.is_admin()) with check (public.is_admin());

-- collections / redemptions / ledger: read only; writes via RPC
drop policy if exists collections_read on public.collections;
create policy collections_read on public.collections
  for select using (public.is_admin() or collector_id = auth.uid());

drop policy if exists collection_items_read on public.collection_items;
create policy collection_items_read on public.collection_items
  for select using (
    public.is_admin() or exists (
      select 1 from public.collections c
      where c.id = collection_id and c.collector_id = auth.uid()
    )
  );

drop policy if exists redemptions_read on public.redemptions;
create policy redemptions_read on public.redemptions
  for select using (public.is_admin() or collector_id = auth.uid());

drop policy if exists ledger_read on public.points_ledger;
create policy ledger_read on public.points_ledger
  for select using (public.is_staff());

-- ---------------------------------------------------------------------------
-- Grants for RPCs
-- ---------------------------------------------------------------------------
revoke all on function public.record_collection(uuid, jsonb, text, text) from public;
revoke all on function public.redeem_reward(uuid, uuid, integer, text) from public;
revoke all on function public.adjust_points(uuid, integer, text) from public;
revoke all on function public.void_transaction(text, uuid, text) from public;

grant execute on function public.record_collection(uuid, jsonb, text, text) to authenticated;
grant execute on function public.redeem_reward(uuid, uuid, integer, text) to authenticated;
grant execute on function public.adjust_points(uuid, integer, text) to authenticated;
grant execute on function public.void_transaction(text, uuid, text) to authenticated;
