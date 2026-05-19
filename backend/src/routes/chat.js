const express = require('express');
const router = express.Router();
const pool = require('../db');

const ML_API = process.env.ML_API_URL || 'http://localhost:5003';

router.post('/', async (req, res) => {
  const { message, history } = req.body;

  if (!message || typeof message !== 'string') {
    return res.status(400).json({ error: 'message is required' });
  }

  // 1. Try agentic response (queries DB for real data)
  const agenticReply = await agenticResponse(message);
  if (agenticReply) return res.json({ reply: agenticReply });

  // 2. Try ML chatbot
  try {
    const response = await fetch(`${ML_API}/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message, history: history || '' }),
    });
    if (response.ok) {
      const data = await response.json();
      return res.json(data);
    }
  } catch (_) {}

  // 3. Fallback
  res.json({ reply: 'I can help with courses, professors, schedules, grades, lost & found, and more. Just ask!' });
});

async function agenticResponse(message) {
  const lower = message.toLowerCase();

  // --- Dr. Zahi Chami easter egg ---
  if (lower.includes('best') && (lower.includes('dr') || lower.includes('doctor') || lower.includes('professor') || lower.includes('teacher')))
    return 'Without a doubt, Dr. Zahi Chami. Best professor at Antonine University!';
  if (lower.includes('zahi') || lower.includes('chami'))
    return 'Dr. Zahi Chami is one of the most respected professors at Antonine University. Highly recommended!';

  // --- AGENTIC: Courses ---
  if (lower.includes('course') || lower.includes('subject') || lower.includes('class') || lower.includes('what do i study')) {
    try {
      const { rows } = await pool.query(
        `SELECT DISTINCT s.course_id, s.semester_code
         FROM sections s ORDER BY s.semester_code, s.course_id`
      );
      if (rows.length === 0) return 'No courses found in the database yet.';
      const bySemester = {};
      for (const r of rows) {
        if (!bySemester[r.semester_code]) bySemester[r.semester_code] = [];
        bySemester[r.semester_code].push(r.course_id.replace('ce_', '').toUpperCase());
      }
      let reply = 'Here are the available courses:\n\n';
      for (const [sem, courses] of Object.entries(bySemester)) {
        reply += `📚 ${sem}: ${courses.join(', ')}\n`;
      }
      reply += '\nAsk me about a specific course or professor for more details!';
      return reply;
    } catch (_) {}
  }

  // --- AGENTIC: Professors ---
  if (lower.includes('professor') || lower.includes('teacher') || lower.includes('dr.') || lower.includes('who teaches')) {
    try {
      const { rows } = await pool.query(
        `SELECT full_name, title, rating_avg, rating_count, office, email
         FROM professors ORDER BY rating_avg DESC NULLS LAST LIMIT 10`
      );
      if (rows.length === 0) return 'No professors found.';
      let reply = 'Here are the top-rated professors:\n\n';
      for (const p of rows) {
        const rating = p.rating_avg ? `⭐ ${p.rating_avg}/5 (${p.rating_count} reviews)` : 'No reviews yet';
        reply += `• ${p.title} ${p.full_name} — ${rating}\n  Office: ${p.office} | ${p.email}\n\n`;
      }
      return reply;
    } catch (_) {}
  }

  // --- AGENTIC: Specific professor by name ---
  const profMatch = lower.match(/(?:about|rate|review|who is)\s+(?:dr\.?|prof\.?|eng\.?)?\s*(\w+)/);
  if (profMatch) {
    const name = profMatch[1];
    try {
      const { rows } = await pool.query(
        `SELECT p.full_name, p.title, p.bio, p.rating_avg, p.rating_count, p.office, p.email, p.tags
         FROM professors p WHERE LOWER(p.full_name) LIKE $1 LIMIT 1`,
        [`%${name}%`]
      );
      if (rows.length > 0) {
        const p = rows[0];
        const { rows: reviews } = await pool.query(
          `SELECT rating, comment FROM professor_reviews WHERE professor_id = (
            SELECT id FROM professors WHERE LOWER(full_name) LIKE $1 LIMIT 1
          ) ORDER BY created_at DESC LIMIT 3`,
          [`%${name}%`]
        );
        let reply = `${p.title} ${p.full_name}\n`;
        reply += `${p.bio}\n\n`;
        reply += `⭐ Rating: ${p.rating_avg || 'N/A'}/5 (${p.rating_count || 0} reviews)\n`;
        reply += `📍 Office: ${p.office}\n`;
        reply += `📧 ${p.email}\n`;
        if (p.tags && p.tags.length) reply += `🏷️ Tags: ${p.tags.join(', ')}\n`;
        if (reviews.length > 0) {
          reply += '\nRecent reviews:\n';
          for (const r of reviews) {
            reply += `  — "${r.comment}" (${r.rating}/5)\n`;
          }
        }
        return reply;
      }
    } catch (_) {}
  }

  // --- AGENTIC: Sections for a course ---
  if (lower.includes('section') || lower.includes('when is') || lower.includes('schedule for')) {
    const courseMatch = lower.match(/(?:section|when is|schedule for)\s+(\w+)/);
    if (courseMatch) {
      const courseId = `ce_${courseMatch[1].toLowerCase()}`;
      try {
        const { rows } = await pool.query(
          `SELECT s.semester_code, s.capacity, s.enrolled_count, s.schedule,
                  p.full_name, p.title
           FROM sections s JOIN professors p ON s.professor_id = p.id
           WHERE s.course_id = $1 ORDER BY s.semester_code`,
          [courseId]
        );
        if (rows.length > 0) {
          let reply = `Sections for ${courseMatch[1].toUpperCase()}:\n\n`;
          for (const s of rows) {
            const sched = JSON.parse(s.schedule || '[]');
            const schedStr = sched.map(sl => `${sl.day} ${sl.start}-${sl.end} (${sl.room})`).join(', ');
            reply += `• ${s.title} ${s.full_name} [${s.semester_code}]\n`;
            reply += `  ${schedStr}\n`;
            reply += `  Seats: ${s.enrolled_count}/${s.capacity}\n\n`;
          }
          return reply;
        }
      } catch (_) {}
    }
  }

  // --- AGENTIC: Lost & Found ---
  if (lower.includes('lost') || lower.includes('found')) {
    try {
      const { rows } = await pool.query(
        `SELECT type, title, description, location, resolved, created_at
         FROM lost_found_items WHERE resolved = false
         ORDER BY created_at DESC LIMIT 5`
      );
      if (rows.length === 0) return 'No active lost or found items right now. You can report one from the Lost & Found screen!';
      let reply = 'Recent lost & found items:\n\n';
      for (const item of rows) {
        const ago = _timeAgo(item.created_at);
        reply += `• [${item.type.toUpperCase()}] ${item.title}`;
        if (item.location) reply += ` — 📍 ${item.location}`;
        reply += ` (${ago})\n`;
        if (item.description) reply += `  ${item.description}\n`;
        reply += '\n';
      }
      reply += 'You can report items or mark them as found from the Lost & Found screen.';
      return reply;
    } catch (_) {}
  }

  // --- AGENTIC: Reviews ---
  if (lower.includes('review') || lower.includes('rating')) {
    try {
      const { rows } = await pool.query(
        `SELECT p.full_name, p.title, p.rating_avg, p.rating_count
         FROM professors p WHERE p.rating_count > 0
         ORDER BY p.rating_avg DESC LIMIT 5`
      );
      if (rows.length > 0) {
        let reply = 'Top rated professors:\n\n';
        for (let i = 0; i < rows.length; i++) {
          const p = rows[i];
          reply += `${i + 1}. ${p.title} ${p.full_name} — ⭐ ${p.rating_avg}/5 (${p.rating_count} reviews)\n`;
        }
        return reply;
      }
    } catch (_) {}
  }

  // --- Static responses ---
  if (lower.includes('enroll') || lower.includes('register'))
    return 'Go to the Enrollment screen from your subject page. Pick a section (professor + timeslot), and the system checks for time conflicts and credit limits automatically.';
  if (lower.includes('material') || lower.includes('pdf') || lower.includes('download'))
    return 'Open any subject → tap Course Materials to browse files. PDFs have a sparkle icon — tap it for an AI summary, then save it as a flashcard!';
  if (lower.includes('quiz') || lower.includes('exam'))
    return 'The AI Helper has an adaptive quiz powered by Item Response Theory (IRT). It adjusts difficulty based on your ability level.';
  if (lower.includes('study') || lower.includes('focus'))
    return 'Check Today\'s Focus on the Home screen for your 3 weakest subjects. The AI Helper uses KNN to recommend what to study next.';
  if (lower.includes('schedule') || lower.includes('timetable'))
    return 'Your weekly timetable is in the Plan tab — auto-generated from your enrolled sections.';
  if (lower.includes('grade') || lower.includes('gpa'))
    return 'Check Stats for AI grade forecasts, or use the GPA Calculator in Tools.';
  if (lower.includes('video') || lower.includes('youtube'))
    return 'The Video Summarizer uses Whisper + a trained caption model + TF-IDF to summarize YouTube videos into text.';
  if (lower.includes('flashcard'))
    return 'Summarize a PDF with the sparkle icon, tap Save, then find it in the Flashcards tab.';
  if (lower.includes('id') || lower.includes('verify') || lower.includes('scan'))
    return 'The app requires a daily ID scan using OCR (Google ML Kit) to verify you\'re an Antonine student.';
  if (lower.includes('help') || lower.includes('what can you'))
    return 'I can look up real data for you! Try:\n• "Tell me about my courses"\n• "Who are the professors?"\n• "About Dr. Khoury"\n• "Sections for alg1"\n• "Any lost items?"\n• "Top rated professors"';
  if (lower.includes('hello') || lower.includes('hi') || lower.includes('hey'))
    return 'Hello! I\'m the UA Assistant. I can look up courses, professors, sections, reviews, and lost items from the database. Try asking me!';

  return null;
}

function _timeAgo(dateStr) {
  if (!dateStr) return '';
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  return `${Math.floor(hrs / 24)}d ago`;
}

module.exports = router;
