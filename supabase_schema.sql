-- ============================================================
-- MECCG Game Database Schema
-- Uitvoeren in Supabase SQL Editor
-- ============================================================

-- 1. Regio's
CREATE TABLE IF NOT EXISTS regions (
  rid        text PRIMARY KEY,
  name       text NOT NULL,
  name2      text,                    -- alternatieve naam
  type       text NOT NULL,           -- W/B/S/D/F/C
  tc         text,                    -- fill kleur (RGBA)
  ts         text,                    -- stroke kleur
  hazards    text[] DEFAULT '{}',
  polys      text,                    -- SVG polygon punten
  updated_at timestamptz DEFAULT now()
);

-- 2. Buurregios (adjacency)
CREATE TABLE IF NOT EXISTS region_adjacency (
  rid        text PRIMARY KEY REFERENCES regions(rid),
  neighbors  text[] DEFAULT '{}'
);

-- 3. Sites
CREATE TABLE IF NOT EXISTS sites (
  id         serial PRIMARY KEY,
  name       text NOT NULL,
  alignment  text,                    -- Hero/Minion/Balrog/Fallen-wizard
  type       text,                    -- haven/free/ruins/border/shadow/dark
  img        text,                    -- bestandsnaam (legacy)
  loc        text,                    -- lokaal pad (legacy)
  cdn        text,                    -- Supabase CDN URL
  set_code   text,                    -- tw/dm/le/...
  region     text,                    -- regio naam
  near_haven text                     -- dichtstbijzijnde haven
);

-- 4. Site markers (kaartposities)
CREATE TABLE IF NOT EXISTS site_markers (
  id         serial PRIMARY KEY,
  name       text NOT NULL,
  type       text,
  rid        text REFERENCES regions(rid),
  x          integer,
  y          integer
);

-- 5. Card overrides (voor stap 5 - editeerbaar)
CREATE TABLE IF NOT EXISTS card_overrides (
  card_id    text PRIMARY KEY,
  img_url    text,
  attrs      jsonb DEFAULT '{}',
  note       text,
  updated_at timestamptz DEFAULT now()
);

-- 6. Region overrides (voor stap 5 - editeerbaar)
CREATE TABLE IF NOT EXISTS region_overrides (
  rid        text PRIMARY KEY,
  name       text,
  name2      text,
  type       text,
  hazards    text[],
  updated_at timestamptz DEFAULT now()
);

-- RLS: publiek leesbaar (geen auth nodig om te lezen)
ALTER TABLE regions ENABLE ROW LEVEL SECURITY;
ALTER TABLE region_adjacency ENABLE ROW LEVEL SECURITY;
ALTER TABLE sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE site_markers ENABLE ROW LEVEL SECURITY;
ALTER TABLE card_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE region_overrides ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read" ON regions FOR SELECT USING (true);
CREATE POLICY "Public read" ON region_adjacency FOR SELECT USING (true);
CREATE POLICY "Public read" ON sites FOR SELECT USING (true);
CREATE POLICY "Public read" ON site_markers FOR SELECT USING (true);
CREATE POLICY "Public read" ON card_overrides FOR SELECT USING (true);
CREATE POLICY "Public read" ON region_overrides FOR SELECT USING (true);

-- Schrijven enkel met service role key (via app na auth)
CREATE POLICY "Auth write" ON card_overrides FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Auth write" ON region_overrides FOR ALL USING (auth.role() = 'authenticated');

-- 7. Spelersprofiel (gekoppeld aan Supabase Auth)
CREATE TABLE IF NOT EXISTS profiles (
  id           uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text NOT NULL DEFAULT '',
  wizard       text NOT NULL DEFAULT '',
  preferences  jsonb NOT NULL DEFAULT '{}',
  created_at   timestamptz DEFAULT now(),
  updated_at   timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Iedereen mag zijn eigen profiel lezen/schrijven; anonieme gebruikers zien niets
CREATE POLICY "Own profile select" ON profiles FOR SELECT  USING (auth.uid() = id);
CREATE POLICY "Own profile insert" ON profiles FOR INSERT  WITH CHECK (auth.uid() = id);
CREATE POLICY "Own profile update" ON profiles FOR UPDATE  USING (auth.uid() = id);
