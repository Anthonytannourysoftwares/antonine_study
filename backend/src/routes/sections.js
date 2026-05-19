const { Router } = require('express');
const pool = require('../db');
const router = Router();

// GET /api/sections?course_id=&semester_code=
router.get('/', async (req, res, next) => {
  try {
    const { course_id, semester_code } = req.query;
    let query = `
      SELECT s.*, json_build_object(
        'id', p.id, 'full_name', p.full_name, 'title', p.title,
        'rating_avg', p.rating_avg, 'rating_count', p.rating_count,
        'tags', p.tags, 'email', p.email, 'office', p.office, 'bio', p.bio
      ) AS professor
      FROM sections s
      JOIN professors p ON p.id = s.professor_id
      WHERE 1=1
    `;
    const params = [];
    if (course_id) {
      params.push(course_id);
      query += ` AND s.course_id = $${params.length}`;
    }
    if (semester_code) {
      params.push(semester_code);
      query += ` AND s.semester_code = $${params.length}`;
    }
    query += ' ORDER BY s.course_id, s.created_at';
    const { rows } = await pool.query(query, params);
    res.json(rows);
  } catch (err) { next(err); }
});

// GET /api/sections/:id
router.get('/:id', async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT s.*, json_build_object(
        'id', p.id, 'full_name', p.full_name, 'title', p.title,
        'bio', p.bio, 'rating_avg', p.rating_avg, 'rating_count', p.rating_count,
        'tags', p.tags, 'email', p.email, 'office', p.office
      ) AS professor
       FROM sections s
       JOIN professors p ON p.id = s.professor_id
       WHERE s.id = $1`,
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Section not found' });
    res.json(rows[0]);
  } catch (err) { next(err); }
});

module.exports = router;
