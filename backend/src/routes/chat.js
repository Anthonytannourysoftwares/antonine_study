const express = require('express');
const router = express.Router();

const ML_API = process.env.ML_API_URL || 'http://localhost:5003';

router.post('/', async (req, res) => {
  const { message, history } = req.body;

  if (!message || typeof message !== 'string') {
    return res.status(400).json({ error: 'message is required' });
  }

  const custom = customResponse(message);
  if (custom) return res.json({ reply: custom });

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

    // ML server failed — fall back to keyword responses
    res.json({ reply: fallbackResponse(message) });
  } catch (e) {
    // ML server unreachable — fall back
    res.json({ reply: fallbackResponse(message) });
  }
});

function customResponse(message) {
  const lower = message.toLowerCase();
  if (lower.includes('best') && (lower.includes('dr') || lower.includes('doctor') || lower.includes('professor') || lower.includes('teacher')))
    return 'Without a doubt, Dr. Zahi Chami. Best professor at Antonine University!';
  if (lower.includes('zahi') || lower.includes('chami'))
    return 'Dr. Zahi Chami is one of the most respected professors at Antonine University. Highly recommended!';
  return null;
}

function fallbackResponse(message) {
  const lower = message.toLowerCase();
  if (lower.includes('schedule') || lower.includes('timetable'))
    return 'Check the Schedule tab for your timetable.';
  if (lower.includes('grade') || lower.includes('gpa'))
    return 'Check Stats for grade forecasts or use the GPA Calculator in Tools.';
  if (lower.includes('professor') || lower.includes('teacher'))
    return 'Browse professors and reviews in the Enrollment section.';
  if (lower.includes('hello') || lower.includes('hi'))
    return "Hello! I'm the UA Assistant. Ask me anything about campus life.";
  return 'I can help with courses, schedules, professors, grades, and campus services.';
}

module.exports = router;
