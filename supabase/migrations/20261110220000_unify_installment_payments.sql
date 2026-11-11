alter table public.installments
  add column paid_amount double precision not null default 0,
  add column paid_at timestamptz,
  add column payment_method text;
