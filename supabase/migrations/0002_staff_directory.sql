-- ReLearn 0002: staff directory, hardened signup role, reward restock.
-- Applied after 0001_init.sql.

-- Never trust client-supplied metadata for authorisation. Self-signup always
-- creates a collector; an admin promotes staff explicitly.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    'collector'
  )
  on conflict (id) do nothing;
  return new;
end $$;

-- Admins see every staff member; a collector sees only themselves. The view
-- runs as its owner, so the filter below is the security boundary.
create or replace view public.staff_directory as
select p.id,
       p.name,
       p.role,
       p.active,
       u.email,
       u.last_sign_in_at
from public.profiles p
join auth.users u on u.id = p.id
where public.is_admin() or p.id = auth.uid();

revoke all on public.staff_directory from anon;
grant select on public.staff_directory to authenticated;

-- Atomic restock so two admins cannot overwrite each other's counts.
create or replace function public.restock_reward(p_reward_id uuid, p_qty integer)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_stock integer;
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if p_qty is null or p_qty <= 0 then raise exception 'quantity must be positive'; end if;

  update public.rewards set stock = stock + p_qty
  where id = p_reward_id
  returning stock into v_stock;

  if not found then raise exception 'reward not found'; end if;
  return jsonb_build_object('reward_id', p_reward_id, 'stock', v_stock);
end $$;

revoke all on function public.restock_reward(uuid, integer) from public;
grant execute on function public.restock_reward(uuid, integer) to authenticated;
