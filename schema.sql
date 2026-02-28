-- ════════════════════════════════════════════════════════
-- TradeMind — Supabase Schema (COMPLETE + FIXED)
-- Supabase SQL Editor मध्ये हे paste करा आणि Run करा
-- ════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ════════════════════════════════════════════════════════
-- TABLES
-- ════════════════════════════════════════════════════════

-- PROFILES
CREATE TABLE public.profiles (
  id                  UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name                TEXT NOT NULL,
  email               TEXT NOT NULL UNIQUE,
  plan                TEXT NOT NULL DEFAULT 'free' CHECK (plan IN ('free','pending','pro')),
  subscribed_at       TIMESTAMPTZ,
  razorpay_payment_id TEXT,
  approved_by         TEXT,
  role                TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user','admin')),
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- TRADES
CREATE TABLE public.trades (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date        DATE NOT NULL,
  symbol      TEXT NOT NULL,
  setup       TEXT,
  side        TEXT CHECK (side IN ('LONG','SHORT')),
  entry       NUMERIC(12,2) NOT NULL,
  exit        NUMERIC(12,2) NOT NULL,
  qty         NUMERIC(12,2) NOT NULL,
  sl          NUMERIC(12,2),
  target      NUMERIC(12,2),
  pnl         NUMERIC(12,2) NOT NULL,
  session     TEXT,
  instrument  TEXT,
  notes       TEXT,
  disc_score  NUMERIC(5,2),
  violated    TEXT[],
  exec_notes  TEXT,
  confidence  INT CHECK (confidence BETWEEN 1 AND 10),
  focus       INT CHECK (focus BETWEEN 1 AND 10),
  patience    INT CHECK (patience BETWEEN 1 AND 10),
  calm        INT CHECK (calm BETWEEN 1 AND 10),
  emotion     TEXT,
  psych_notes TEXT,
  lesson      TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- JOURNALS
CREATE TABLE public.journals (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date       DATE NOT NULL,
  mood       TEXT,
  title      TEXT,
  body       TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RULES
CREATE TABLE public.rules (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rule       TEXT NOT NULL,
  category   TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ADMIN SETTINGS (Supabase Lint error fix करण्यासाठी — RLS सहित)
CREATE TABLE public.admin_settings (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key        TEXT NOT NULL UNIQUE,
  value      TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by TEXT
);

-- Default admin settings insert
INSERT INTO public.admin_settings (key, value) VALUES
  ('upi_id',          '9987961609@paytm'),
  ('whatsapp',        '+919987961609'),
  ('price_first',     '99'),
  ('price_monthly',   '299'),
  ('platform_name',   'TradeMind'),
  ('platform_version','1.0'');

-- ════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS) — सर्व tables वर
-- ════════════════════════════════════════════════════════

ALTER TABLE public.profiles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trades          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journals        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rules           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_settings  ENABLE ROW LEVEL SECURITY;

-- ── PROFILES policies ──
-- User can read/update their own profile
CREATE POLICY "user_own_profile_select" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "user_own_profile_update" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Admin can read ALL profiles
CREATE POLICY "admin_all_profiles_select" ON public.profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'admin'
    )
  );

-- Admin can update ALL profiles (for grant/revoke pro)
CREATE POLICY "admin_all_profiles_update" ON public.profiles
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'admin'
    )
  );

-- Admin can delete profiles
CREATE POLICY "admin_all_profiles_delete" ON public.profiles
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'admin'
    )
  );

-- ── TRADES policies ──
CREATE POLICY "user_own_trades" ON public.trades
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "admin_all_trades_select" ON public.trades
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'admin'
    )
  );

-- ── JOURNALS policies ──
CREATE POLICY "user_own_journals" ON public.journals
  FOR ALL USING (auth.uid() = user_id);

-- ── RULES policies ──
CREATE POLICY "user_own_rules" ON public.rules
  FOR ALL USING (auth.uid() = user_id);

-- ── ADMIN SETTINGS policies ──
-- Anyone authenticated can READ settings (prices, UPI ID etc.)
CREATE POLICY "authenticated_read_settings" ON public.admin_settings
  FOR SELECT TO authenticated
  USING (true);

-- Only admins can write settings
CREATE POLICY "admin_write_settings" ON public.admin_settings
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'admin'
    )
  );

-- ════════════════════════════════════════════════════════
-- TRIGGER — Auto create profile on signup
-- ════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, plan, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.email,
    'free',
    'user'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop if exists, then recreate
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ════════════════════════════════════════════════════════
-- TRIGGER — Auto update updated_at on profiles
-- ════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS profiles_updated_at ON public.profiles;
CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.update_updated_at();

DROP TRIGGER IF EXISTS admin_settings_updated_at ON public.admin_settings;
CREATE TRIGGER admin_settings_updated_at
  BEFORE UPDATE ON public.admin_settings
  FOR EACH ROW EXECUTE PROCEDURE public.update_updated_at();

-- ════════════════════════════════════════════════════════
-- INDEXES — Performance साठी
-- ════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_trades_user_id   ON public.trades(user_id);
CREATE INDEX IF NOT EXISTS idx_trades_date       ON public.trades(date DESC);
CREATE INDEX IF NOT EXISTS idx_trades_pnl        ON public.trades(pnl);
CREATE INDEX IF NOT EXISTS idx_journals_user_id  ON public.journals(user_id);
CREATE INDEX IF NOT EXISTS idx_journals_date     ON public.journals(date DESC);
CREATE INDEX IF NOT EXISTS idx_rules_user_id     ON public.rules(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_plan     ON public.profiles(plan);
CREATE INDEX IF NOT EXISTS idx_profiles_role     ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_admin_settings_key ON public.admin_settings(key);

-- ════════════════════════════════════════════════════════
-- GRANT — Anon key ला profiles insert करता यावं (signup साठी)
-- ════════════════════════════════════════════════════════

-- Note: handle_new_user() trigger SECURITY DEFINER आहे,
-- त्यामुळे anon users ला direct insert grant करण्याची गरज नाही.
-- Supabase auth.users trigger आपोआप handle करतो.

-- ════════════════════════════════════════════════════════
-- DONE! ✅
-- Tables: profiles, trades, journals, rules, admin_settings
-- RLS: सर्व tables वर enabled + policies set
-- Triggers: auto profile create, auto updated_at
-- Indexes: performance optimized
-- ════════════════════════════════════════════════════════
