-- Trade completion is a separate two-person acknowledgement.
-- This migration NEVER changes collection_cards.
alter table public.trade_proposals
 add column if not exists sender_completed boolean not null default false,
 add column if not exists recipient_completed boolean not null default false,
 add column if not exists completed_at timestamptz;
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
 raise exception 'Trade contents cannot be changed';
 end if;
 if old.status='pending' then
   if new.sender_completed<>old.sender_completed or new.recipient_completed<>old.recipient_completed
     or new.completed_at is distinct from old.completed_at or
     not ((auth.uid()=old.recipient_id and new.status in ('accepted','declined'))
       or (auth.uid()=old.sender_id and new.status='cancelled')) then
     raise exception 'Invalid proposal transition';
   end if;
 elsif old.status='accepted' then
   if new.status<>old.status or old.completed_at is not null then
     raise exception 'Completed trade cannot change';
   end if;
   if auth.uid()=old.sender_id then
     if new.recipient_completed<>old.recipient_completed or
       (old.sender_completed and not new.sender_completed) then
       raise exception 'Cannot change other trainer confirmation';
     end if;
   elsif auth.uid()=old.recipient_id then
     if new.sender_completed<>old.sender_completed or
       (old.recipient_completed and not new.recipient_completed) then
       raise exception 'Cannot change other trainer confirmation';
     end if;
   else raise exception 'Not a participant';
   end if;
   if new.sender_completed and new.recipient_completed then
     new.completed_at=now();
   elsif new.completed_at is distinct from old.completed_at then
     raise exception 'Completion requires both trainers';
   end if;
 else
   raise exception 'Trade status is final';
 end if;
 new.updated_at=now();
 return new;
end; $$;
