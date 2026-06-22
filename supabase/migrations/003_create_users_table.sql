-- Create users table to store authentication & premium subscription status
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  display_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  is_premium BOOLEAN DEFAULT FALSE,
  trial_ends_at TIMESTAMPTZ,
  subscription_renews_at TIMESTAMPTZ
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only read their own record
DROP POLICY IF EXISTS "Users can view own record" ON users;
CREATE POLICY "Users can view own record"
  ON users FOR SELECT
  USING ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Users can update own record" ON users;
CREATE POLICY "Users can update own record"
  ON users FOR UPDATE
  USING ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Service role can insert user records" ON users;
CREATE POLICY "Service role can insert user records"
  ON users FOR INSERT
  WITH CHECK (true);
