/**
 * Import course materials into Render DB.
 * Uses one connection per course with reconnect logic.
 */
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const CONN = 'postgresql://antonine:jzvsoQJgVKU26WkmtUXI6qOyK7i4Jjfe@dpg-d85k9d0js32c73alq1q0-a.oregon-postgres.render.com/antonine_study';
const COURSES_DIR = path.join(__dirname, '../courses');
const MAX_FILE_SIZE = 25 * 1024 * 1024; // 25 MB

const sleep = ms => new Promise(r => setTimeout(r, ms));

function getMimeType(filename) {
  const ext = path.extname(filename).toLowerCase();
  const map = {
    '.pdf':'application/pdf','.jpg':'image/jpeg','.jpeg':'image/jpeg',
    '.png':'image/png','.zip':'application/zip','.txt':'text/plain',
    '.docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    '.xlsx':'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    '.pptx':'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    '.ppsm':'application/vnd.ms-powerpoint.slideshow.macroEnabled.12',
    '.cs':'text/plain','.php':'text/plain','.js':'text/javascript',
    '.json':'application/json','.java':'text/plain','.c':'text/plain',
    '.m':'text/plain','.css':'text/css','.html':'text/html',
    '.xml':'application/xml','.md':'text/markdown','.log':'text/plain',
    '.mod':'text/plain','.sqlite':'application/x-sqlite3',
    '.ico':'image/x-icon','.otf':'font/otf','.ttf':'font/ttf',
    '.jar':'application/java-archive','.iml':'text/xml',
    '.ai':'application/postscript','.indd':'application/x-indesign',
    '.xsd':'application/xml',
  };
  return map[ext] || 'application/octet-stream';
}

async function connect() {
  const client = new Client({ connectionString: CONN, ssl: { rejectUnauthorized: false } });
  client.on('error', () => {}); // suppress unhandled
  await client.connect();
  return client;
}

function collectFiles(courseDir) {
  const files = [];
  function walk(dir, folderPath) {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      if (e.name.startsWith('.') || e.name === 'manifest.json') continue;
      const fp = path.join(dir, e.name);
      if (e.isDirectory()) {
        walk(fp, folderPath ? `${folderPath}/${e.name}` : e.name);
      } else {
        const stat = fs.statSync(fp);
        files.push({ fullPath: fp, folderPath: folderPath || '', name: e.name, size: stat.size });
      }
    }
  }
  walk(courseDir, '');
  return files;
}

async function main() {
  // Get already-imported file names to skip duplicates
  let client = await connect();
  const existingRes = await client.query(
    "SELECT course_id || '/' || folder_path || '/' || file_name as key FROM course_materials"
  );
  await client.end();

  const existingKeys = new Set(existingRes.rows.map(r => r.key));
  console.log(`Already in DB: ${existingKeys.size} files\n`);

  const courseIds = fs.readdirSync(COURSES_DIR, { withFileTypes: true })
    .filter(e => e.isDirectory() && e.name.startsWith('ce_'))
    .map(e => e.name)
    .sort();

  let totalNew = 0;
  const skipped = [];

  for (const courseId of courseIds) {
    const files = collectFiles(path.join(COURSES_DIR, courseId));
    const toUpload = files.filter(f => {
      if (f.size > MAX_FILE_SIZE) {
        skipped.push(`${courseId}/${f.name} (${(f.size/1024/1024).toFixed(1)}MB)`);
        return false;
      }
      const key = `${courseId}/${f.folderPath}/${f.name}`;
      return !existingKeys.has(key);
    });

    if (toUpload.length === 0) {
      console.log(`${courseId}: nothing new`);
      continue;
    }

    console.log(`${courseId}: uploading ${toUpload.length} files...`);

    for (let i = 0; i < toUpload.length; i++) {
      const f = toUpload[i];
      let retries = 3;
      while (retries > 0) {
        try {
          client = await connect();
          const data = fs.readFileSync(f.fullPath);
          await client.query(
            `INSERT INTO course_materials (course_id, folder_path, file_name, file_size, mime_type, data)
             VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT DO NOTHING`,
            [courseId, f.folderPath, f.name, f.size, getMimeType(f.name), data]
          );
          await client.end();
          totalNew++;
          process.stdout.write(`\r  ${i+1}/${toUpload.length} - ${f.name}`);
          break;
        } catch (err) {
          retries--;
          try { await client.end(); } catch(_) {}
          if (retries === 0) {
            console.log(`\n  FAILED: ${f.name} - ${err.message}`);
          } else {
            await sleep(2000);
          }
        }
      }
      // Small delay between files to be kind to Render
      await sleep(200);
    }
    console.log();
  }

  console.log(`\nDone! ${totalNew} new files imported.`);
  if (skipped.length) {
    console.log(`\nSkipped (>25MB):`);
    skipped.forEach(s => console.log(`  - ${s}`));
  }
}

main().catch(e => { console.error(e); process.exit(1); });
