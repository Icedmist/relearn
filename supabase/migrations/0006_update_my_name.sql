-- ReLearn 0006: let a signed-in staff member rename their own account.
-- RLS on public.profiles only allows admins to update rows, so this
-- security-definer function exposes the name column without allowing a
-- collector to change their own role or active flag.

create or replace function public.update_my_name(p_name text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text := trim(p_name);
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  if length(v_name) < 2 then
    raise exception 'name is too short';
  end if;
  if length(v_name) > 80 then
    raise exception 'name is too long';
  end if;
  update public.profiles set name = v_name where id = auth.uid();
end;
$$;

revoke all on function public.update_my_name(text) from public;
grant execute on function public.update_my_name(text) to authenticated;
