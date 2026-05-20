import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  const OcrResult({
    required this.fullText,
    required this.blocks,
    required this.confidence,
    this.detectedName,
    this.detectedId,
    this.isAntonineId,
  });

  final String fullText;
  final List<String> blocks;
  final double confidence;
  final String? detectedName;
  final String? detectedId;
  final bool? isAntonineId;
}

class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  // Antonine-related keywords to look for on the ID card
  static const _antonineKeywords = [
    'antonine',
    'université',
    'universite',
    'university antonine',
    'université antonine',
    'ua',
    'hadat',
    'baabda',
  ];

  // Antonine student ID format: 9-digit number (e.g. 202210138)
  static final _idPattern = RegExp(r'\b[A-Z]{0,3}\d{6,10}\b');

  // Name detection: 2-3 words, supports ALL CAPS or Title Case
  static final _namePattern = RegExp(r'^[A-Z][A-Za-z]+(?: [A-Z][A-Za-z]+){1,3}$');

  Future<OcrResult> processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognized = await _recognizer.processImage(inputImage);

    final blocks = <String>[];
    for (final block in recognized.blocks) {
      blocks.add(block.text);
    }

    final fullText = blocks.join('\n');
    final lowerText = fullText.toLowerCase();

    // Count Antonine keyword matches
    var keywordMatches = 0;
    for (final keyword in _antonineKeywords) {
      if (lowerText.contains(keyword)) {
        keywordMatches++;
      }
    }

    // Extract student ID
    final idMatch = _idPattern.firstMatch(fullText);
    final detectedId = idMatch?.group(0);

    // Extract name — check each block line for name-like patterns
    String? detectedName;
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final trimmed = line.text.trim();
        if (_namePattern.hasMatch(trimmed) &&
            !_antonineKeywords.any(
              (k) => trimmed.toLowerCase().contains(k),
            )) {
          detectedName = trimmed;
          break;
        }
      }
      if (detectedName != null) break;
    }

    // OCR confidence: keyword matches (0-1) combined with ID detection
    final keywordScore = (keywordMatches / 3).clamp(0.0, 1.0);
    final idScore = detectedId != null ? 1.0 : 0.0;
    final confidence = (keywordScore * 0.7 + idScore * 0.3).clamp(0.0, 1.0);
    final isAntonine = keywordMatches >= 2 || (keywordMatches >= 1 && detectedId != null);

    return OcrResult(
      fullText: fullText,
      blocks: blocks,
      confidence: confidence,
      detectedName: detectedName,
      detectedId: detectedId,
      isAntonineId: isAntonine,
    );
  }

  void dispose() {
    _recognizer.close();
  }
}
