const express = require('express');
const router = express.Router();
const pool = require('../db');
const { v4: uuidv4 } = require('uuid');
const multer = require('multer');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
});

// GET /api/lost-found
router.get('/', async (req, res) => {
  const { type } = req.query;
  let query = `SELECT id, type, title, description, location, resolved, created_at,
               CASE WHEN image_data IS NOT NULL THEN true ELSE false END AS has_image
               FROM lost_found_items ORDER BY created_at DESC`;
  const params = [];

  if (type && (type === 'lost' || type === 'found')) {
    query = `SELECT id, type, title, description, location, resolved, created_at,
             CASE WHEN image_data IS NOT NULL THEN true ELSE false END AS has_image
             FROM lost_found_items WHERE type = $1 ORDER BY created_at DESC`;
    params.push(type);
  }

  const { rows } = await pool.query(query, params);
  // Add image_url for items that have images
  const items = rows.map(r => ({
    ...r,
    image_url: r.has_image ? `/api/lost-found/image/${r.id}` : null,
  }));
  res.json({ items });
});

// Serve image from DB
router.get('/image/:id', async (req, res) => {
  const { rows } = await pool.query(
    'SELECT image_data, image_mime FROM lost_found_items WHERE id = $1',
    [req.params.id]
  );
  if (rows.length === 0 || !rows[0].image_data) {
    return res.status(404).json({ error: 'Image not found' });
  }
  res.setHeader('Content-Type', rows[0].image_mime || 'image/jpeg');
  res.send(rows[0].image_data);
});

// POST /api/lost-found (multipart with optional image)
router.post('/', upload.single('image'), async (req, res) => {
  const { type, title, description, location } = req.body;

  if (!type || !title) {
    return res.status(400).json({ error: 'type and title are required' });
  }
  if (type !== 'lost' && type !== 'found') {
    return res.status(400).json({ error: 'type must be "lost" or "found"' });
  }

  const id = uuidv4();
  const imageData = req.file ? req.file.buffer : null;
  const imageMime = req.file ? req.file.mimetype : null;

  const { rows } = await pool.query(
    `INSERT INTO lost_found_items (id, type, title, description, location, image_data, image_mime, image_url)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     RETURNING id, type, title, description, location, resolved, created_at`,
    [id, type, title, description || '', location || '', imageData, imageMime,
     imageData ? `/api/lost-found/image/${id}` : null]
  );

  const item = rows[0];
  item.image_url = imageData ? `/api/lost-found/image/${id}` : null;
  res.status(201).json(item);
});

// PUT /api/lost-found/:id/resolve
router.put('/:id/resolve', async (req, res) => {
  const { rows } = await pool.query(
    'UPDATE lost_found_items SET resolved = true WHERE id = $1 RETURNING id, resolved',
    [req.params.id]
  );
  if (rows.length === 0) return res.status(404).json({ error: 'Item not found' });
  res.json(rows[0]);
});

// DELETE /api/lost-found/:id
router.delete('/:id', async (req, res) => {
  await pool.query('DELETE FROM lost_found_items WHERE id = $1', [req.params.id]);
  res.json({ success: true });
});

module.exports = router;
