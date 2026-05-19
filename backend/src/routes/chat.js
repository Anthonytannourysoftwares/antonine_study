const express = require('express');
const router = express.Router();

// POST /api/chat
// ML chatbot endpoint — placeholder for model integration
router.post('/', async (req, res) => {
  const { message, history } = req.body;

  if (!message || typeof message !== 'string') {
    return res.status(400).json({ error: 'message is required' });
  }

  // TODO: integrate ML model (e.g. fine-tuned LLM, RAG pipeline, or rule-based NLP)
  // For now, return a placeholder response
  const reply = generateResponse(message);

  res.json({ reply });
});

function generateResponse(message) {
  const lower = message.toLowerCase();

  // Simple keyword-based responses until ML model is connected
  if (lower.includes('schedule') || lower.includes('timetable')) {
    return 'You can view your timetable in the Schedule tab. The auto-scheduler will suggest the best study plan based on your mastery levels.';
  }
  if (lower.includes('grade') || lower.includes('gpa')) {
    return 'Check the Stats tab for grade forecasts, or use the GPA Calculator in Tools. Your grades are predicted using logistic regression based on mastery and study consistency.';
  }
  if (lower.includes('professor') || lower.includes('teacher')) {
    return 'You can browse professors and their reviews in the Enrollment section. Rate professors to help other students!';
  }
  if (lower.includes('lost') || lower.includes('found')) {
    return 'Head to Lost & Found from the home screen to report or browse lost/found items on campus.';
  }
  if (lower.includes('enroll') || lower.includes('course') || lower.includes('register')) {
    return 'Go to Enrollment to browse available sections, check professor ratings, and register for courses. The system validates time conflicts and credit limits automatically.';
  }
  if (lower.includes('hello') || lower.includes('hi') || lower.includes('hey')) {
    return 'Hello! I\'m the UA Assistant. Ask me about courses, schedules, professors, grades, or campus services.';
  }

  return 'I can help with courses, schedules, professors, grades, and campus services. What would you like to know?';
}

module.exports = router;
