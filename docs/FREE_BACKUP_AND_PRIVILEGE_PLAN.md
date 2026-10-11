# NFLM Collection — Free plan recovery & privilege hardening (PREPARATION ONLY)
Date: 2026-10-11
Project: NFLM Collection, Supabase Free
Status: NO DATABASE CHANGES APPLIED. NO BACKUP CREATED. NO COSTS INCURRED.

## Verified recovery options
- Organization is on Supabase **Free**.
- Supabase's managed daily backups are provided for Pro/Team/Enterprise, not Free. Point-in-time recovery is not included on Free.
- Supabase recommends manual off-site logical exports using `supabase db dump`.
- No migrations are listed by Supabase for this project. GitHub website source is NOT a backup of user data.
- No verified recoverable database backup exists in the evidence gathered. Do not apply the production change until a backup is created and verified.
- Backups can contain account details and personal data: NEVER commit `data.sql`, `roles.sql`, database URLs, passwords or private exports to GitHub.

## Safe manual backup method (do not run until user is ready)
Official guide: https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore
1. Install Docker Desktop and Supabase CLI on a trusted machine.
2. In the Supabase Dashboard, obtain the **Session pooler** connection string from Connect. Never paste the string/password into a public issue, GitHub commit, or ChatGPT conversation.
3. From a secure local folder, run (replace locally; do not share the URL):
```bash
supabase db dump --db-url "[CONNECTION_STRING]" -f roles.sql --role-only
supabase db dump --db-url "[CONNECTION_STRING]" -f schema.sql
supabase db dump --db-url "[CONNECTION_STRING]" -f data.sql --use-copy --data-only -x "storage.buckets_vectors" -x "storage.vector_indexes"
```
4. Confirm files exist and are nonempty, and check that the export finished successfully. Store encrypted copies offline. These dumps do not contain Storage file objects; back those up separately.
5. A successful dump is not yet a proven restore. Ideally perform a local isolated restore before any production change.

## Verified least-privilege issue
Effective privileges (via has_table_privilege and relacl):
- `anon` has TRUNCATE + TRIGGER on 7 public tables (all except game_progress).
- `authenticated` has TRUNCATE + TRIGGER on all 8 public tables.
- Grants appear directly in each table ACL, not only via PUBLIC.
- PostgreSQL RLS does NOT protect against TRUNCATE. PostgREST's ordinary table API does not expose arbitrary TRUNCATE, so this is defense-in-depth and a risk if other SQL/RPC paths become accessible.

## Proposed SQL migration — NOT EXECUTED
Run only after verified backup, review, testing, and explicit user permission. In production, use a transaction and check effective privileges:
```sql
BEGIN;

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

DO $$
DECLARE table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'collection_cards','friendships','game_progress','login_streaks',
    'market_listings','messages','profiles','trade_proposals'
  ] LOOP
    IF has_table_privilege('anon',format('public.%I',table_name),'TRUNCATE')
      OR has_table_privilege('authenticated',format('public.%I',table_name),'TRUNCATE')
      OR has_table_privilege('anon',format('public.%I',table_name),'TRIGGER')
      OR has_table_privilege('authenticated',format('public.%I',table_name),'TRIGGER')
    THEN
      RAISE EXCEPTION 'Unexpected TRUNCATE/TRIGGER privilege on %',table_name;
    END IF;
  END LOOP;
END $$;

COMMIT;
```

## Targeted privilege rollback (NOT EXECUTED)
Restore ONLY the grants that were present before the proposed migration; this is not a data recovery mechanism:
```sql
BEGIN;
GRANT TRUNCATE, TRIGGER ON TABLE
  public.collection_cards,
  public.friendships,
  public.login_streaks,
  public.market_listings,
  public.messages,
  public.profiles,
  public.trade_proposals
TO anon, authenticated;

GRANT TRUNCATE, TRIGGER ON TABLE public.game_progress TO authenticated;
COMMIT;
```

## Why not change anything yet?
- No verified backup or tested restore.
- Production RLS and business functions may have dependencies requiring end-to-end testing.
- There is an existing trade_proposal_guard trigger with transition validation; preserve it.
- No paid branch authorized; local development and manual backup remain the no-extra-cost options.

## Acceptance tests after explicit approval
- Verify effective TRUNCATE/TRIGGER privileges are false for anon/authenticated on all eight tables.
- Verify owner-only collection edits, accepted friend visibility, signup/Trainer-ID generation, profile save, friend request, messaging, trade proposal accept/complete, and inventory transfer.
- Re-run security advisors. Do not change RLS, trigger functions, or live site code as part of this minimal grant change.
