-- ============================================================
-- Antonine Study — Seed Data
-- TODO(user): replace seed data with real Antonine roster
-- ============================================================

-- ============================================================
-- 15 Professors (Computer Engineering faculty)
-- ============================================================

INSERT INTO professors (id, full_name, title, faculty_id, bio, email, office, tags) VALUES
  ('a0000001-0000-0000-0000-000000000001', 'Georges Khoury', 'Dr.', 'fea',
   'Specializes in linear algebra and discrete mathematics. 12 years at Antonine University with research in applied mathematics.',
   'gkhoury@ua.edu.lb', 'A102', ARRAY['clear explanations', 'approachable', 'practical examples']),

  ('a0000001-0000-0000-0000-000000000002', 'Nadia Haddad', 'Prof.', 'fea',
   'Expert in electrostatics and electromagnetism. Published 30+ papers on electromagnetic field theory.',
   'nhaddad@ua.edu.lb', 'B201', ARRAY['research-focused', 'strict grading', 'engaging lectures']),

  ('a0000001-0000-0000-0000-000000000003', 'Michel Aoun', 'Dr.', 'fea',
   'Teaches programming and data structures. Industry background at Murex before joining academia.',
   'maoun@ua.edu.lb', 'C105', ARRAY['practical examples', 'lots of homework', 'fast-paced']),

  ('a0000001-0000-0000-0000-000000000004', 'Rima Nassar', 'Prof.', 'fea',
   'Database systems and web technologies specialist. Leads the university digital transformation committee.',
   'rnassar@ua.edu.lb', 'A205', ARRAY['approachable', 'flexible deadlines', 'clear explanations']),

  ('a0000001-0000-0000-0000-000000000005', 'Antoine Sfeir', 'Dr.', 'fea',
   'Network architecture and security researcher. Cisco-certified instructor with telecom industry experience.',
   'asfeir@ua.edu.lb', 'B303', ARRAY['exam-heavy', 'engaging lectures', 'strict grading']),

  ('a0000001-0000-0000-0000-000000000006', 'Elias Daou', 'Eng.', 'fea',
   'Computer architecture and operating systems. Background at Intel before returning to Lebanon.',
   'edaou@ua.edu.lb', 'C201', ARRAY['fast-paced', 'practical examples', 'lots of homework']),

  ('a0000001-0000-0000-0000-000000000007', 'Carla Mansour', 'Dr.', 'fea',
   'Artificial intelligence and machine learning. PhD from Sorbonne, leads the AI research lab at UA.',
   'cmansour@ua.edu.lb', 'A301', ARRAY['research-focused', 'engaging lectures', 'clear explanations']),

  ('a0000001-0000-0000-0000-000000000008', 'Marc Bechara', 'Eng.', 'fea',
   'Web development and open-source systems. Active contributor to several open-source projects.',
   'mbechara@ua.edu.lb', 'B105', ARRAY['flexible deadlines', 'practical examples', 'approachable']),

  ('a0000001-0000-0000-0000-000000000009', 'Hala Kassab', 'Dr.', 'fea',
   'Probability, statistics, and operations research. Consults for regional banks on risk modeling.',
   'hkassab@ua.edu.lb', 'A204', ARRAY['clear explanations', 'exam-heavy', 'strict grading']),

  ('a0000001-0000-0000-0000-000000000010', 'Joseph Khalil', 'Prof.', 'fea',
   'Calculus and numerical analysis. 20+ years teaching mathematics at Antonine University.',
   'jkhalil@ua.edu.lb', 'B102', ARRAY['approachable', 'clear explanations', 'flexible deadlines']),

  ('a0000001-0000-0000-0000-000000000011', 'Sandra Frem', 'Dr.', 'fea',
   'Fundamentals of electronics and circuit design. Co-authored the department lab manual.',
   'sfrem@ua.edu.lb', 'C103', ARRAY['lots of homework', 'practical examples', 'engaging lectures']),

  ('a0000001-0000-0000-0000-000000000012', 'Pierre Rahal', 'Dr.', 'fea',
   'Information systems security and cryptography. Former CERT Lebanon team lead.',
   'prahal@ua.edu.lb', 'A106', ARRAY['fast-paced', 'exam-heavy', 'research-focused']),

  ('a0000001-0000-0000-0000-000000000013', 'Maya Geagea', 'Dr.', 'fea',
   'Oral communication and technical writing specialist. Bilingual French-English curriculum developer.',
   'mgeagea@ua.edu.lb', 'B204', ARRAY['approachable', 'flexible deadlines', 'clear explanations']),

  ('a0000001-0000-0000-0000-000000000014', 'Charbel Mouawad', 'Dr.', 'fea',
   'Advanced programming and software architecture. .NET and cloud computing specialist.',
   'cmouawad@ua.edu.lb', 'C202', ARRAY['practical examples', 'fast-paced', 'lots of homework']),

  ('a0000001-0000-0000-0000-000000000015', 'Layla Saad', 'Dr.', 'fea',
   'Infographics, multimedia databases, and image processing researcher.',
   'lsaad@ua.edu.lb', 'A303', ARRAY['engaging lectures', 'flexible deadlines', 'approachable']);

-- ============================================================
-- Sections — Real Antonine CE Curriculum
-- Course IDs match curriculum.json (ce_* prefix for CE major)
-- ~3 sections per course, semester_code: Y1S1, Y1S2, Y2S3, etc.
-- ============================================================

-- === YEAR 1, SEMESTER 1 ===

-- Algebra I (3 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_alg1', 'a0000001-0000-0000-0000-000000000001', 'Y1S1', 35, 28,
   '[{"day":"MON","start":"08:00","end":"09:30","room":"A102"},{"day":"WED","start":"08:00","end":"09:30","room":"A102"}]'),
  ('ce_alg1', 'a0000001-0000-0000-0000-000000000010', 'Y1S1', 35, 32,
   '[{"day":"TUE","start":"10:00","end":"11:30","room":"B102"},{"day":"THU","start":"10:00","end":"11:30","room":"B102"}]'),
  ('ce_alg1', 'a0000001-0000-0000-0000-000000000009', 'Y1S1', 30, 25,
   '[{"day":"MON","start":"14:00","end":"15:30","room":"A204"},{"day":"WED","start":"14:00","end":"15:30","room":"A204"}]');

-- Lab. Computer and Networks (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_lab_networks', 'a0000001-0000-0000-0000-000000000005', 'Y1S1', 25, 22,
   '[{"day":"TUE","start":"14:00","end":"16:00","room":"LAB-NET1"}]'),
  ('ce_lab_networks', 'a0000001-0000-0000-0000-000000000005', 'Y1S1', 25, 20,
   '[{"day":"THU","start":"14:00","end":"16:00","room":"LAB-NET1"}]');

-- Lab. Programming I (3 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_lab_prog1', 'a0000001-0000-0000-0000-000000000003', 'Y1S1', 25, 24,
   '[{"day":"WED","start":"10:00","end":"12:00","room":"LAB-CS1"}]'),
  ('ce_lab_prog1', 'a0000001-0000-0000-0000-000000000008', 'Y1S1', 25, 18,
   '[{"day":"FRI","start":"08:00","end":"10:00","room":"LAB-CS1"}]'),
  ('ce_lab_prog1', 'a0000001-0000-0000-0000-000000000003', 'Y1S1', 25, 23,
   '[{"day":"THU","start":"08:00","end":"10:00","room":"LAB-CS2"}]');

-- Programming I (3 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_prog1', 'a0000001-0000-0000-0000-000000000003', 'Y1S1', 35, 33,
   '[{"day":"MON","start":"10:00","end":"11:30","room":"C105"},{"day":"WED","start":"10:00","end":"11:30","room":"C105"}]'),
  ('ce_prog1', 'a0000001-0000-0000-0000-000000000008', 'Y1S1', 35, 27,
   '[{"day":"TUE","start":"08:00","end":"09:30","room":"B105"},{"day":"THU","start":"08:00","end":"09:30","room":"B105"}]'),
  ('ce_prog1', 'a0000001-0000-0000-0000-000000000003', 'Y1S1', 30, 30,
   '[{"day":"MON","start":"16:00","end":"17:30","room":"C105"},{"day":"WED","start":"16:00","end":"17:30","room":"C105"}]');

-- Introduction to Engineering (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_intro_eng', 'a0000001-0000-0000-0000-000000000006', 'Y1S1', 40, 35,
   '[{"day":"FRI","start":"10:00","end":"11:30","room":"AMPH-A"}]'),
  ('ce_intro_eng', 'a0000001-0000-0000-0000-000000000006', 'Y1S1', 40, 30,
   '[{"day":"FRI","start":"14:00","end":"15:30","room":"AMPH-A"}]');

-- Circuit Analysis (3 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_circuit', 'a0000001-0000-0000-0000-000000000011', 'Y1S1', 35, 30,
   '[{"day":"TUE","start":"10:00","end":"11:30","room":"C103"},{"day":"THU","start":"10:00","end":"11:30","room":"C103"}]'),
  ('ce_circuit', 'a0000001-0000-0000-0000-000000000002', 'Y1S1', 35, 28,
   '[{"day":"MON","start":"08:00","end":"09:30","room":"B201"},{"day":"WED","start":"08:00","end":"09:30","room":"B201"}]'),
  ('ce_circuit', 'a0000001-0000-0000-0000-000000000011', 'Y1S1', 30, 26,
   '[{"day":"TUE","start":"16:00","end":"17:30","room":"C103"},{"day":"THU","start":"16:00","end":"17:30","room":"C103"}]');

-- Lab Circuit Analysis (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_lab_circuit', 'a0000001-0000-0000-0000-000000000011', 'Y1S1', 20, 18,
   '[{"day":"WED","start":"14:00","end":"16:00","room":"LAB-ELEC1"}]'),
  ('ce_lab_circuit', 'a0000001-0000-0000-0000-000000000011', 'Y1S1', 20, 17,
   '[{"day":"FRI","start":"14:00","end":"16:00","room":"LAB-ELEC1"}]');

-- === YEAR 1, SEMESTER 2 ===

-- Algebra II (3 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_alg2', 'a0000001-0000-0000-0000-000000000001', 'Y1S2', 35, 30,
   '[{"day":"MON","start":"08:00","end":"09:30","room":"A102"},{"day":"WED","start":"08:00","end":"09:30","room":"A102"}]'),
  ('ce_alg2', 'a0000001-0000-0000-0000-000000000010', 'Y1S2', 35, 26,
   '[{"day":"TUE","start":"10:00","end":"11:30","room":"B102"},{"day":"THU","start":"10:00","end":"11:30","room":"B102"}]'),
  ('ce_alg2', 'a0000001-0000-0000-0000-000000000001', 'Y1S2', 30, 22,
   '[{"day":"MON","start":"14:00","end":"15:30","room":"A102"},{"day":"WED","start":"14:00","end":"15:30","room":"A102"}]');

-- Calculus II (3 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_calc2', 'a0000001-0000-0000-0000-000000000010', 'Y1S2', 35, 31,
   '[{"day":"MON","start":"10:00","end":"11:30","room":"B102"},{"day":"WED","start":"10:00","end":"11:30","room":"B102"}]'),
  ('ce_calc2', 'a0000001-0000-0000-0000-000000000001', 'Y1S2', 35, 29,
   '[{"day":"TUE","start":"08:00","end":"09:30","room":"A102"},{"day":"THU","start":"08:00","end":"09:30","room":"A102"}]'),
  ('ce_calc2', 'a0000001-0000-0000-0000-000000000009', 'Y1S2', 30, 24,
   '[{"day":"TUE","start":"14:00","end":"15:30","room":"A204"},{"day":"THU","start":"14:00","end":"15:30","room":"A204"}]');

-- Electrostatics (3 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_electrostatics', 'a0000001-0000-0000-0000-000000000002', 'Y1S2', 35, 32,
   '[{"day":"TUE","start":"10:00","end":"11:30","room":"B201"},{"day":"THU","start":"10:00","end":"11:30","room":"B201"}]'),
  ('ce_electrostatics', 'a0000001-0000-0000-0000-000000000002', 'Y1S2', 35, 27,
   '[{"day":"MON","start":"14:00","end":"15:30","room":"B201"},{"day":"WED","start":"14:00","end":"15:30","room":"B201"}]'),
  ('ce_electrostatics', 'a0000001-0000-0000-0000-000000000011', 'Y1S2', 30, 23,
   '[{"day":"FRI","start":"08:00","end":"09:30","room":"C103"},{"day":"FRI","start":"10:00","end":"11:30","room":"C103"}]');

-- Introduction to Networks (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_intro_net', 'a0000001-0000-0000-0000-000000000005', 'Y1S2', 35, 30,
   '[{"day":"MON","start":"10:00","end":"11:30","room":"B303"},{"day":"WED","start":"10:00","end":"11:30","room":"B303"}]'),
  ('ce_intro_net', 'a0000001-0000-0000-0000-000000000005', 'Y1S2', 35, 28,
   '[{"day":"TUE","start":"16:00","end":"17:30","room":"B303"},{"day":"THU","start":"16:00","end":"17:30","room":"B303"}]');

-- Programming II (3 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_prog2', 'a0000001-0000-0000-0000-000000000003', 'Y1S2', 35, 33,
   '[{"day":"TUE","start":"08:00","end":"09:30","room":"C105"},{"day":"THU","start":"08:00","end":"09:30","room":"C105"}]'),
  ('ce_prog2', 'a0000001-0000-0000-0000-000000000008', 'Y1S2', 35, 25,
   '[{"day":"MON","start":"16:00","end":"17:30","room":"B105"},{"day":"WED","start":"16:00","end":"17:30","room":"B105"}]'),
  ('ce_prog2', 'a0000001-0000-0000-0000-000000000003', 'Y1S2', 30, 28,
   '[{"day":"FRI","start":"10:00","end":"11:30","room":"C105"},{"day":"FRI","start":"14:00","end":"15:30","room":"C105"}]');

-- Lab. CAD & GIS (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_lab_cad', 'a0000001-0000-0000-0000-000000000015', 'Y1S2', 25, 20,
   '[{"day":"WED","start":"14:00","end":"16:00","room":"LAB-CAD"}]'),
  ('ce_lab_cad', 'a0000001-0000-0000-0000-000000000015', 'Y1S2', 25, 18,
   '[{"day":"FRI","start":"14:00","end":"16:00","room":"LAB-CAD"}]');

-- === YEAR 2, SEMESTER 3 ===

-- Calculus III (3 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_calc3', 'a0000001-0000-0000-0000-000000000010', 'Y2S3', 35, 29,
   '[{"day":"MON","start":"08:00","end":"09:30","room":"B102"},{"day":"WED","start":"08:00","end":"09:30","room":"B102"}]'),
  ('ce_calc3', 'a0000001-0000-0000-0000-000000000001', 'Y2S3', 35, 27,
   '[{"day":"TUE","start":"10:00","end":"11:30","room":"A102"},{"day":"THU","start":"10:00","end":"11:30","room":"A102"}]'),
  ('ce_calc3', 'a0000001-0000-0000-0000-000000000010', 'Y2S3', 30, 22,
   '[{"day":"MON","start":"14:00","end":"15:30","room":"B102"},{"day":"WED","start":"14:00","end":"15:30","room":"B102"}]');

-- Data Structures (3 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_ds', 'a0000001-0000-0000-0000-000000000003', 'Y2S3', 35, 34,
   '[{"day":"TUE","start":"08:00","end":"09:30","room":"C105"},{"day":"THU","start":"08:00","end":"09:30","room":"C105"}]'),
  ('ce_ds', 'a0000001-0000-0000-0000-000000000008', 'Y2S3', 35, 26,
   '[{"day":"MON","start":"10:00","end":"11:30","room":"B105"},{"day":"WED","start":"10:00","end":"11:30","room":"B105"}]'),
  ('ce_ds', 'a0000001-0000-0000-0000-000000000003', 'Y2S3', 30, 30,
   '[{"day":"TUE","start":"14:00","end":"15:30","room":"C105"},{"day":"THU","start":"14:00","end":"15:30","room":"C105"}]');

-- Electricity and Magnetism (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_em', 'a0000001-0000-0000-0000-000000000002', 'Y2S3', 35, 31,
   '[{"day":"MON","start":"10:00","end":"11:30","room":"B201"},{"day":"WED","start":"10:00","end":"11:30","room":"B201"}]'),
  ('ce_em', 'a0000001-0000-0000-0000-000000000002', 'Y2S3', 35, 28,
   '[{"day":"TUE","start":"14:00","end":"15:30","room":"B201"},{"day":"THU","start":"14:00","end":"15:30","room":"B201"}]');

-- Lab. Electricity and Magnetism (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_lab_em', 'a0000001-0000-0000-0000-000000000002', 'Y2S3', 20, 18,
   '[{"day":"FRI","start":"08:00","end":"10:00","room":"LAB-ELEC1"}]'),
  ('ce_lab_em', 'a0000001-0000-0000-0000-000000000011', 'Y2S3', 20, 16,
   '[{"day":"FRI","start":"10:00","end":"12:00","room":"LAB-ELEC1"}]');

-- Routing and Switching Essentials (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_rse', 'a0000001-0000-0000-0000-000000000005', 'Y2S3', 30, 27,
   '[{"day":"TUE","start":"10:00","end":"11:30","room":"B303"},{"day":"THU","start":"10:00","end":"11:30","room":"B303"}]'),
  ('ce_rse', 'a0000001-0000-0000-0000-000000000005', 'Y2S3', 30, 24,
   '[{"day":"MON","start":"16:00","end":"17:30","room":"B303"},{"day":"WED","start":"16:00","end":"17:30","room":"B303"}]');

-- Unix (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_unix', 'a0000001-0000-0000-0000-000000000006', 'Y2S3', 30, 25,
   '[{"day":"WED","start":"14:00","end":"15:30","room":"C201"},{"day":"FRI","start":"14:00","end":"15:30","room":"C201"}]'),
  ('ce_unix', 'a0000001-0000-0000-0000-000000000008', 'Y2S3', 30, 22,
   '[{"day":"MON","start":"08:00","end":"09:30","room":"B105"},{"day":"WED","start":"08:00","end":"09:30","room":"B105"}]');

-- Web Design (3 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_webdesign', 'a0000001-0000-0000-0000-000000000008', 'Y2S3', 30, 28,
   '[{"day":"TUE","start":"16:00","end":"17:30","room":"LAB-CS1"},{"day":"THU","start":"16:00","end":"17:30","room":"LAB-CS1"}]'),
  ('ce_webdesign', 'a0000001-0000-0000-0000-000000000004', 'Y2S3', 30, 24,
   '[{"day":"MON","start":"14:00","end":"15:30","room":"A205"},{"day":"WED","start":"14:00","end":"15:30","room":"A205"}]'),
  ('ce_webdesign', 'a0000001-0000-0000-0000-000000000008', 'Y2S3', 25, 20,
   '[{"day":"FRI","start":"10:00","end":"11:30","room":"LAB-CS1"},{"day":"FRI","start":"14:00","end":"15:30","room":"LAB-CS1"}]');

-- === YEAR 2, SEMESTER 4 ===

-- Database Design (3 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_dbdesign', 'a0000001-0000-0000-0000-000000000004', 'Y2S4', 35, 32,
   '[{"day":"MON","start":"08:00","end":"09:30","room":"A205"},{"day":"WED","start":"08:00","end":"09:30","room":"A205"}]'),
  ('ce_dbdesign', 'a0000001-0000-0000-0000-000000000004', 'Y2S4', 35, 28,
   '[{"day":"TUE","start":"10:00","end":"11:30","room":"A205"},{"day":"THU","start":"10:00","end":"11:30","room":"A205"}]'),
  ('ce_dbdesign', 'a0000001-0000-0000-0000-000000000008', 'Y2S4', 30, 25,
   '[{"day":"MON","start":"14:00","end":"15:30","room":"B105"},{"day":"WED","start":"14:00","end":"15:30","room":"B105"}]');

-- OOP I (3 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_oop1', 'a0000001-0000-0000-0000-000000000003', 'Y2S4', 35, 33,
   '[{"day":"TUE","start":"08:00","end":"09:30","room":"C105"},{"day":"THU","start":"08:00","end":"09:30","room":"C105"}]'),
  ('ce_oop1', 'a0000001-0000-0000-0000-000000000014', 'Y2S4', 35, 26,
   '[{"day":"MON","start":"10:00","end":"11:30","room":"C202"},{"day":"WED","start":"10:00","end":"11:30","room":"C202"}]'),
  ('ce_oop1', 'a0000001-0000-0000-0000-000000000003', 'Y2S4', 30, 29,
   '[{"day":"TUE","start":"14:00","end":"15:30","room":"C105"},{"day":"THU","start":"14:00","end":"15:30","room":"C105"}]');

-- Operations Research (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_or', 'a0000001-0000-0000-0000-000000000009', 'Y2S4', 35, 30,
   '[{"day":"MON","start":"10:00","end":"11:30","room":"A204"},{"day":"WED","start":"10:00","end":"11:30","room":"A204"}]'),
  ('ce_or', 'a0000001-0000-0000-0000-000000000009', 'Y2S4', 35, 27,
   '[{"day":"TUE","start":"16:00","end":"17:30","room":"A204"},{"day":"THU","start":"16:00","end":"17:30","room":"A204"}]');

-- OWC (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_owc', 'a0000001-0000-0000-0000-000000000013', 'Y2S4', 30, 26,
   '[{"day":"FRI","start":"08:00","end":"09:30","room":"B204"}]'),
  ('ce_owc', 'a0000001-0000-0000-0000-000000000013', 'Y2S4', 30, 22,
   '[{"day":"FRI","start":"10:00","end":"11:30","room":"B204"}]');

-- Probability and Statistics (3 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_probstats', 'a0000001-0000-0000-0000-000000000009', 'Y2S4', 35, 31,
   '[{"day":"TUE","start":"10:00","end":"11:30","room":"A204"},{"day":"THU","start":"10:00","end":"11:30","room":"A204"}]'),
  ('ce_probstats', 'a0000001-0000-0000-0000-000000000001', 'Y2S4', 35, 28,
   '[{"day":"MON","start":"16:00","end":"17:30","room":"A102"},{"day":"WED","start":"16:00","end":"17:30","room":"A102"}]'),
  ('ce_probstats', 'a0000001-0000-0000-0000-000000000009', 'Y2S4', 30, 24,
   '[{"day":"FRI","start":"14:00","end":"15:30","room":"A204"},{"day":"FRI","start":"16:00","end":"17:30","room":"A204"}]');

-- Scaling and Connecting Network (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_scn', 'a0000001-0000-0000-0000-000000000005', 'Y2S4', 30, 27,
   '[{"day":"TUE","start":"14:00","end":"15:30","room":"B303"},{"day":"THU","start":"14:00","end":"15:30","room":"B303"}]'),
  ('ce_scn', 'a0000001-0000-0000-0000-000000000005', 'Y2S4', 30, 23,
   '[{"day":"MON","start":"08:00","end":"09:30","room":"B303"},{"day":"WED","start":"08:00","end":"09:30","room":"B303"}]');

-- === YEAR 3, SEMESTER 5 ===

-- Database Programming (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_dbprog', 'a0000001-0000-0000-0000-000000000004', 'Y3S5', 30, 26,
   '[{"day":"MON","start":"08:00","end":"09:30","room":"A205"},{"day":"WED","start":"08:00","end":"09:30","room":"A205"}]'),
  ('ce_dbprog', 'a0000001-0000-0000-0000-000000000004', 'Y3S5', 30, 22,
   '[{"day":"TUE","start":"14:00","end":"15:30","room":"A205"},{"day":"THU","start":"14:00","end":"15:30","room":"A205"}]');

-- Fundamentals Electronics (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_fundelec', 'a0000001-0000-0000-0000-000000000011', 'Y3S5', 30, 27,
   '[{"day":"TUE","start":"10:00","end":"11:30","room":"C103"},{"day":"THU","start":"10:00","end":"11:30","room":"C103"}]'),
  ('ce_fundelec', 'a0000001-0000-0000-0000-000000000011', 'Y3S5', 30, 24,
   '[{"day":"MON","start":"14:00","end":"15:30","room":"C103"},{"day":"WED","start":"14:00","end":"15:30","room":"C103"}]');

-- OOP II (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_oop2', 'a0000001-0000-0000-0000-000000000014', 'Y3S5', 30, 28,
   '[{"day":"MON","start":"10:00","end":"11:30","room":"C202"},{"day":"WED","start":"10:00","end":"11:30","room":"C202"}]'),
  ('ce_oop2', 'a0000001-0000-0000-0000-000000000003', 'Y3S5', 30, 25,
   '[{"day":"TUE","start":"16:00","end":"17:30","room":"C105"},{"day":"THU","start":"16:00","end":"17:30","room":"C105"}]');

-- Web Programming I (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_webprog1', 'a0000001-0000-0000-0000-000000000008', 'Y3S5', 30, 27,
   '[{"day":"TUE","start":"08:00","end":"09:30","room":"LAB-CS1"},{"day":"THU","start":"08:00","end":"09:30","room":"LAB-CS1"}]'),
  ('ce_webprog1', 'a0000001-0000-0000-0000-000000000004', 'Y3S5', 30, 23,
   '[{"day":"FRI","start":"10:00","end":"11:30","room":"A205"},{"day":"FRI","start":"14:00","end":"15:30","room":"A205"}]');

-- === YEAR 3, SEMESTER 6 ===

-- Artificial Intelligence (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_ai', 'a0000001-0000-0000-0000-000000000007', 'Y3S6', 35, 33,
   '[{"day":"MON","start":"08:00","end":"09:30","room":"A301"},{"day":"WED","start":"08:00","end":"09:30","room":"A301"}]'),
  ('ce_ai', 'a0000001-0000-0000-0000-000000000007', 'Y3S6', 35, 29,
   '[{"day":"TUE","start":"10:00","end":"11:30","room":"A301"},{"day":"THU","start":"10:00","end":"11:30","room":"A301"}]');

-- Computer Architecture (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_comparch', 'a0000001-0000-0000-0000-000000000006', 'Y3S6', 35, 30,
   '[{"day":"TUE","start":"08:00","end":"09:30","room":"C201"},{"day":"THU","start":"08:00","end":"09:30","room":"C201"}]'),
  ('ce_comparch', 'a0000001-0000-0000-0000-000000000006', 'Y3S6', 35, 26,
   '[{"day":"MON","start":"14:00","end":"15:30","room":"C201"},{"day":"WED","start":"14:00","end":"15:30","room":"C201"}]');

-- Infographics (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_infographics', 'a0000001-0000-0000-0000-000000000015', 'Y3S6', 25, 22,
   '[{"day":"MON","start":"10:00","end":"11:30","room":"LAB-CAD"},{"day":"WED","start":"10:00","end":"11:30","room":"LAB-CAD"}]'),
  ('ce_infographics', 'a0000001-0000-0000-0000-000000000015', 'Y3S6', 25, 19,
   '[{"day":"FRI","start":"08:00","end":"09:30","room":"LAB-CAD"},{"day":"FRI","start":"10:00","end":"11:30","room":"LAB-CAD"}]');

-- Lab. AI (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_lab_ai', 'a0000001-0000-0000-0000-000000000007', 'Y3S6', 25, 23,
   '[{"day":"WED","start":"14:00","end":"16:00","room":"LAB-CS2"}]'),
  ('ce_lab_ai', 'a0000001-0000-0000-0000-000000000007', 'Y3S6', 25, 20,
   '[{"day":"FRI","start":"14:00","end":"16:00","room":"LAB-CS2"}]');

-- Lab. Numerical Analysis (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_lab_numanalysis', 'a0000001-0000-0000-0000-000000000010', 'Y3S6', 25, 21,
   '[{"day":"TUE","start":"14:00","end":"16:00","room":"LAB-CS1"}]'),
  ('ce_lab_numanalysis', 'a0000001-0000-0000-0000-000000000001', 'Y3S6', 25, 18,
   '[{"day":"THU","start":"14:00","end":"16:00","room":"LAB-CS1"}]');

-- Network Architecture (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_netarch', 'a0000001-0000-0000-0000-000000000005', 'Y3S6', 30, 27,
   '[{"day":"TUE","start":"16:00","end":"17:30","room":"B303"},{"day":"THU","start":"16:00","end":"17:30","room":"B303"}]'),
  ('ce_netarch', 'a0000001-0000-0000-0000-000000000005', 'Y3S6', 30, 23,
   '[{"day":"MON","start":"16:00","end":"17:30","room":"B303"},{"day":"WED","start":"16:00","end":"17:30","room":"B303"}]');

-- Proprietary Systems (2 sections)
INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_propsys', 'a0000001-0000-0000-0000-000000000012', 'Y3S6', 30, 26,
   '[{"day":"MON","start":"08:00","end":"09:30","room":"A106"},{"day":"WED","start":"08:00","end":"09:30","room":"A106"}]'),
  ('ce_propsys', 'a0000001-0000-0000-0000-000000000006', 'Y3S6', 30, 22,
   '[{"day":"TUE","start":"08:00","end":"09:30","room":"C201"},{"day":"THU","start":"08:00","end":"09:30","room":"C201"}]');

-- === YEAR 4, SEMESTER 7 ===

INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_advprog', 'a0000001-0000-0000-0000-000000000014', 'Y4S7', 30, 26,
   '[{"day":"MON","start":"08:00","end":"09:30","room":"C202"},{"day":"WED","start":"08:00","end":"09:30","room":"C202"}]'),
  ('ce_advprog', 'a0000001-0000-0000-0000-000000000003', 'Y4S7', 30, 24,
   '[{"day":"TUE","start":"10:00","end":"11:30","room":"C105"},{"day":"THU","start":"10:00","end":"11:30","room":"C105"}]');

INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_dbadmin', 'a0000001-0000-0000-0000-000000000004', 'Y4S7', 30, 25,
   '[{"day":"TUE","start":"08:00","end":"09:30","room":"A205"},{"day":"THU","start":"08:00","end":"09:30","room":"A205"}]'),
  ('ce_dbadmin', 'a0000001-0000-0000-0000-000000000004', 'Y4S7', 30, 21,
   '[{"day":"MON","start":"14:00","end":"15:30","room":"A205"},{"day":"WED","start":"14:00","end":"15:30","room":"A205"}]');

INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_devoss', 'a0000001-0000-0000-0000-000000000008', 'Y4S7', 30, 24,
   '[{"day":"MON","start":"10:00","end":"11:30","room":"B105"},{"day":"WED","start":"10:00","end":"11:30","room":"B105"}]'),
  ('ce_devoss', 'a0000001-0000-0000-0000-000000000008', 'Y4S7', 30, 20,
   '[{"day":"FRI","start":"10:00","end":"11:30","room":"B105"},{"day":"FRI","start":"14:00","end":"15:30","room":"B105"}]');

INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_infosec', 'a0000001-0000-0000-0000-000000000012', 'Y4S7', 30, 28,
   '[{"day":"TUE","start":"14:00","end":"15:30","room":"A106"},{"day":"THU","start":"14:00","end":"15:30","room":"A106"}]'),
  ('ce_infosec', 'a0000001-0000-0000-0000-000000000012', 'Y4S7', 30, 23,
   '[{"day":"MON","start":"16:00","end":"17:30","room":"A106"},{"day":"WED","start":"16:00","end":"17:30","room":"A106"}]');

INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_mmdb', 'a0000001-0000-0000-0000-000000000015', 'Y4S7', 25, 22,
   '[{"day":"TUE","start":"16:00","end":"17:30","room":"LAB-CS2"},{"day":"THU","start":"16:00","end":"17:30","room":"LAB-CS2"}]');

INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_webprog2', 'a0000001-0000-0000-0000-000000000008', 'Y4S7', 30, 27,
   '[{"day":"WED","start":"14:00","end":"15:30","room":"LAB-CS1"},{"day":"FRI","start":"08:00","end":"09:30","room":"LAB-CS1"}]'),
  ('ce_webprog2', 'a0000001-0000-0000-0000-000000000014', 'Y4S7', 30, 22,
   '[{"day":"MON","start":"08:00","end":"09:30","room":"C202"},{"day":"WED","start":"08:00","end":"09:30","room":"C202"}]');

-- === YEAR 4, SEMESTER 8 ===

INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_appos', 'a0000001-0000-0000-0000-000000000006', 'Y4S8', 30, 25,
   '[{"day":"MON","start":"10:00","end":"11:30","room":"C201"},{"day":"WED","start":"10:00","end":"11:30","room":"C201"}]'),
  ('ce_appos', 'a0000001-0000-0000-0000-000000000006', 'Y4S8', 30, 22,
   '[{"day":"TUE","start":"14:00","end":"15:30","room":"C201"},{"day":"THU","start":"14:00","end":"15:30","room":"C201"}]');

INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_netopt', 'a0000001-0000-0000-0000-000000000005', 'Y4S8', 30, 24,
   '[{"day":"TUE","start":"08:00","end":"09:30","room":"B303"},{"day":"THU","start":"08:00","end":"09:30","room":"B303"}]'),
  ('ce_netopt', 'a0000001-0000-0000-0000-000000000005', 'Y4S8', 30, 20,
   '[{"day":"MON","start":"14:00","end":"15:30","room":"B303"},{"day":"WED","start":"14:00","end":"15:30","room":"B303"}]');

-- === YEAR 5, SEMESTER 9 ===

INSERT INTO sections (course_id, professor_id, semester_code, capacity, enrolled_count, schedule) VALUES
  ('ce_econ', 'a0000001-0000-0000-0000-000000000009', 'Y5S9', 40, 35,
   '[{"day":"MON","start":"08:00","end":"09:30","room":"AMPH-A"}]'),
  ('ce_law', 'a0000001-0000-0000-0000-000000000013', 'Y5S9', 40, 33,
   '[{"day":"WED","start":"08:00","end":"09:30","room":"AMPH-A"}]');

-- ============================================================
-- Professor Reviews (3-5 per professor)
-- ============================================================

INSERT INTO professor_reviews (professor_id, student_id, rating, tags, comment) VALUES
  -- Dr. Georges Khoury
  ('a0000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000001', 5, ARRAY['clear explanations', 'approachable'], 'Best math professor. Makes algebra feel intuitive.'),
  ('a0000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000002', 4, ARRAY['clear explanations'], 'Very organized lectures. Exam difficulty is fair.'),
  ('a0000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000003', 5, ARRAY['approachable', 'practical examples'], 'Always available during office hours. Highly recommend.'),
  ('a0000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000004', 4, ARRAY['clear explanations'], 'Solid professor, explains proofs step by step.'),

  -- Prof. Nadia Haddad
  ('a0000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000001', 3, ARRAY['strict grading', 'research-focused'], 'Very knowledgeable but exams are tough. Study hard.'),
  ('a0000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000002', 4, ARRAY['engaging lectures'], 'Physics comes alive in her lectures. Challenging but rewarding.'),
  ('a0000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000005', 3, ARRAY['strict grading'], 'Fair but strict. You need to keep up with the material.'),

  -- Dr. Michel Aoun
  ('a0000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000001', 5, ARRAY['practical examples', 'lots of homework'], 'Incredible programming teacher. His industry stories are the best.'),
  ('a0000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000003', 4, ARRAY['fast-paced', 'practical examples'], 'Moves fast but the labs are very hands-on. Learned a lot.'),
  ('a0000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000004', 5, ARRAY['lots of homework', 'practical examples'], 'The homework load is real but it prepares you well for internships.'),
  ('a0000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000005', 4, ARRAY['fast-paced'], 'Great if you already know basics. Tough for beginners.'),

  -- Prof. Rima Nassar
  ('a0000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000002', 5, ARRAY['approachable', 'flexible deadlines'], 'Super helpful with database projects. Very patient.'),
  ('a0000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000003', 5, ARRAY['clear explanations', 'approachable'], 'Best professor for databases. Explains SQL like a story.'),
  ('a0000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000004', 4, ARRAY['flexible deadlines'], 'Gives reasonable deadlines and answers questions on WhatsApp.'),

  -- Dr. Antoine Sfeir
  ('a0000001-0000-0000-0000-000000000005', 'b0000001-0000-0000-0000-000000000001', 4, ARRAY['exam-heavy', 'engaging lectures'], 'Networks finally made sense. Labs are great with real Cisco gear.'),
  ('a0000001-0000-0000-0000-000000000005', 'b0000001-0000-0000-0000-000000000002', 3, ARRAY['strict grading', 'exam-heavy'], 'Good content but the exams are brutal. Memorize everything.'),
  ('a0000001-0000-0000-0000-000000000005', 'b0000001-0000-0000-0000-000000000005', 4, ARRAY['engaging lectures'], 'Really knows his stuff. Cisco cert prep is built into the course.'),

  -- Eng. Elias Daou
  ('a0000001-0000-0000-0000-000000000006', 'b0000001-0000-0000-0000-000000000001', 4, ARRAY['fast-paced', 'practical examples'], 'Brings real Intel experience to class. Very insightful.'),
  ('a0000001-0000-0000-0000-000000000006', 'b0000001-0000-0000-0000-000000000003', 3, ARRAY['fast-paced', 'lots of homework'], 'You need to be on top of everything. No room for slacking.'),
  ('a0000001-0000-0000-0000-000000000006', 'b0000001-0000-0000-0000-000000000004', 4, ARRAY['practical examples'], 'The Unix course was practical and well-structured.'),

  -- Dr. Carla Mansour
  ('a0000001-0000-0000-0000-000000000007', 'b0000001-0000-0000-0000-000000000001', 5, ARRAY['engaging lectures', 'clear explanations'], 'AI was the highlight of my degree. She makes ML accessible.'),
  ('a0000001-0000-0000-0000-000000000007', 'b0000001-0000-0000-0000-000000000002', 5, ARRAY['research-focused', 'engaging lectures'], 'Brilliant researcher who actually cares about teaching.'),
  ('a0000001-0000-0000-0000-000000000007', 'b0000001-0000-0000-0000-000000000005', 4, ARRAY['clear explanations'], 'The AI project was the most fun I had at UA.'),

  -- Eng. Marc Bechara
  ('a0000001-0000-0000-0000-000000000008', 'b0000001-0000-0000-0000-000000000002', 5, ARRAY['flexible deadlines', 'practical examples'], 'Web dev with Marc is amazing. Very modern tech stack.'),
  ('a0000001-0000-0000-0000-000000000008', 'b0000001-0000-0000-0000-000000000004', 4, ARRAY['approachable', 'practical examples'], 'Chill professor. Focuses on real-world skills over theory.'),
  ('a0000001-0000-0000-0000-000000000008', 'b0000001-0000-0000-0000-000000000005', 5, ARRAY['flexible deadlines', 'approachable'], 'Best for open-source and web. His GitHub is a goldmine.'),

  -- Dr. Hala Kassab
  ('a0000001-0000-0000-0000-000000000009', 'b0000001-0000-0000-0000-000000000001', 3, ARRAY['exam-heavy', 'strict grading'], 'Stats is hard enough already, and she makes exams harder. But you learn.'),
  ('a0000001-0000-0000-0000-000000000009', 'b0000001-0000-0000-0000-000000000003', 4, ARRAY['clear explanations'], 'Very methodical. Follow her steps and you will pass.'),
  ('a0000001-0000-0000-0000-000000000009', 'b0000001-0000-0000-0000-000000000005', 3, ARRAY['strict grading'], 'Operations Research was tough but she is fair on the curve.'),

  -- Prof. Joseph Khalil
  ('a0000001-0000-0000-0000-000000000010', 'b0000001-0000-0000-0000-000000000001', 5, ARRAY['approachable', 'clear explanations'], 'The GOAT of math at UA. Been teaching longer than most of us have been alive.'),
  ('a0000001-0000-0000-0000-000000000010', 'b0000001-0000-0000-0000-000000000002', 5, ARRAY['flexible deadlines', 'clear explanations'], 'Calculus finally clicked thanks to him. Patient and clear.'),
  ('a0000001-0000-0000-0000-000000000010', 'b0000001-0000-0000-0000-000000000004', 4, ARRAY['approachable'], 'Old school teaching style but it works. Great professor.'),

  -- Dr. Sandra Frem
  ('a0000001-0000-0000-0000-000000000011', 'b0000001-0000-0000-0000-000000000002', 4, ARRAY['lots of homework', 'practical examples'], 'Electronics labs are well organized. She follows up on every student.'),
  ('a0000001-0000-0000-0000-000000000011', 'b0000001-0000-0000-0000-000000000003', 4, ARRAY['engaging lectures'], 'Circuit analysis became fun. Never thought I would say that.'),
  ('a0000001-0000-0000-0000-000000000011', 'b0000001-0000-0000-0000-000000000005', 3, ARRAY['lots of homework'], 'Too many lab reports. But the content is solid.'),

  -- Dr. Pierre Rahal
  ('a0000001-0000-0000-0000-000000000012', 'b0000001-0000-0000-0000-000000000001', 4, ARRAY['fast-paced', 'research-focused'], 'Security course was eye-opening. Real-world case studies.'),
  ('a0000001-0000-0000-0000-000000000012', 'b0000001-0000-0000-0000-000000000004', 4, ARRAY['exam-heavy'], 'Challenging but the best security course in Lebanon.'),
  ('a0000001-0000-0000-0000-000000000012', 'b0000001-0000-0000-0000-000000000005', 3, ARRAY['fast-paced', 'exam-heavy'], 'Need strong networking background before taking his class.'),

  -- Dr. Maya Geagea
  ('a0000001-0000-0000-0000-000000000013', 'b0000001-0000-0000-0000-000000000002', 5, ARRAY['approachable', 'flexible deadlines'], 'Made OWC actually enjoyable. Great presentation feedback.'),
  ('a0000001-0000-0000-0000-000000000013', 'b0000001-0000-0000-0000-000000000003', 4, ARRAY['clear explanations'], 'Improved my technical writing significantly.'),
  ('a0000001-0000-0000-0000-000000000013', 'b0000001-0000-0000-0000-000000000004', 5, ARRAY['approachable', 'flexible deadlines'], 'Super nice and gives great feedback on reports.'),

  -- Dr. Charbel Mouawad
  ('a0000001-0000-0000-0000-000000000014', 'b0000001-0000-0000-0000-000000000001', 4, ARRAY['practical examples', 'fast-paced'], 'Advanced prog with .NET was intense but I learned so much.'),
  ('a0000001-0000-0000-0000-000000000014', 'b0000001-0000-0000-0000-000000000003', 4, ARRAY['lots of homework', 'practical examples'], 'Weekly assignments are tough but prepare you for the industry.'),
  ('a0000001-0000-0000-0000-000000000014', 'b0000001-0000-0000-0000-000000000005', 3, ARRAY['fast-paced'], 'Expects you to already know C# well. Steep learning curve.'),

  -- Dr. Layla Saad
  ('a0000001-0000-0000-0000-000000000015', 'b0000001-0000-0000-0000-000000000002', 5, ARRAY['engaging lectures', 'flexible deadlines'], 'Infographics was the most creative course. Loved it.'),
  ('a0000001-0000-0000-0000-000000000015', 'b0000001-0000-0000-0000-000000000004', 4, ARRAY['approachable'], 'Image processing was complex but she guided us well.'),
  ('a0000001-0000-0000-0000-000000000015', 'b0000001-0000-0000-0000-000000000005', 4, ARRAY['flexible deadlines', 'engaging lectures'], 'Great balance of theory and hands-on design work.');

-- ============================================================
-- Update professor rating_avg and rating_count from reviews
-- ============================================================
UPDATE professors p SET
  rating_avg = sub.avg_rating,
  rating_count = sub.cnt
FROM (
  SELECT professor_id, ROUND(AVG(rating)::numeric, 2) AS avg_rating, COUNT(*) AS cnt
  FROM professor_reviews
  GROUP BY professor_id
) sub
WHERE p.id = sub.professor_id;
