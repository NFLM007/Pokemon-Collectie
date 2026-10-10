-- NFLM Trade Center v1: proposals only; no automatic collection transfer.
create table if not exists public.trade_proposals (
 id uuid primary key default gen_random_uuid(),
 sender_id uuid not null references auth.users(id) on delete cascade,
 recipient_id uuid not null references auth.users(id) on delete cascade,
 offered_set_id text not null,
 offered_card_number text not null,
 offered_variant text not null,
 requested_set_id text not null,
 requested_card_number text not null,
 requested_variant text not null,
 note text not null default '' check(char_length(note)<=500),
 status text not null default 'pending' check(status in ('pending','accepted','declined','cancelled')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 constraint trade_not_self check(sender_id<>recipient_id)
);
create index if not exists trade_proposals_sender_idx on public.trade_proposals(sender_id,created_at desc);
create index if not exists trade_proposals_recipient_idx on public.trade_proposals(recipient_id,created_at desc);
alter table public.trade_proposals enable row level security;
drop policy if exists trade_proposals_read on public.trade_proposals;
create policy trade_proposals_read on public.trade_proposals for select to authenticated
 using(auth.uid()=sender_id or auth.uid()=recipient_id);
drop policy if exists trade_proposals_insert on public.trade_proposals;
create policy trade_proposals_insert on public.trade_proposals for insert to authenticated
 with check(sender_id=auth.uid() and status='pending'
 and exists(select 1 from public.friendships f where f.status='accepted' and
 ((f.requester_id=sender_id and f.addressee_id=recipient_id) or
 (f.requester_id=recipient_id and f.addressee_id=sender_id))));
drop policy if exists trade_proposals_update on public.trade_proposals;
-- Status transitions are enforced in a trigger; participants cannot alter card fields.
create or replace function public.trade_proposal_guard()
returns trigger language plpgsql set search_path=public as $$
begin
 if new.id<>old.id or new.sender_id<>old.sender_id or new.recipient_id<>old.recipient_id
 or new.offered_set_id<>old.offered_set_id or new.offered_card_number<>old.offered_card_number
 or new.offered_variant<>old.offered_variant or new.requested_set_id<>old.requested_set_id
 or new.requested_card_number<>old.requested_card_number or new.requested_variant<>old.requested_variant
 or new.note<>old.note or new.created_at<>old.created_at then
 raise exception 'Only proposal status can be changed';
 end if;
 if old.status<>'pending' or
 not ((auth.uid()=old.recipient_id and new.status in ('accepted','declined'))
 or (auth.uid()=old.sender_id and new.status='cancelled')) then
 raise exception 'Invalid trade status transition';
 end if;
 new.updated_at=now();
 return new;
end; $$;
drop trigger if exists trade_proposal_guard_trigger on public.trade_proposals;
create trigger trade_proposal_guard_trigger before update on public.trade_proposals
 for each row execute function public.trade_proposal_guard();
create policy trade_proposals_update on public.trade_proposals for update to authenticated
 using(auth.uid()=sender_id or auth.uid()=recipient_id)
 with check(auth.uid()=sender_id or auth.uid()=recipient_id);
