# NFLM Collection — Supabase security audit (read-only, 2026-10-11)

Project: NFLM Collection. This document contains no user records, API keys or secrets.

## Verified facts
- Eight public tables have RLS enabled: profiles, collection_cards, friendships, login_streaks, messages, game_progress, market_listings, trade_proposals.
- RLS enabled is not equivalent to correct authorization. No two-user end-to-end permission tests have been completed.
- Supabase security advisor returned seven findings: two mutable function search paths (generate_trainer_id, trade_cards_valid), two SECURITY DEFINER trigger functions executable by anon (generate_trainer_id, handle_new_user), two executable by authenticated, and leaked-password protection disabled.
- Both SECURITY DEFINER functions return trigger and appear intended for database triggers. Before restricting EXECUTE, verify the actual trigger dependencies and the resulting registration / Trainer-ID flows.
- Authenticated users may SELECT all profiles; fields include username, display_name, bio, avatar_url, favorite_pokemon and trainer_id. Decide which should be public within the application.
- collection_cards SELECT permits owner or accepted friends. INSERT, UPDATE and DELETE are owner-only.
- friendships receiver UPDATE currently permits the recipient to update their friendship row without a policy-level status transition constraint. Validate status and other column changes with explicit grants or database-side guards.
- trade_proposals UPDATE currently permits sender or recipient to update their row; the policy does not by itself restrict which fields can be changed. Validate status transitions and card payload integrity.
- market_listings are readable by all authenticated users by design; confirm no sensitive columns.
- Messages read policy permits sender or recipient; receiver UPDATE policy permits receiver to update their row but does not itself restrict editable columns to read_at.

## Required safe sequence — no production changes without approval
1. Verify triggers, current column privileges, table constraints, functions, and application write patterns via read-only queries.
2. Design least-privilege policies and trigger/function hardening in a versioned SQL migration, plus reversible rollback.
3. Obtain a separate non-production database / branch and seed only synthetic accounts and cards. Confirm any extra project/branch cost before creating it.
4. Test as anon, account A, account B, and accepted friends. Verify denial of cross-user writes and unwanted reads, and successful intended flows (signup, trainer ID, friend request, message, trades, profile update).
5. Only after tests and explicit owner approval, apply migration to production in a maintenance window; validate login and core app flows.
6. Configure leaked-password protection in Supabase Auth settings, where available on the project plan.

## Beta release blockers
- No confirmed account-isolation tests.
- No proven backup-and-restore exercise.
- No tested staging database.
- No privacy policy or user-data deletion flow review.
- No review of rights to Pokémon images and trademarks.
- No full automated browser regression suite.

## References
- https://supabase.com/docs/guides/database/database-linter?lint=0011_function_search_path_mutable
- https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable
- https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable
- https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection
