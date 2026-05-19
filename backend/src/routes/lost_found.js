const express = require('express');
const router = express.Router();
const pool = require('../db');
const { v4: uuidv4 } = require('uuid');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, '../../uploads/lost_found');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadsDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `${uuidv4()}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req, file, cb) => {
    const allowed = /\.(jpg|jpeg|png|heic|webp)$/i;
    if (allowed.test(path.extname(file.originalname))) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  },
});

// GET /api/lost-found
router.get('/', async (req, res) => {
  const { type } = req.query;
  let query = 'SELECT * FROM lost_found_items ORDER BY created_at DESC';
  const params = [];

  if (type && (type === 'lost' || type === 'found')) {
    query = 'SELECT * FROM lost_found_items WHERE type = $1 ORDER BY created_at DESC';
    params.push(type);
  }

  const { rows } = await pool.query(query, params);
  res.json({ items: rows });
});

// Serve uploaded images
router.get('/image/:filename', (req, res) => {
  const filePath = path.join(uploadsDir, req.params.filename);
  if (fs.existsSync(filePath)) {
    res.sendFile(filePath);
  } else {
    res.status(404).json({ error: 'Image not found' });
  }
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
  const imageUrl = req.file ? `/api/lost-found/image/${req.file.filename}` : null;

  const { rows } = await pool.query(
    `INSERT INTO lost_found_items (id, type, title, description, location, image_url)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [id, type, title, description || '', location || '', imageUrl]
  );

  res.status(201).json(rows[0]);
});

// DELETE /api/lost-found/:id
router.delete('/:id', async (req, res) => {
  const { id } = req.params;
  // Clean up image file
  const { rows } = await pool.query('SELECT image_url FROM lost_found_items WHERE id = $1', [id]);
  if (rows.length > 0 && rows[0].image_url) {
    const filename = rows[0].image_url.split('/').pop();
    const filePath = path.join(uploadsDir, filename);
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
  }
  await pool.query('DELETE FROM lost_found_items WHERE id = $1', [id]);
  res.json({ success: true });
});

module.exports = router;
