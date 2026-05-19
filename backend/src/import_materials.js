/**
 * Import course materials from backend/courses/ into the database.
 * Usage: node src/import_materials.js
 */
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const pool = require('./db');
const mime = require('mime-types');

const COURSES_DIR = path.join(__dirname, '../courses');

function getMimeType(filename) {
  return mime.lookup(filename) || 'application/octet-stream';
}

async function importCourse(courseId) {
  const courseDir = path.join(COURSES_DIR, courseId);
  if (!fs.existsSync(courseDir) || !fs.statSync(courseDir).isDirectory()) return 0;

  let count = 0;

  async function walkDir(dir, folderPath) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });

    for (const entry of entries) {
      if (entry.name.startsWith('.') || entry.name === 'manifest.json') continue;
      const fullPath = path.join(dir, entry.name);

      if (entry.isDirectory()) {
        const subFolder = folderPath ? `${folderPath}/${entry.name}` : entry.name;
        await walkDir(fullPath, subFolder);
      } else {
        const stat = fs.statSync(fullPath);
        const data = fs.readFileSync(fullPath);
        const mimeType = getMimeType(entry.name);

        await pool.query(
          `INSERT INTO course_materials (course_id, folder_path, file_name, file_size, mime_type, data)
           VALUES ($1, $2, $3, $4, $5, $6)
           ON CONFLICT DO NOTHING`,
          [courseId, folderPath || '', entry.name, stat.size, mimeType, data]
        );
        count++;
        process.stdout.write(`\r  ${courseId}: ${count} files imported`);
      }
    }
  }

  await walkDir(courseDir, '');
  console.log(); // newline after progress
  return count;
}

async function main() {
  // Create table if not exists
  const schemaSql = fs.readFileSync(
    path.join(__dirname, '../sql/004_course_materials.sql'),
    'utf8'
  );
  await pool.query(schemaSql);
  console.log('Table course_materials ready.');

  // Clear existing data
  await pool.query('DELETE FROM course_materials');
  console.log('Cleared existing materials.');

  // Find all course directories
  const entries = fs.readdirSync(COURSES_DIR, { withFileTypes: true });
  const courseIds = entries
    .filter(e => e.isDirectory() && e.name.startsWith('ce_'))
    .map(e => e.name);

  console.log(`Found ${courseIds.length} courses to import.\n`);

  let total = 0;
  for (const courseId of courseIds.sort()) {
    const count = await importCourse(courseId);
    total += count;
  }

  console.log(`\nDone! Imported ${total} files total.`);
  await pool.end();
}

main().catch(err => {
  console.error('Import failed:', err);
  process.exit(1);
});
