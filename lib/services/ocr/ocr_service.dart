import 'dart:io';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class OcrService {
  const OcrService();

  /// Extracts text from an image at the given [imagePath].
  /// Default [language] is English ('eng').
  Future<String> extractText(String imagePath, {String language = 'eng'}) async {
    // Basic validation
    if (imagePath.isEmpty) {
      throw Exception('Image path is empty');
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Image file does not exist at: $imagePath');
    }

    try {
      final text = await FlutterTesseractOcr.extractText(
        imagePath,
        language: language,
        args: {
          "psm": "4",
          "preserve_interword_spaces": "1",
        },
      );
      
      if (text.trim().isEmpty) {
        return 'No text detected in the image.';
      }
      
      return text;
    } catch (e) {
      // Common issue: missing traineddata files in assets/tessdata
      if (e.toString().contains('tessdata')) {
        throw Exception(
          'OCR Data missing. Please ensure "$language.traineddata" is in your assets/tessdata/ folder and registered in pubspec.yaml.'
        );
      }
      throw Exception('Failed to extract text from image: $e');
    }
  }

  /// Extracts text from multiple images and joins them.
  Future<String> extractTextFromMultiple(List<String> imagePaths, {String language = 'eng'}) async {
    final StringBuffer buffer = StringBuffer();
    for (final path in imagePaths) {
      final text = await extractText(path, language: language);
      buffer.writeln(text);
      buffer.writeln('\n--- Page Break ---\n');
    }
    return buffer.toString();
  }
}
