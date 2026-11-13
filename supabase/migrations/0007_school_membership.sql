-- ReLearn 0007: portable ID generation, teacher role, school membership and
-- school-scoped history.
--
-- Fixes: public.next_public_id() used gen_random_bytes(), which is not
-- available on every Postgres/Supabase project. Use the core gen_random_uuid()
-- instead so inserting a beneficiary always works.

-- ---------------------------------------------------------------------------
-- 1. Portable public IDs
-- ---------------------------------------------------------------------------
create or replace function public.next_public_id()
returns text language plpgsql security definer set search_path = public as $$
declare
  alphabet text := public.id_alphabet();
  n bigint := nextval('public.beneficiary_seq');
  body text;
  rnd text := '';
  v_bytes bytea := uuid_send(gen_random_uuid());
  i int;
begin
  for i in 0..2 loop
    rnd := rnd || substr(alphabet, 1 + (get_byte(v_bytes, i) % length(alphabet)), 1);
  end loop;
  body := lpad(n::text, 4, '0') || '-' || rnd;
  return 'RL-' || body || public.check_char(body);
end $$;

-- ---------------------------------------------------------------------------
-- 2. Teacher role and school membership
-- ---------------------------------------------------------------------------
alter type public.user_role add value if not exists 'teacher';

alter table public.profiles
  add column if not exists school_id uuid references public.schools (id);

create index if not exists profiles_school_idx on public.profiles (school_id);

-- Active admins and collectors may record points; teachers are read-only.
create or replace function public.is_collector()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and active and role in ('admin', 'collector')
  );
$$;

create or replace function public.my_school_id()
returns uuid language sql stable security definer set search_path = public as $$
  select school_id from public.profiles where id = auth.uid();
$$;

grant execute on function public.is_collector() to authenticated;
grant execute on function public.my_school_id() to authenticated;

-- A new user may link themselves to an active school during onboarding. Once
-- set, only an admin can move them.
create or replace function public.update_my_school(p_school_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_current uuid;
  v_role public.user_role;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  select school_id, role into v_current, v_role
    from public.profiles where id = auth.uid();

  if v_role = 'admin' then
    raise exception 'admins are not restricted to a school';
  end if;
  if v_current is not null and v_current <> p_school_id then
    raise exception 'school already set; ask an admin to change it';
  end if;
  if not exists (
    select 1 from public.schools where id = p_school_id and active
  ) then
    raise exception 'school not found or inactive';
  end if;

  update public.profiles set school_id = p_school_id where id = auth.uid();
end $$;

revoke all on function public.update_my_school(uuid) from public;
grant execute on function public.update_my_school(uuid) to authenticated;

-- Staff directory now carries the school, for apps and admin screens.
drop view if exists public.staff_directory;
create view public.staff_directory as
select p.id,
       p.name,
       p.role,
       p.active,
       p.school_id,
       s.name as school_name,
       u.email,
       u.last_sign_in_at
from public.profiles p
join auth.users u on u.id = p.id
left join public.schools s on s.id = p.school_id
where public.is_admin() or p.id = auth.uid();

revoke all on public.staff_directory from anon;
grant select on public.staff_directory to authenticated;

-- ---------------------------------------------------------------------------
-- 3. School-scoped history
-- ---------------------------------------------------------------------------
-- Staff can read beneficiaries in their own school; admins still see all.
drop policy if exists beneficiaries_read on public.beneficiaries;
create policy beneficiaries_read on public.beneficiaries
  for select using (
    public.is_admin()
    or (public.my_school_id() is not null and school_id = public.my_school_id())
  );

-- Collections and redemptions are visible to the collector who recorded them
-- and to every staff member attached to the same school.
drop policy if exists collections_read on public.collections;
create policy collections_read on public.collections
  for select using (
    public.is_admin()
    or collector_id = auth.uid()
    or (
      public.my_school_id() is not null
      and school_id = public.my_school_id()
    )
  );

drop policy if exists collection_items_read on public.collection_items;
create policy collection_items_read on public.collection_items
  for select using (
    public.is_admin()
    or exists (
      select 1 from public.collections c
      where c.id = collection_id
        and (
          c.collector_id = auth.uid()
          or (
            public.my_school_id() is not null
            and c.school_id = public.my_school_id()
          )
        )
    )
  );

drop policy if exists redemptions_read on public.redemptions;
create policy redemptions_read on public.redemptions
  for select using (
    public.is_admin()
    or collector_id = auth.uid()
    or (
      public.my_school_id() is not null
      and exists (
        select 1 from public.beneficiaries b
        where b.id = beneficiary_id
          and b.school_id = public.my_school_id()
      )
    )
  );

-- The ledger is school-scoped too: reconciliation needs the full picture.
drop policy if exists ledger_read on public.points_ledger;
create policy ledger_read on public.points_ledger
  for select using (
    public.is_admin()
    or (
      public.my_school_id() is not null
      and exists (
        select 1 from public.beneficiaries b
        where b.id = beneficiary_id
          and b.school_id = public.my_school_id()
      )
    )
  );

-- ---------------------------------------------------------------------------
-- 4. Teachers are read-only, and collectors stay inside their school
-- ---------------------------------------------------------------------------
-- The original RPCs checked is_staff(), which would let a teacher write. They
-- now require is_collector() and, for non-admins, a beneficiary in the caller's
-- own school. The RPCs are security definer, so RLS alone cannot enforce this.
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
  if not public.is_collector() then
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
  if not public.is_admin()
     and v_beneficiary.school_id <> public.my_school_id() then
    raise exception 'beneficiary is outside your school';
  end if;
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
  if not public.is_collector() then raise exception 'not authorised'; end if;
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
  if not public.is_admin()
     and v_beneficiary.school_id <> public.my_school_id() then
    raise exception 'beneficiary is outside your school';
  end if;
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

revoke all on function public.record_collection(uuid, jsonb, text, text) from public;
revoke all on function public.redeem_reward(uuid, uuid, integer, text) from public;
grant execute on function public.record_collection(uuid, jsonb, text, text) to authenticated;
grant execute on function public.redeem_reward(uuid, uuid, integer, text) to authenticated;
