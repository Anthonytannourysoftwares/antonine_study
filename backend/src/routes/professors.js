const { Router } = require('express');
const pool = require('../db');
const router = Router();

// GET /api/professors?faculty_id=
router.get('/', async (req, res, next) => {
  try {
    const { faculty_id } = req.query;
    let query = 'SELECT * FROM professors';
    const params = [];
    if (faculty_id) {
      query += ' WHERE faculty_id = $1';
      params.push(faculty_id);
    }
    query += ' ORDER BY full_name';
    const { rows } = await pool.query(query, params);
    res.json(rows);
  } catch (err) { next(err); }
});

// GET /api/professors/:id
router.get('/:id', async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT p.*,
        COALESCE(json_agg(json_build_object(
          'id', r.id, 'rating', r.rating, 'tags', r.tags,
          'comment', r.comment, 'created_at', r.created_at
        )) FILTER (WHERE r.id IS NOT NULL), '[]') AS reviews
       FROM professors p
       LEFT JOIN professor_reviews r ON r.professor_id = p.id
       WHERE p.id = $1
       GROUP BY p.id`,
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Professor not found' });
    res.json(rows[0]);
  } catch (err) { next(err); }
});

module.exports = router;
