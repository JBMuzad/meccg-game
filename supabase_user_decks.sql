-- ── user_decks tabel ─────────────────────────────────────────────────────────
-- Elk record = 1 eigen deck per gebruiker (geïdentificeerd via browser UUID)

CREATE TABLE IF NOT EXISTS user_decks (
  id          text PRIMARY KEY,           -- 'own_' + timestamp
  user_id     text NOT NULL,              -- anonieme browser-UUID (localStorage)
  deck_name   text NOT NULL,
  alignment   text DEFAULT 'Hero',
  cards       jsonb NOT NULL DEFAULT '{}',-- {resources:[{qty,name}],hazards:[...],…}
  updated_at  timestamptz DEFAULT now()
);

-- Row Level Security: iedereen mag lezen/schrijven (anon key)
-- user_id is client-side filter; voldoende voor persoonlijk gebruik
ALTER TABLE user_decks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_all" ON user_decks;
CREATE POLICY "anon_all" ON user_decks
  FOR ALL TO anon
  USING (true)
  WITH CHECK (true);
