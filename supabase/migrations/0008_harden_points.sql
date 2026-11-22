-- ReLearn 0008: harden point awarding.
--
-- The app reads the derived `beneficiary_balances` view on every refresh, so
-- make its grant explicit instead of relying on default privileges.
--
-- `record_collection` now serialises per beneficiary, rejects a collection that
-- would post a zero-point ledger row (the ledger has a points <> 0 check), and
-- writes the material summary into the ledger note so history is readable.

grant select on public.beneficiary_balances to authenticated;

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
  v_summary text := '';
  v_existing public.collections%rowtype;
  v_balance bigint;
begin
  if not public.is_collector() then
    raise exception 'not authorised';
  end if;
  if p_idempotency_key is null or length(p_idempotency_key) < 8 then
    raise exception 'idempotency key required';
  end if;

  select * into v_existing from public.collections
    where idempotency_key = p_idempotency_key;
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

  -- Serialise collections per beneficiary so concurrent devices cannot race.
  perform pg_advisory_xact_lock(hashtext(p_beneficiary_id::text));

  select * into v_beneficiary from public.beneficiaries
    where id = p_beneficiary_id for share;
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
    select * into v_material from public.materials
      where id = (v_item->>'material_id')::uuid;
    if not found then raise exception 'material not found'; end if;
    if not v_material.allowed then raise exception 'material % is not accepted', v_material.name; end if;
    if not v_material.active then raise exception 'material % is inactive', v_material.name; end if;

    v_qty := (v_item->>'quantity')::numeric;
    if v_qty is null or v_qty <= 0 then raise exception 'quantity must be greater than zero'; end if;

    v_points := round(v_qty * v_material.points_per_unit)::integer;
    insert into public.collection_items (collection_id, material_id, quantity, rate_snapshot, points)
    values (v_collection_id, v_material.id, v_qty, v_material.points_per_unit, v_points);
    v_total := v_total + v_points;

    v_summary := v_summary
      || case when v_summary = '' then '' else ' + ' end
      || v_material.name || ' · ' || v_qty::text || ' '
      || case when v_material.unit::text = 'kg' then 'kg' else 'pcs' end;
  end loop;

  if v_total <= 0 then
    raise exception 'this collection is worth 0 points; set a rate above zero for the selected material';
  end if;

  insert into public.points_ledger (beneficiary_id, type, points, ref_id, note, actor_id)
  values (
    p_beneficiary_id,
    'earn',
    v_total,
    v_collection_id,
    coalesce(nullif(trim(p_note), ''), v_summary),
    v_actor
  );

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

revoke all on function public.record_collection(uuid, jsonb, text, text) from public;
grant execute on function public.record_collection(uuid, jsonb, text, text) to authenticated;
