-- Track when a user's premium subscription ended.
-- Used to enforce the 1-year remote-data retention window before deletion.
ALTER TABLE public.users
  ADD COLUMN subscription_ended_at TIMESTAMPTZ DEFAULT NULL;

-- Optional: index to make the daily cleanup query efficient.
CREATE INDEX idx_users_subscription_ended_at
  ON public.users (subscription_ended_at)
  WHERE subscription_ended_at IS NOT NULL;

-- Daily pg_cron job: delete tasks and sessions for users whose subscription
-- ended more than 1 year ago.  Requires the pg_cron extension to be enabled
-- in the Supabase dashboard (Database → Extensions → pg_cron).
-- Run once manually or uncomment here to register automatically.
--
-- SELECT cron.schedule(
--   'delete-expired-user-data',
--   '0 3 * * *',
--   $$
--     DELETE FROM public.sessions
--     WHERE user_id IN (
--       SELECT id FROM public.users
--       WHERE subscription_ended_at IS NOT NULL
--         AND subscription_ended_at < NOW() - INTERVAL '1 year'
--     );
--
--     DELETE FROM public.tasks
--     WHERE user_id IN (
--       SELECT id FROM public.users
--       WHERE subscription_ended_at IS NOT NULL
--         AND subscription_ended_at < NOW() - INTERVAL '1 year'
--     );
--   $$
-- );
