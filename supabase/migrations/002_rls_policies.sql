-- ============================================================
-- Trackr — Row Level Security (RLS) policies
-- Run AFTER 001_initial_schema.sql
-- ============================================================

-- Enable RLS on both tables
ALTER TABLE public.tasks    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;

-- =====================
-- tasks policies
-- =====================
DROP POLICY IF EXISTS "tasks: select own" ON public.tasks;
CREATE POLICY "tasks: select own"
  ON public.tasks FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "tasks: insert own" ON public.tasks;
CREATE POLICY "tasks: insert own"
  ON public.tasks FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "tasks: update own" ON public.tasks;
CREATE POLICY "tasks: update own"
  ON public.tasks FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "tasks: delete own" ON public.tasks;
CREATE POLICY "tasks: delete own"
  ON public.tasks FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- =====================
-- sessions policies
-- =====================
DROP POLICY IF EXISTS "sessions: select own" ON public.sessions;
CREATE POLICY "sessions: select own"
  ON public.sessions FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "sessions: insert own" ON public.sessions;
CREATE POLICY "sessions: insert own"
  ON public.sessions FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "sessions: update own" ON public.sessions;
CREATE POLICY "sessions: update own"
  ON public.sessions FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "sessions: delete own" ON public.sessions;
CREATE POLICY "sessions: delete own"
  ON public.sessions FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- =====================
-- Optional: allow service_role to bypass RLS for admin tasks
-- (service_role key already bypasses RLS by default in Supabase)
-- =====================
