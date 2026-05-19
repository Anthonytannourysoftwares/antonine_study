-- ============================================================
-- Antonine Study — Initial Schema
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- Professors
-- ============================================================
CREATE TABLE IF NOT EXISTS professors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name TEXT NOT NULL,
  title TEXT NOT NULL DEFAULT 'Dr.',
  faculty_id TEXT NOT NULL,
  bio TEXT,
  avatar_url TEXT,
  email TEXT,
  office TEXT,
  rating_avg NUMERIC NOT NULL DEFAULT 0,
  rating_count INT NOT NULL DEFAULT 0,
  tags TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- Sections
-- ============================================================
CREATE TABLE IF NOT EXISTS sections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id TEXT NOT NULL,
  professor_id UUID NOT NULL REFERENCES professors(id) ON DELETE CASCADE,
  semester_code TEXT NOT NULL,
  capacity INT NOT NULL DEFAULT 30,
  enrolled_count INT NOT NULL DEFAULT 0,
  schedule JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sections_course ON sections(course_id);
CREATE INDEX IF NOT EXISTS idx_sections_semester ON sections(semester_code);

-- ============================================================
-- Professor Reviews
-- ============================================================
CREATE TABLE IF NOT EXISTS professor_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  professor_id UUID NOT NULL REFERENCES professors(id) ON DELETE CASCADE,
  student_id UUID NOT NULL,
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  tags TEXT[] DEFAULT '{}',
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(professor_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_reviews_professor ON professor_reviews(professor_id);

-- ============================================================
-- Enrollments
-- ============================================================
CREATE TABLE IF NOT EXISTS enrollments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id UUID NOT NULL,
  course_id TEXT NOT NULL,
  section_id UUID REFERENCES sections(id) ON DELETE SET NULL,
  semester_code TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'enrolled' CHECK (status IN ('enrolled', 'dropped', 'completed')),
  enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(student_id, course_id, semester_code)
);

CREATE INDEX IF NOT EXISTS idx_enrollments_student ON enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_semester ON enrollments(semester_code);
