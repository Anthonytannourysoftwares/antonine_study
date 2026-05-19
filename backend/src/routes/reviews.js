const { Router } = require('express');
const pool = require('../db');
const router = Router();

// GET /api/reviews?professor_id=
router.get('/', async (req, res, next) => {
  try {
    const { professor_id } = req.query;
    if (!professor_id) return res.status(400).json({ error: 'professor_id required' });
    const { rows } = await pool.query(
      'SELECT * FROM professor_reviews WHERE professor_id = $1 ORDER BY created_at DESC',
      [professor_id]
    );
    res.json(rows);
  } catch (err) { next(err); }
});

// POST /api/reviews
router.post('/', async (req, res, next) => {
  try {
    const { professor_id, student_id, rating, tags, comment } = req.body;
    if (!professor_id || !student_id || !rating) {
      return res.status(400).json({ error: 'professor_id, student_id, rating required' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const { rows } = await client.query(
        `INSERT INTO professor_reviews (professor_id, student_id, rating, tags, comment)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (professor_id, student_id)
         DO UPDATE SET rating = $3, tags = $4, comment = $5, created_at = NOW()
         RETURNING *`,
        [professor_id, student_id, rating, tags || [], comment]
      );

      // Recompute professor rating
      await client.query(
        `UPDATE professors SET
           rating_avg = (SELECT COALESCE(AVG(rating), 0) FROM professor_reviews WHERE professor_id = $1),
           rating_count = (SELECT COUNT(*) FROM professor_reviews WHERE professor_id = $1)
         WHERE id = $1`,
        [professor_id]
      );

      await client.query('COMMIT');
      res.status(201).json(rows[0]);
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (err) { next(err); }
});

module.exports = router;
