-- Trade Center 2.3: atomic transfer ONLY after BOTH trainers confirm.
-- Run after supabase-trade-completion.sql.
-- Collection rows are never changed when merely accepting a proposal.
create or replace function public.trade_apply_completed()
returns trigger language plpgsql security definer set search_path=public as $$
declare
 item jsonb;
 uid uuid;
 row_set text;
 row_number text;
 row_variant text;
 amount int;
 available int;
 side text;
 items jsonb;
begin
 if new.completed_at is null or old.completed_at is not null then return new; end if;
 if not new.sender_completed or not new.recipient_completed or new.status <> 'accepted' then
   raise exception 'Both trainers must confirm first';
 end if;
 -- Serialize all transfers affecting either user to prevent overlapping trades.
 if new.sender_id::text < new.recipient_id::text then
   perform pg_advisory_xact_lock(hashtextextended(new.sender_id::text, 90421));
   perform pg_advisory_xact_lock(hashtextextended(new.recipient_id::text, 90421));
 else
   perform pg_advisory_xact_lock(hashtextextended(new.recipient_id::text, 90421));
   perform pg_advisory_xact_lock(hashtextextended(new.sender_id::text, 90421));
 end if;
 -- Validate and debit both sides before crediting either side.
 for side in select unnest(array['offered','requested']) loop
   uid := case when side='offered' then new.sender_id else new.recipient_id end;
   items := case when side='offered' then
      coalesce(new.offered_cards,jsonb_build_array(jsonb_build_object('set_id',new.offered_set_id,'card_number',new.offered_card_number,'variant',new.offered_variant,'quantity',1)))
    else coalesce(new.requested_cards,jsonb_build_array(jsonb_build_object('set_id',new.requested_set_id,'card_number',new.requested_card_number,'variant',new.requested_variant,'quantity',1))) end;
   for row_set,row_number,row_variant,amount in
     select v->>'set_id',v->>'card_number',v->>'variant',sum((v->>'quantity')::int)::int
     from jsonb_array_elements(items) v
     group by 1,2,3
   loop
     select quantity into available from public.collection_cards
     where user_id=uid and set_id=row_set and card_number=row_number and variant=row_variant
     for update;
     if coalesce(available,0)<amount then
       raise exception 'Not enough copies of card % / % / % for trainer %',row_set,row_number,row_variant,uid;
     end if;
     update public.collection_cards set quantity=quantity-amount,updated_at=now()
       where user_id=uid and set_id=row_set and card_number=row_number and variant=row_variant;
   end loop;
 end loop;
 -- Credit cards to the other trainer.
 for side in select unnest(array['offered','requested']) loop
   uid := case when side='offered' then new.recipient_id else new.sender_id end;
   items := case when side='offered' then
      coalesce(new.offered_cards,jsonb_build_array(jsonb_build_object('set_id',new.offered_set_id,'card_number',new.offered_card_number,'variant',new.offered_variant,'quantity',1)))
    else coalesce(new.requested_cards,jsonb_build_array(jsonb_build_object('set_id',new.requested_set_id,'card_number',new.requested_card_number,'variant',new.requested_variant,'quantity',1))) end;
   for row_set,row_number,row_variant,amount in
     select v->>'set_id',v->>'card_number',v->>'variant',sum((v->>'quantity')::int)::int
     from jsonb_array_elements(items) v
     group by 1,2,3
   loop
     insert into public.collection_cards(user_id,set_id,card_number,variant,quantity,updated_at)
       values(uid,row_set,row_number,row_variant,amount,now())
     on conflict(user_id,set_id,card_number,variant)
       do update set quantity=public.collection_cards.quantity+excluded.quantity,updated_at=now();
   end loop;
 end loop;
 return new;
end; $$;
drop trigger if exists trade_apply_completed_trigger on public.trade_proposals;
create trigger trade_apply_completed_trigger after update on public.trade_proposals
 for each row when (new.completed_at is not null and old.completed_at is null)
 execute function public.trade_apply_completed();
revoke all on function public.trade_apply_completed() from public,anon,authenticated;
