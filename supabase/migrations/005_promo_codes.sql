-- Promo codes for granting premium access (testing & marketing).
-- Clients have NO direct access to these tables (RLS enabled, zero policies);
-- redemption goes exclusively through the SECURITY DEFINER function below,
-- called from the app as a parameterized RPC.

CREATE TABLE IF NOT EXISTS promo_codes (
  code TEXT PRIMARY KEY CHECK (code = upper(code)),
  duration_days INTEGER NOT NULL DEFAULT 30 CHECK (duration_days > 0),
  max_redemptions INTEGER NOT NULL DEFAULT 1 CHECK (max_redemptions > 0),
  redemption_count INTEGER NOT NULL DEFAULT 0,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS promo_redemptions (
  code TEXT NOT NULL REFERENCES promo_codes(code) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  redeemed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (code, user_id)
);

ALTER TABLE promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE promo_redemptions ENABLE ROW LEVEL SECURITY;
-- Intentionally no policies: deny all direct client access.

CREATE OR REPLACE FUNCTION redeem_promo_code(p_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := (SELECT auth.uid());
  v_promo promo_codes%ROWTYPE;
  v_renews_at TIMESTAMPTZ;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'not_authenticated');
  END IF;

  SELECT * INTO v_promo
    FROM promo_codes
   WHERE code = upper(trim(p_code))
     FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'invalid_code');
  END IF;

  IF v_promo.expires_at IS NOT NULL AND v_promo.expires_at < NOW() THEN
    RETURN jsonb_build_object('success', false, 'error', 'expired');
  END IF;

  IF v_promo.redemption_count >= v_promo.max_redemptions THEN
    RETURN jsonb_build_object('success', false, 'error', 'exhausted');
  END IF;

  IF EXISTS (
    SELECT 1 FROM promo_redemptions
     WHERE code = v_promo.code AND user_id = v_user_id
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'already_redeemed');
  END IF;

  INSERT INTO promo_redemptions (code, user_id)
  VALUES (v_promo.code, v_user_id);

  UPDATE promo_codes
     SET redemption_count = redemption_count + 1
   WHERE code = v_promo.code;

  v_renews_at := NOW() + make_interval(days => v_promo.duration_days);

  UPDATE users
     SET is_premium = TRUE,
         subscription_renews_at = v_renews_at,
         subscription_ended_at = NULL
   WHERE id = v_user_id;

  RETURN jsonb_build_object('success', true, 'premium_until', v_renews_at);
END;
$$;

REVOKE ALL ON FUNCTION redeem_promo_code(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION redeem_promo_code(TEXT) TO authenticated;

-- Create codes from the Supabase SQL editor (never ship codes in the app):
-- INSERT INTO promo_codes (code, duration_days, max_redemptions, expires_at)
-- VALUES ('DORO-TESTER', 30, 20, NOW() + INTERVAL '90 days');
--
-- To manually revoke a user's premium for testing, keep is_premium = TRUE and
-- back-date the renewal; the app records the expiry on next load:
-- UPDATE users SET subscription_renews_at = NOW() - INTERVAL '1 day'
--  WHERE email = 'tester@example.com';
