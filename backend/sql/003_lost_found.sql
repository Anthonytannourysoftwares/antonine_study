-- ============================================================
-- Lost & Found Items
-- ============================================================

CREATE TABLE IF NOT EXISTS lost_found_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type VARCHAR(10) NOT NULL CHECK (type IN ('lost', 'found')),
  title VARCHAR(200) NOT NULL,
  description TEXT DEFAULT '',
  location VARCHAR(200) DEFAULT '',
  student_id UUID,
  resolved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_lost_found_type ON lost_found_items(type);
CREATE INDEX idx_lost_found_created ON lost_found_items(created_at DESC);
