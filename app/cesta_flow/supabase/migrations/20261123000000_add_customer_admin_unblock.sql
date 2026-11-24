alter table public.customers
  add column is_admin_unblocked boolean not null default false;

create function public.enforce_customer_admin_unblock()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if not new.is_admin_unblocked then
      return new;
    end if;
  elsif new.is_admin_unblocked is not distinct from old.is_admin_unblocked then
    return new;
  end if;

  if not exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and deleted_at is null
      and upper(role::text) = 'ADMIN'
  ) then
    raise exception 'Apenas administradores podem alterar a liberação.'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

revoke execute on function public.enforce_customer_admin_unblock()
  from public, anon, authenticated;

-- AFTER INSERT evita tratar um upsert que atualiza uma linha como cadastro.
create trigger enforce_customer_admin_unblock
  after insert or update on public.customers
  for each row execute function public.enforce_customer_admin_unblock();
