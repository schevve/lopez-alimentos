create table public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

insert into public.companies (name)
values ('Cesta Básica Lopes')
on conflict (name) do nothing;

alter table public.profiles
  add column company_id uuid references public.companies (id);

alter table public.customers
  add column company_id uuid references public.companies (id),
  add column score_category text not null default 'yellow'
    check (score_category in ('green', 'yellow', 'red')),
  add column is_authorized boolean not null default false,
  add column manual_block_override boolean;

alter table public.sales
  add column company_id uuid references public.companies (id);

alter table public.installments
  add column company_id uuid references public.companies (id);

alter table public.regions
  add column company_id uuid references public.companies (id);

alter table public.products
  add column company_id uuid references public.companies (id);

alter table public.baskets
  add column company_id uuid references public.companies (id);

alter table public.basket_products
  add column company_id uuid references public.companies (id);

alter table public.sale_baskets
  add column company_id uuid references public.companies (id);

update public.profiles
set company_id = (select id from public.companies where name = 'Cesta Básica Lopes')
where company_id is null;

update public.customers
set company_id = (select id from public.companies where name = 'Cesta Básica Lopes')
where company_id is null;

update public.customers
set manual_block_override = true
where is_blocked = true
  and manual_block_override is null;

update public.sales
set company_id = (select id from public.companies where name = 'Cesta Básica Lopes')
where company_id is null;

update public.installments
set company_id = (select id from public.companies where name = 'Cesta Básica Lopes')
where company_id is null;

update public.regions
set company_id = (select id from public.companies where name = 'Cesta Básica Lopes')
where company_id is null;

update public.products
set company_id = (select id from public.companies where name = 'Cesta Básica Lopes')
where company_id is null;

update public.baskets
set company_id = (select id from public.companies where name = 'Cesta Básica Lopes')
where company_id is null;

update public.basket_products
set company_id = (select id from public.companies where name = 'Cesta Básica Lopes')
where company_id is null;

update public.sale_baskets
set company_id = (select id from public.companies where name = 'Cesta Básica Lopes')
where company_id is null;

alter table public.profiles alter column company_id set not null;
alter table public.customers alter column company_id set not null;
alter table public.sales alter column company_id set not null;
alter table public.installments alter column company_id set not null;
alter table public.regions alter column company_id set not null;
alter table public.products alter column company_id set not null;
alter table public.baskets alter column company_id set not null;
alter table public.basket_products alter column company_id set not null;
alter table public.sale_baskets alter column company_id set not null;

create unique index profiles_id_company_id_key
  on public.profiles (id, company_id);
create unique index customers_id_company_id_key
  on public.customers (id, company_id);
create unique index sales_id_company_id_key
  on public.sales (id, company_id);
create unique index installments_id_company_id_key
  on public.installments (id, company_id);
create unique index regions_id_company_id_key
  on public.regions (id, company_id);
create unique index products_id_company_id_key
  on public.products (id, company_id);
create unique index baskets_id_company_id_key
  on public.baskets (id, company_id);

create index profiles_company_id_idx on public.profiles (company_id);
create index customers_company_id_idx on public.customers (company_id);
create index customers_user_id_company_id_idx
  on public.customers (user_id, company_id);
create index sales_company_id_idx on public.sales (company_id);
create index sales_user_id_company_id_idx
  on public.sales (user_id, company_id);
create index installments_company_id_idx on public.installments (company_id);
create index regions_company_id_idx on public.regions (company_id);
create index products_company_id_idx on public.products (company_id);
create index baskets_company_id_idx on public.baskets (company_id);
create index basket_products_company_id_idx
  on public.basket_products (company_id);
create index sale_baskets_company_id_idx
  on public.sale_baskets (company_id);

alter table public.customers
  add constraint customers_user_company_fkey
  foreign key (user_id, company_id)
  references public.profiles (id, company_id)
  not valid;

alter table public.customers
  add constraint customers_region_company_fkey
  foreign key (region_id, company_id)
  references public.regions (id, company_id)
  not valid;

alter table public.sales
  add constraint sales_user_company_fkey
  foreign key (user_id, company_id)
  references public.profiles (id, company_id)
  not valid;

alter table public.sales
  add constraint sales_customer_company_fkey
  foreign key (customer_id, company_id)
  references public.customers (id, company_id)
  not valid;

alter table public.installments
  add constraint installments_sale_company_fkey
  foreign key (sale_id, company_id)
  references public.sales (id, company_id)
  not valid;

alter table public.basket_products
  add constraint basket_products_basket_company_fkey
  foreign key (basket_id, company_id)
  references public.baskets (id, company_id)
  not valid;

alter table public.basket_products
  add constraint basket_products_product_company_fkey
  foreign key (product_id, company_id)
  references public.products (id, company_id)
  not valid;

alter table public.sale_baskets
  add constraint sale_baskets_sale_company_fkey
  foreign key (sale_id, company_id)
  references public.sales (id, company_id)
  not valid;

alter table public.sale_baskets
  add constraint sale_baskets_basket_company_fkey
  foreign key (basket_id, company_id)
  references public.baskets (id, company_id)
  not valid;

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id),
  installment_id uuid not null,
  amount double precision not null check (amount > 0),
  paid_at timestamptz not null default now(),
  received_by uuid,
  created_at timestamptz not null default now()
);

alter table public.payments
  add constraint payments_installment_company_fkey
  foreign key (installment_id, company_id)
  references public.installments (id, company_id)
  not valid;

alter table public.payments
  add constraint payments_receiver_company_fkey
  foreign key (received_by, company_id)
  references public.profiles (id, company_id)
  not valid;

create index payments_company_id_idx on public.payments (company_id);
create index payments_installment_company_id_idx
  on public.payments (installment_id, company_id);

alter table public.companies enable row level security;
alter table public.profiles enable row level security;
alter table public.customers enable row level security;
alter table public.sales enable row level security;
alter table public.installments enable row level security;
alter table public.regions enable row level security;
alter table public.products enable row level security;
alter table public.baskets enable row level security;
alter table public.basket_products enable row level security;
alter table public.sale_baskets enable row level security;
alter table public.payments enable row level security;

drop policy if exists "authenticated users can crud customers"
  on public.customers;

create or replace function public.current_company_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select p.company_id
  from public.profiles as p
  where p.id = (select auth.uid())
  limit 1
$$;

create or replace function public.current_app_role()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select p.role::text
  from public.profiles as p
  where p.id = (select auth.uid())
  limit 1
$$;

revoke all on function public.current_company_id() from public, anon;
revoke all on function public.current_app_role() from public, anon;
grant execute on function public.current_company_id() to authenticated;
grant execute on function public.current_app_role() to authenticated;

create or replace function public.customer_is_blocked(
  p_customer_id uuid,
  p_company_id uuid
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  blocked boolean;
begin
  if (select auth.uid()) is null
      or p_company_id is distinct from public.current_company_id() then
    return true;
  end if;

  select case
    when c.manual_block_override is not null then c.manual_block_override
    when c.is_authorized then false
    else c.is_blocked or (
      select count(*) >= 4
      from public.installments as i
      join public.sales as s
        on s.id = i.sale_id
       and s.company_id = i.company_id
      left join lateral (
        select coalesce(sum(p.amount), 0) as paid
        from public.payments as p
        where p.installment_id = i.id
          and p.company_id = i.company_id
      ) as totals on true
      where s.customer_id = c.id
        and s.company_id = c.company_id
        and i.amount > totals.paid
    )
  end
  into blocked
  from public.customers as c
  where c.id = p_customer_id
    and c.company_id = p_company_id;

  return coalesce(blocked, true);
end;
$$;

revoke all on function public.customer_is_blocked(uuid, uuid)
  from public, anon;
grant execute on function public.customer_is_blocked(uuid, uuid)
  to authenticated;

create or replace function public.guard_customer_manager_fields()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (select auth.uid()) is not null
      and public.current_app_role() is distinct from 'ADMIN' then
    if tg_op = 'INSERT' then
      if new.is_blocked
          or new.is_authorized
          or new.manual_block_override is not null
          or new.score is not null
          or new.score_category <> 'yellow' then
        raise exception 'Somente ADMIN pode definir bloqueio, autorização ou score.'
          using errcode = '42501';
      end if;
    elsif
      old.is_blocked is distinct from new.is_blocked
      or old.is_authorized is distinct from new.is_authorized
      or old.manual_block_override is distinct from new.manual_block_override
      or old.score is distinct from new.score
      or old.score_category is distinct from new.score_category then
      raise exception 'Somente ADMIN pode alterar bloqueio, autorização ou score.'
        using errcode = '42501';
    end if;
  end if;

  return new;
end;
$$;

create trigger customers_guard_manager_fields
before insert or update on public.customers
for each row execute function public.guard_customer_manager_fields();

create policy companies_select_member
  on public.companies
  for select
  to authenticated
  using (
    id = (select public.current_company_id())
    and (select public.current_app_role()) in ('ADMIN', 'SELLER')
  );

create policy profiles_select_same_company
  on public.profiles
  for select
  to authenticated
  using (
    company_id = (select public.current_company_id())
    and (
      id = (select auth.uid())
      or (select public.current_app_role()) = 'ADMIN'
    )
  );

create policy customers_select_wallet
  on public.customers
  for select
  to authenticated
  using (
    company_id = (select public.current_company_id())
    and (
      (select public.current_app_role()) = 'ADMIN'
      or (
        (select public.current_app_role()) = 'SELLER'
        and user_id = (select auth.uid())
      )
    )
  );

create policy customers_insert_wallet
  on public.customers
  for insert
  to authenticated
  with check (
    company_id = (select public.current_company_id())
    and (
      (select public.current_app_role()) = 'ADMIN'
      or (
        (select public.current_app_role()) = 'SELLER'
        and user_id = (select auth.uid())
      )
    )
  );

create policy customers_update_wallet
  on public.customers
  for update
  to authenticated
  using (
    company_id = (select public.current_company_id())
    and (
      (select public.current_app_role()) = 'ADMIN'
      or (
        (select public.current_app_role()) = 'SELLER'
        and user_id = (select auth.uid())
      )
    )
  )
  with check (
    company_id = (select public.current_company_id())
    and (
      (select public.current_app_role()) = 'ADMIN'
      or (
        (select public.current_app_role()) = 'SELLER'
        and user_id = (select auth.uid())
      )
    )
  );

create policy sales_select_wallet
  on public.sales
  for select
  to authenticated
  using (
    company_id = (select public.current_company_id())
    and (
      (select public.current_app_role()) = 'ADMIN'
      or (
        (select public.current_app_role()) = 'SELLER'
        and user_id = (select auth.uid())
      )
    )
  );

create policy sales_insert_unblocked_wallet
  on public.sales
  for insert
  to authenticated
  with check (
    company_id = (select public.current_company_id())
    and (
      (select public.current_app_role()) = 'ADMIN'
      or (
        (select public.current_app_role()) = 'SELLER'
        and user_id = (select auth.uid())
      )
    )
    and exists (
      select 1
      from public.customers as c
      where c.id = customer_id
        and c.company_id = sales.company_id
        and not public.customer_is_blocked(c.id, c.company_id)
        and (
          (select public.current_app_role()) = 'ADMIN'
          or c.user_id = (select auth.uid())
        )
    )
  );

create policy sales_update_wallet
  on public.sales
  for update
  to authenticated
  using (
    company_id = (select public.current_company_id())
    and (
      (select public.current_app_role()) = 'ADMIN'
      or (
        (select public.current_app_role()) = 'SELLER'
        and user_id = (select auth.uid())
      )
    )
  )
  with check (
    company_id = (select public.current_company_id())
    and (
      (select public.current_app_role()) = 'ADMIN'
      or (
        (select public.current_app_role()) = 'SELLER'
        and user_id = (select auth.uid())
      )
    )
    and exists (
      select 1
      from public.customers as c
      where c.id = customer_id
        and c.company_id = sales.company_id
        and not public.customer_is_blocked(c.id, c.company_id)
        and (
          (select public.current_app_role()) = 'ADMIN'
          or c.user_id = (select auth.uid())
        )
    )
  );

create policy installments_select_wallet
  on public.installments
  for select
  to authenticated
  using (
    company_id = (select public.current_company_id())
    and exists (
      select 1
      from public.sales as s
      where s.id = sale_id
        and s.company_id = installments.company_id
        and (
          (select public.current_app_role()) = 'ADMIN'
          or (
            (select public.current_app_role()) = 'SELLER'
            and s.user_id = (select auth.uid())
          )
        )
    )
  );

create policy installments_insert_wallet
  on public.installments
  for insert
  to authenticated
  with check (
    company_id = (select public.current_company_id())
    and exists (
      select 1
      from public.sales as s
      where s.id = sale_id
        and s.company_id = installments.company_id
        and (
          (select public.current_app_role()) = 'ADMIN'
          or (
            (select public.current_app_role()) = 'SELLER'
            and s.user_id = (select auth.uid())
          )
        )
    )
  );

create policy payments_select_wallet
  on public.payments
  for select
  to authenticated
  using (
    company_id = (select public.current_company_id())
    and exists (
      select 1
      from public.installments as i
      join public.sales as s
        on s.id = i.sale_id
       and s.company_id = i.company_id
      where i.id = installment_id
        and i.company_id = payments.company_id
        and (
          (select public.current_app_role()) = 'ADMIN'
          or (
            (select public.current_app_role()) = 'SELLER'
            and s.user_id = (select auth.uid())
          )
        )
    )
  );

create policy payments_insert_wallet
  on public.payments
  for insert
  to authenticated
  with check (
    company_id = (select public.current_company_id())
    and (
      (select public.current_app_role()) = 'ADMIN'
      or (
        (select public.current_app_role()) = 'SELLER'
        and received_by = (select auth.uid())
      )
    )
    and exists (
      select 1
      from public.installments as i
      join public.sales as s
        on s.id = i.sale_id
       and s.company_id = i.company_id
      where i.id = installment_id
        and i.company_id = payments.company_id
        and (
          (select public.current_app_role()) = 'ADMIN'
          or s.user_id = (select auth.uid())
        )
    )
  );

create policy regions_select_company
  on public.regions
  for select
  to authenticated
  using (
    company_id = (select public.current_company_id())
    and (select public.current_app_role()) in ('ADMIN', 'SELLER')
  );

create policy products_select_company
  on public.products
  for select
  to authenticated
  using (
    company_id = (select public.current_company_id())
    and (select public.current_app_role()) in ('ADMIN', 'SELLER')
  );

create policy baskets_select_company
  on public.baskets
  for select
  to authenticated
  using (
    company_id = (select public.current_company_id())
    and (select public.current_app_role()) in ('ADMIN', 'SELLER')
  );

create policy basket_products_select_company
  on public.basket_products
  for select
  to authenticated
  using (
    company_id = (select public.current_company_id())
    and (select public.current_app_role()) in ('ADMIN', 'SELLER')
  );

create policy sale_baskets_select_wallet
  on public.sale_baskets
  for select
  to authenticated
  using (
    company_id = (select public.current_company_id())
    and exists (
      select 1
      from public.sales as s
      where s.id = sale_id
        and s.company_id = sale_baskets.company_id
        and (
          (select public.current_app_role()) = 'ADMIN'
          or (
            (select public.current_app_role()) = 'SELLER'
            and s.user_id = (select auth.uid())
          )
        )
    )
  );

create policy sale_baskets_insert_wallet
  on public.sale_baskets
  for insert
  to authenticated
  with check (
    company_id = (select public.current_company_id())
    and exists (
      select 1
      from public.sales as s
      where s.id = sale_id
        and s.company_id = sale_baskets.company_id
        and (
          (select public.current_app_role()) = 'ADMIN'
          or (
            (select public.current_app_role()) = 'SELLER'
            and s.user_id = (select auth.uid())
          )
        )
    )
  );
