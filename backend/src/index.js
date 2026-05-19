require('dotenv').config();
const express = require('express');
const cors = require('cors');
const pool = require('./db');
const fs = require('fs');

const healthRoute = require('./routes/health');
const professorsRoute = require('./routes/professors');
const sectionsRoute = require('./routes/sections');
const enrollmentsRoute = require('./routes/enrollments');
const reviewsRoute = require('./routes/reviews');
const chatRoute = require('./routes/chat');
const lostFoundRoute = require('./routes/lost_found');

const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

const COURSES_DIR = path.join(__dirname, '../courses');

// Browse folder tree for a course from DB (supports ?path= for subfolders)
app.get('/api/courses/:courseId/browse', async (req, res) => {
  try {
    const { courseId } = req.params;
    const subPath = req.query.path || '';

    // Get distinct subfolders at this level
    let folderQuery, fileQuery;

    if (subPath) {
      // Get folders: find distinct next-level folder names under subPath
      folderQuery = await pool.query(
        `SELECT DISTINCT
           split_part(substr(folder_path, length($2) + 2), '/', 1) AS name
         FROM course_materials
         WHERE course_id = $1
           AND folder_path LIKE $2 || '/%'
           AND split_part(substr(folder_path, length($2) + 2), '/', 1) != ''`,
        [courseId, subPath]
      );
      // Get files at this exact folder level
      fileQuery = await pool.query(
        `SELECT file_name AS name, file_size AS size
         FROM course_materials
         WHERE course_id = $1 AND folder_path = $2
         ORDER BY file_name`,
        [courseId, subPath]
      );
    } else {
      // Root level: get top-level folders
      folderQuery = await pool.query(
        `SELECT DISTINCT split_part(folder_path, '/', 1) AS name
         FROM course_materials
         WHERE course_id = $1 AND folder_path != ''`,
        [courseId]
      );
      // Get files at root level
      fileQuery = await pool.query(
        `SELECT file_name AS name, file_size AS size
         FROM course_materials
         WHERE course_id = $1 AND folder_path = ''
         ORDER BY file_name`,
        [courseId]
      );
    }

    const folders = folderQuery.rows
      .map(r => r.name)
      .filter(Boolean)
      .sort();
    const files = fileQuery.rows;

    res.json({ folders, files });
  } catch (err) {
    console.error('Browse error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Download a file from DB
app.get('/api/courses/:courseId/download', async (req, res) => {
  try {
    const { courseId } = req.params;
    const folderPath = req.query.folder || '';
    const fileName = req.query.file;

    if (!fileName) return res.status(400).json({ error: 'file is required' });

    const result = await pool.query(
      `SELECT data, mime_type, file_name
       FROM course_materials
       WHERE course_id = $1 AND folder_path = $2 AND file_name = $3`,
      [courseId, folderPath, fileName]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'File not found' });
    }

    const row = result.rows[0];
    res.setHeader('Content-Type', row.mime_type);
    res.setHeader('Content-Disposition', `inline; filename="${row.file_name}"`);
    res.send(row.data);
  } catch (err) {
    console.error('Download error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Routes
app.use('/api', healthRoute);
app.use('/api/professors', professorsRoute);
app.use('/api/sections', sectionsRoute);
app.use('/api/enrollments', enrollmentsRoute);
app.use('/api/reviews', reviewsRoute);
app.use('/api/chat', chatRoute);
app.use('/api/lost-found', lostFoundRoute);

// Error handler
app.use((err, _req, res, _next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.SERVER_PORT || 8080;

async function start() {
  try {
    const { rows } = await pool.query('SELECT NOW()');
    console.log(`Database connected: ${rows[0].now}`);
  } catch (err) {
    console.error('Database connection failed:', err.message);
    console.log('Server will start anyway — fix DB and retry.');
  }

  app.listen(PORT, '::', () => {
    console.log(`Antonine University API running on port ${PORT}`);
  });
}

start();
