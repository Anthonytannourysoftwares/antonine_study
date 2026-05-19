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
  if (lower.includes('enroll') || lower.includes('register') || lower.includes('sign up'))
    return 'Go to the Enrollment screen from your subject page. Pick a section (professor + timeslot), and the system will check for time conflicts and credit limits automatically.';
  if (lower.includes('course') || lower.includes('subject') || lower.includes('class'))
    return 'You can browse all your semester courses on the Home screen. Tap any subject to see topics, course materials, flashcards, and more. Use Course Materials to download PDFs and summarize them with AI!';
  if (lower.includes('material') || lower.includes('pdf') || lower.includes('download'))
    return 'Open any subject → tap Course Materials to browse folders and files. PDFs have a sparkle icon — tap it to get an AI summary, then save it as a flashcard!';
  if (lower.includes('quiz') || lower.includes('exam') || lower.includes('test'))
    return 'The AI Helper has an adaptive quiz powered by Item Response Theory (IRT). It adjusts question difficulty based on your ability level in real-time.';
  if (lower.includes('study') || lower.includes('learn') || lower.includes('focus'))
    return 'Check Today\'s Focus on the Home screen for your 3 weakest subjects. The AI Helper gives personalized study recommendations using KNN and predicts how much time you need with linear regression.';
  if (lower.includes('lost') || lower.includes('found'))
    return 'Head to Lost & Found from the Home screen. You can report lost items with photos, browse found items, and mark items as resolved when recovered.';
  if (lower.includes('schedule') || lower.includes('timetable'))
    return 'Your weekly timetable is in the Plan tab. It auto-generates from your enrolled sections showing class times, rooms, and professors.';
  if (lower.includes('grade') || lower.includes('gpa'))
    return 'Check Stats for AI grade forecasts (logistic regression), or use the GPA Calculator in Tools to compute your semester GPA manually.';
  if (lower.includes('video') || lower.includes('summarize') || lower.includes('youtube'))
    return 'The Video Summarizer uses ML to create text summaries from YouTube videos. It uses Whisper for transcription, a trained caption model for visual analysis, and TF-IDF for extractive summarization.';
  if (lower.includes('flashcard'))
    return 'Flashcards are created from PDF summaries. Open Course Materials, tap the sparkle icon on a PDF, then tap Save. View them in the Flashcards tab on any subject page.';
  if (lower.includes('id') || lower.includes('verify') || lower.includes('scan'))
    return 'The app requires a daily ID scan to verify you\'re an Antonine student. It uses OCR (Google ML Kit) to read your ID card and checks for Antonine keywords and your student number.';
  if (lower.includes('help') || lower.includes('what can you'))
    return 'I can help with: courses, enrollment, professors, schedules, grades, study tips, course materials, video summaries, flashcards, lost & found, and ID verification. Just ask!';
  if (lower.includes('hello') || lower.includes('hi') || lower.includes('hey'))
    return 'Hello! I\'m the UA Assistant. Ask me about courses, professors, schedules, grades, or anything about campus life!';
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
