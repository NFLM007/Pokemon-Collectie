# NFLM Collection — urgent least-privilege grants proposal
Date: 2026-10-11
Status: PROPOSAL ONLY. NOT APPLIED TO PRODUCTION.

## Read-only verification
All eight public tables have RLS enabled. However, PostgreSQL has_table_privilege confirms:
- anon: TRUNCATE on collection_cards, friendships, login_streaks, market_listings, messages, profiles, trade_proposals (7 of 8); TRIGGER on the same 7 tables.
- authenticated: TRUNCATE on all 8 public tables.
- game_progress: anon lacks TRUNCATE, authenticated has TRUNCATE.

**Important:** PostgreSQL TRUNCATE is not subject to row-level security. This is an authorization hardening priority. Do not assume the REST client exposes a TRUNCATE operation directly; actual exploitability depends on available SQL/RPC execution paths.

## Production proposal (requires owner approval)
After backup and dependency review, revoke unused table-level privileges:
```sql
-- PROPOSAL; DO NOT RUN UNTIL APPROVED.
REVOKE TRUNCATE, TRIGGER ON ALL TABLES IN SCHEMA public FROM anon, authenticated;
```
Note: SQL above affects all current public tables, not only the eight audited tables. Before running, scope it to the eight known tables and review newly created tables. PostgreSQL GRANT/REVOKE may need to account for privileges inherited through PUBLIC or other roles. Confirm effective privileges afterward via has_table_privilege. This change does not delete rows, but may affect code or database routines that require these grants. Use a maintenance window and rollback plan.

Safer explicitly scoped candidate:
```sql
REVOKE TRUNCATE, TRIGGER ON TABLE
  public.collection_cards,
  public.friendships,
  public.game_progress,
  public.login_streaks,
  public.market_listings,
  public.messages,
  public.profiles,
  public.trade_proposals
FROM anon, authenticated;
```

## Additional findings
- UPDATE grants cover all columns for profiles, messages, friendships and trade_proposals, including immutable identities and content. RLS is row-based, not column-based. Harden column grants or use dedicated secure functions/triggers.
- Frontend currently uses messages UPDATE only to set read_at, friendships UPDATE only to set status, and profiles UPDATE only to set username, bio, favorite_pokemon and avatar_url.
- IMPORTANT CORRECTION: trade_proposals already has a BEFORE UPDATE guard trigger (trade_proposal_guard) checking immutable parties/card contents, legal transitions, and participant confirmations, plus an AFTER UPDATE completion trigger (trade_apply_completed). This reduces the earlier suspected risk from broad UPDATE grants. Test the guard rather than removing it.
- Supabase advisor: mutable search_path on generate_trainer_id and trade_cards_valid; trigger SECURITY DEFINER functions generate_trainer_id and handle_new_user executable by anon/authenticated; leaked password protection disabled.
- Trigger functions generate_trainer_id and handle_new_user are needed for Trainer-ID generation and account creation; review impact before changing EXECUTE grants.
- Profile data is readable by any authenticated user, including bio, avatar_url and trainer_id; confirm intended privacy.

## Validation checklist
1. Confirm effective grants on all public tables and any grants inherited via PUBLIC.
2. Confirm no application RPC/SQL function relies on end-user TRUNCATE/TRIGGER privileges.
3. Preserve backup or reliable recovery path before production changes.
4. Test signup, Trainer-ID assignment, profile save, friend request acceptance, message send/read, trade proposal acceptance/completion.
5. Re-run Supabase security advisors and read-only grants query.

No live DB changes were made in this investigation.
