const { Router } = require('express');
const pool = require('../db');
const router = Router();

// GET /api/enrollments?student_id=&semester_code=
router.get('/', async (req, res, next) => {
  try {
    const { student_id, semester_code } = req.query;
    if (!student_id) return res.status(400).json({ error: 'student_id required' });

    let query = `
      SELECT e.*,
        json_build_object(
          'id', s.id, 'course_id', s.course_id, 'professor_id', s.professor_id,
          'schedule', s.schedule, 'capacity', s.capacity, 'enrolled_count', s.enrolled_count
        ) AS section,
        json_build_object(
          'id', p.id, 'full_name', p.full_name, 'title', p.title
        ) AS professor
      FROM enrollments e
      LEFT JOIN sections s ON s.id = e.section_id
      LEFT JOIN professors p ON p.id = s.professor_id
      WHERE e.student_id = $1
    `;
    const params = [student_id];
    if (semester_code) {
      params.push(semester_code);
      query += ` AND e.semester_code = $${params.length}`;
    }
    query += ` AND e.status = 'enrolled' ORDER BY e.enrolled_at`;
    const { rows } = await pool.query(query, params);
    res.json(rows);
  } catch (err) { next(err); }
});

// POST /api/enrollments
router.post('/', async (req, res, next) => {
  try {
    const { student_id, course_id, section_id, semester_code } = req.body;
    if (!student_id || !course_id || !section_id || !semester_code) {
      return res.status(400).json({ error: 'student_id, course_id, section_id, semester_code required' });
    }

    // Validate
    const errors = await validateEnrollment(student_id, course_id, section_id, semester_code);
    if (errors.length) return res.status(422).json({ valid: false, errors });

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const { rows } = await client.query(
        `INSERT INTO enrollments (student_id, course_id, section_id, semester_code)
         VALUES ($1, $2, $3, $4) RETURNING *`,
        [student_id, course_id, section_id, semester_code]
      );

      // Increment enrolled_count
      await client.query(
        'UPDATE sections SET enrolled_count = enrolled_count + 1 WHERE id = $1',
        [section_id]
      );

      await client.query('COMMIT');
      res.status(201).json(rows[0]);
    } catch (err) {
      await client.query('ROLLBACK');
      if (err.code === '23505') {
        return res.status(409).json({ error: 'Already enrolled in this course for this semester' });
      }
      throw err;
    } finally {
      client.release();
    }
  } catch (err) { next(err); }
});

// POST /api/enrollments/validate
router.post('/validate', async (req, res, next) => {
  try {
    const { student_id, course_id, section_id, semester_code } = req.body;
    const errors = await validateEnrollment(student_id, course_id, section_id, semester_code);
    res.json({ valid: errors.length === 0, errors });
  } catch (err) { next(err); }
});

// PUT /api/enrollments/:id  (change section or status)
router.put('/:id', async (req, res, next) => {
  try {
    const { section_id, status } = req.body;
    const fields = [];
    const params = [];
    let idx = 1;

    if (section_id) {
      fields.push(`section_id = $${idx++}`);
      params.push(section_id);
    }
    if (status) {
      fields.push(`status = $${idx++}`);
      params.push(status);
    }
    if (!fields.length) return res.status(400).json({ error: 'Nothing to update' });

    params.push(req.params.id);
    const { rows } = await pool.query(
      `UPDATE enrollments SET ${fields.join(', ')} WHERE id = $${idx} RETURNING *`,
      params
    );
    if (!rows.length) return res.status(404).json({ error: 'Enrollment not found' });
    res.json(rows[0]);
  } catch (err) { next(err); }
});

// DELETE /api/enrollments/:id
router.delete('/:id', async (req, res, next) => {
  try {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Get enrollment to find section
      const { rows: enrollment } = await client.query(
        'SELECT * FROM enrollments WHERE id = $1', [req.params.id]
      );
      if (!enrollment.length) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Enrollment not found' });
      }

      await client.query('DELETE FROM enrollments WHERE id = $1', [req.params.id]);

      // Decrement enrolled_count
      if (enrollment[0].section_id) {
        await client.query(
          'UPDATE sections SET enrolled_count = GREATEST(enrolled_count - 1, 0) WHERE id = $1',
          [enrollment[0].section_id]
        );
      }

      await client.query('COMMIT');
      res.json({ deleted: true });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (err) { next(err); }
});

async function validateEnrollment(studentId, courseId, sectionId, semesterCode) {
  const errors = [];

  // 1. Check capacity
  const { rows: section } = await pool.query(
    'SELECT * FROM sections WHERE id = $1', [sectionId]
  );
  if (!section.length) {
    errors.push('Section not found');
    return errors;
  }
  if (section[0].enrolled_count >= section[0].capacity) {
    errors.push('Section is full');
  }

  // 2. Check credit cap (18 max)
  const { rows: currentEnrollments } = await pool.query(
    `SELECT e.course_id FROM enrollments e
     WHERE e.student_id = $1 AND e.semester_code = $2 AND e.status = 'enrolled'`,
    [studentId, semesterCode]
  );
  // Each course is 3 credits (default), count * 3
  const currentCredits = currentEnrollments.length * 3;
  if (currentCredits + 3 > 18) {
    errors.push('Credit cap exceeded (max 18 per semester)');
  }

  // 3. Check time conflict
  const { rows: enrolledSections } = await pool.query(
    `SELECT s.schedule, e.course_id FROM enrollments e
     JOIN sections s ON s.id = e.section_id
     WHERE e.student_id = $1 AND e.semester_code = $2 AND e.status = 'enrolled'`,
    [studentId, semesterCode]
  );

  const newSchedule = section[0].schedule || [];
  for (const enrolled of enrolledSections) {
    const existingSchedule = enrolled.schedule || [];
    for (const newSlot of newSchedule) {
      for (const existSlot of existingSchedule) {
        if (newSlot.day === existSlot.day && timesOverlap(newSlot, existSlot)) {
          errors.push(`Time conflict with ${enrolled.course_id} (${existSlot.day} ${existSlot.start}-${existSlot.end})`);
        }
      }
    }
  }

  return errors;
}

function timesOverlap(a, b) {
  const toMin = (t) => {
    const [h, m] = t.split(':').map(Number);
    return h * 60 + m;
  };
  return toMin(a.start) < toMin(b.end) && toMin(b.start) < toMin(a.end);
}

module.exports = router;
