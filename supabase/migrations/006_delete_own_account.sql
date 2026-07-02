-- ============================================================
-- Self-service account deletion (Google Play data-deletion requirement)
-- ============================================================
-- Lets an authenticated user permanently delete their own account.
-- Deleting the auth.users row cascades to public.users, public.tasks and
-- public.sessions (all reference auth.users(id) ON DELETE CASCADE), so this
-- one delete removes every trace of the account's data.
--
-- Runs as SECURITY DEFINER because the `authenticated` role cannot delete
-- from the auth schema directly. Must be created by a privileged role
-- (the Supabase SQL editor / `supabase db push` run as such by default).

CREATE OR REPLACE FUNCTION public.delete_own_account()
  RETURNS void
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = ''
AS $$
DECLARE
  uid uuid := (SELECT auth.uid());
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Cascades to public.users, public.tasks, public.sessions.
  DELETE FROM auth.users WHERE id = uid;
END;
$$;

-- Only signed-in users may call it; never anon/public.
REVOKE ALL ON FUNCTION public.delete_own_account() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
