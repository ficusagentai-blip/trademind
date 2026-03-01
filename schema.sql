CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS public.profiles (
  id                  UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name           TEXT,
  email               TEXT NOT NULL UNIQUE,
  plan                TEXT NOT NULL DEFAULT 'free',
  subscribed_at       TIMESTAMPTZ,
  razorpay_payment_id TEXT,
  approved_by         TEXT,
  role                TEXT NOT NULL DEFAULT 'user',
  wolf_rank           TEXT DEFAULT 'Cub',
  wolf_xp             INT DEFAULT 0,
  streak              INT DEFAULT 0,
  best_streak         INT DEFAULT 0,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.trades (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date        DATE NOT NULL,
  symbol      TEXT NOT NULL,
  setup       TEXT,
  side        TEXT,
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
  confidence  INT,
  focus       INT,
  patience    INT,
  calm        INT,
  emotion     TEXT,
  psych_notes TEXT,
  lesson      TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.journals (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date       DATE NOT NULL,
  mood       TEXT,
  title      TEXT,
  body       TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.rules (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rule       TEXT NOT NULL,
  category   TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.admin_settings (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key        TEXT NOT NULL UNIQUE,
  value      TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by TEXT
);

INSERT INTO public.admin_settings (key, value) VALUES
  ('upi_id',          '9987961609@paytm'),
  ('whatsapp',        '+919987961609'),
  ('price_first',     '99'),
  ('price_monthly',   '299'),
  ('platform_name',   'TradeMind'),
  ('platform_version','1.0')
ON CONFLICT (key) DO NOTHING;

ALTER TABLE public.profiles       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trades         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journals       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rules          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_own_profile_select"    ON public.profiles;
DROP POLICY IF EXISTS "user_own_profile_update"    ON public.profiles;
DROP POLICY IF EXISTS "admin_all_profiles_select"  ON public.profiles;
DROP POLICY IF EXISTS "admin_all_profiles_update"  ON public.profiles;
DROP POLICY IF EXISTS "admin_all_profiles_delete"  ON public.profiles;
DROP POLICY IF EXISTS "user_own_trades"            ON public.trades;
DROP POLICY IF EXISTS "admin_all_trades_select"    ON public.trades;
DROP POLICY IF EXISTS "user_own_journals"          ON public.journals;
DROP POLICY IF EXISTS "user_own_rules"             ON public.rules;
DROP POLICY IF EXISTS "authenticated_read_settings"ON public.admin_settings;
DROP POLICY IF EXISTS "admin_write_settings"       ON public.admin_settings;

CREATE POLICY "user_own_profile_select" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "user_own_profile_update" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "admin_all_profiles_select" ON public.profiles
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

CREATE POLICY "admin_all_profiles_update" ON public.profiles
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

CREATE POLICY "admin_all_profiles_delete" ON public.profiles
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

CREATE POLICY "user_own_trades" ON public.trades
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "admin_all_trades_select" ON public.trades
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

CREATE POLICY "user_own_journals" ON public.journals
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "user_own_rules" ON public.rules
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "authenticated_read_settings" ON public.admin_settings
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "admin_write_settings" ON public.admin_settings
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, plan, role)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      split_part(NEW.email, '@', 1)
    ),
    NEW.email,
    'free',
    'user'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

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

CREATE INDEX IF NOT EXISTS idx_trades_user_id  ON public.trades(user_id);
CREATE INDEX IF NOT EXISTS idx_trades_date      ON public.trades(date DESC);
CREATE INDEX IF NOT EXISTS idx_journals_user_id ON public.journals(user_id);
CREATE INDEX IF NOT EXISTS idx_rules_user_id    ON public.rules(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_plan    ON public.profiles(plan);
CREATE INDEX IF NOT EXISTS idx_profiles_role    ON public.profiles(role);

INSERT INTO public.profiles (id, full_name, email, plan, role)
SELECT
  id,
  'Admin',
  email,
  'pro',
  'admin'
FROM auth.users
WHERE email = 'ficusagentai@gmail.com'
ON CONFLICT (id) DO UPDATE
SET role = 'admin', plan = 'pro', full_name = 'Admin';
