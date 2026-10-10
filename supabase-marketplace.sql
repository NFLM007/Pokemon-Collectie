-- Run once in Supabase SQL Editor.
create table if not exists public.market_listings (
 id uuid primary key default gen_random_uuid(),
 seller_id uuid not null references auth.users(id) on delete cascade,
 title text not null check (char_length(title) between 3 and 100),
 description text not null default '' check (char_length(description)<=1000),
 mode text not null check(mode in ('sale','trade','both')),
 price numeric(9,2) check(price>=0 and price<=999999),
 condition text not null default 'Niet opgegeven',
 status text not null default 'active' check(status in ('active','closed')),
 created_at timestamptz not null default now()
);
create index if not exists market_listings_active_idx on public.market_listings(status,created_at desc);
alter table public.market_listings enable row level security;
drop policy if exists "market_read_authenticated" on public.market_listings;
create policy "market_read_authenticated" on public.market_listings for select to authenticated using (true);
drop policy if exists "market_insert_own" on public.market_listings;
create policy "market_insert_own" on public.market_listings for insert to authenticated with check(seller_id=auth.uid());
drop policy if exists "market_update_own" on public.market_listings;
create policy "market_update_own" on public.market_listings for update to authenticated using(seller_id=auth.uid()) with check(seller_id=auth.uid());
drop policy if exists "market_delete_own" on public.market_listings;
create policy "market_delete_own" on public.market_listings for delete to authenticated using(seller_id=auth.uid());
