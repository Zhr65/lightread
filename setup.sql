-- ============================================
-- 轻读 · 全套数据库 v3
-- 📖阅读 💡灵感 📅倒数日 🧠记忆 🌸生活
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$ LANGUAGE plpgsql;

-- 安全策略 helper
CREATE OR REPLACE FUNCTION safe_policy(tbl text, pol text) RETURNS void AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname=pol AND tablename=tbl) THEN
    EXECUTE format('CREATE POLICY %I ON %I FOR ALL USING (true) WITH CHECK (true)', pol, tbl);
  END IF;
END $$ LANGUAGE plpgsql;

-- 安全触发器 helper
CREATE OR REPLACE FUNCTION safe_trigger(tbl text, trg text) RETURNS void AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname=trg) THEN
    EXECUTE format('CREATE TRIGGER %I BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at()', trg, tbl);
  END IF;
END $$ LANGUAGE plpgsql;

-- ============================================
-- 1. 文档
-- ============================================
CREATE TABLE IF NOT EXISTS documents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY, title TEXT NOT NULL DEFAULT '未命名',
  content TEXT NOT NULL DEFAULT '', size INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
SELECT safe_trigger('documents','trg_documents_ua');
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
SELECT safe_policy('documents','anon_docs');
CREATE INDEX IF NOT EXISTS idx_docs_ua ON documents (updated_at DESC);

-- ============================================
-- 2. 灵感
-- ============================================
CREATE TABLE IF NOT EXISTS ideas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY, title TEXT NOT NULL DEFAULT '',
  content TEXT NOT NULL DEFAULT '',
  category TEXT, feasibility INTEGER DEFAULT 3, score INTEGER DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'raw' CHECK (status IN ('raw','incubating','active','archived')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
SELECT safe_trigger('ideas','trg_ideas_ua');
ALTER TABLE ideas ENABLE ROW LEVEL SECURITY;
SELECT safe_policy('ideas','anon_ideas');
CREATE INDEX IF NOT EXISTS idx_ideas_ua ON ideas (updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_ideas_status ON ideas (status);

-- ============================================
-- 3. 倒数日
-- ============================================
CREATE TABLE IF NOT EXISTS countdowns (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY, title TEXT NOT NULL DEFAULT '',
  target_date DATE NOT NULL, type TEXT NOT NULL DEFAULT 'custom',
  repeat_yearly BOOLEAN NOT NULL DEFAULT false, remind_before INTEGER NOT NULL DEFAULT 7,
  is_lunar BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
SELECT safe_trigger('countdowns','trg_countdowns_ua');
ALTER TABLE countdowns ENABLE ROW LEVEL SECURITY;
SELECT safe_policy('countdowns','anon_cds');
CREATE INDEX IF NOT EXISTS idx_cds_date ON countdowns (target_date);

-- ============================================
-- 4. 记忆大脑 🧠
-- ============================================
CREATE TABLE IF NOT EXISTS memories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL DEFAULT '',
  content TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL DEFAULT '其他',
  tags TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
SELECT safe_trigger('memories','trg_memories_ua');
ALTER TABLE memories ENABLE ROW LEVEL SECURITY;
SELECT safe_policy('memories','anon_memories');
CREATE INDEX IF NOT EXISTS idx_memories_ua ON memories (updated_at DESC);

-- ============================================
-- 5. 生活记录 🌸
-- ============================================
CREATE TABLE IF NOT EXISTS life_moments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  content TEXT NOT NULL DEFAULT '',
  photo TEXT NOT NULL DEFAULT '',       -- base64 或图片 URL
  lat DOUBLE PRECISION, lng DOUBLE PRECISION,
  place_name TEXT NOT NULL DEFAULT '',
  moment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE life_moments ENABLE ROW LEVEL SECURITY;
SELECT safe_policy('life_moments','anon_life');
CREATE INDEX IF NOT EXISTS idx_life_date ON life_moments (moment_date DESC);
