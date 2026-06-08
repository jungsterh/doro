-- ============================================================
-- Trackr — Supabase initial schema
-- Run this in the Supabase SQL Editor (or via supabase db push)
-- ============================================================

-- --------------------------
-- tasks
-- --------------------------
CREATE TABLE IF NOT EXISTS public.tasks (
  id             TEXT        PRIMARY KEY,
  user_id        UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name           TEXT        NOT NULL,
  color_hex      TEXT        NOT NULL,
  created_at     TEXT        NOT NULL
);

-- Index for fast per-user lookups
CREATE INDEX IF NOT EXISTS tasks_user_id_idx ON public.tasks (user_id);

-- --------------------------
-- sessions
-- --------------------------
CREATE TABLE IF NOT EXISTS public.sessions (
  id                 TEXT     PRIMARY KEY,
  user_id            UUID     NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  task_id            TEXT     NOT NULL,
  start_time         TEXT     NOT NULL,
  end_time           TEXT,
  duration_seconds   INTEGER  NOT NULL DEFAULT 0,
  comment            TEXT
);

-- Indexes for common query patterns
CREATE INDEX IF NOT EXISTS sessions_user_id_idx     ON public.sessions (user_id);
CREATE INDEX IF NOT EXISTS sessions_task_id_idx     ON public.sessions (task_id);
CREATE INDEX IF NOT EXISTS sessions_start_time_idx  ON public.sessions (start_time DESC);
