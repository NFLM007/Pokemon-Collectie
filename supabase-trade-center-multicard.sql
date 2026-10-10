-- Trade Center 2.1: multiple cards per proposal.
alter table public.trade_proposals
 add column if not exists offered_cards jsonb,
 add column if not exists requested_cards jsonb;
-- Each item: {set_id,card_number,variant,quantity}
create or replace function public.trade_cards_valid(items jsonb)
returns boolean language sql immutable as $$
 select items is not null and jsonb_typeof(items)='array'
 and jsonb_array_length(items) between 1 and 20
 and not exists(
  select 1 from jsonb_array_elements(items) item
  where jsonb_typeof(item)<>'object'
   or jsonb_typeof(item->'set_id')<>'string'
   or jsonb_typeof(item->'card_number')<>'string'
   or jsonb_typeof(item->'variant')<>'string'
   or length(item->>'set_id') not between 1 and 150
   or length(item->>'card_number') not between 1 and 30
   or length(item->>'variant') not between 1 and 60
   or jsonb_typeof(item->'quantity')<>'number'
   or (item->>'quantity') !~ '^[1-9][0-9]{0,2}$'
   or (item->>'quantity')::int>999
 );
$$;
alter table public.trade_proposals drop constraint if exists trade_cards_shape;
alter table public.trade_proposals add constraint trade_cards_shape check (
 (offered_cards is null and requested_cards is null)
 or (public.trade_cards_valid(offered_cards) and public.trade_cards_valid(requested_cards))
);
create or replace function public.trade_proposal_guard()
returns trigger language plpgsql set search_path=public as $$
begin
 if new.id<>old.id or new.sender_id<>old.sender_id or new.recipient_id<>old.recipient_id
 or new.offered_set_id<>old.offered_set_id or new.offered_card_number<>old.offered_card_number
 or new.offered_variant<>old.offered_variant or new.requested_set_id<>old.requested_set_id
 or new.requested_card_number<>old.requested_card_number or new.requested_variant<>old.requested_variant
 or new.offered_cards is distinct from old.offered_cards
 or new.requested_cards is distinct from old.requested_cards
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
