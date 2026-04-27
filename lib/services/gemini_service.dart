import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // MAKE SURE YOUR REAL KEY IS HERE
  static const String _apiKey = 'AQ.Ab8RN6IN17RARKX5DjiUNM7ut-TeGGyqQrcCCIvmNRPasTUkPQ';

  Future<String> extractTextFromImage(Uint8List bytes) async {
    print("--- GEMINI DEBUG 1: Starting API Call ---");

    if (_apiKey.isEmpty) {
      return "Error: API Key is missing!";
    }

    try {
      print("--- GEMINI DEBUG 2: Building Model ---");
      final model = GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: _apiKey);

      final content = [
        Content.multi([
          DataPart('image/jpeg', bytes),
          TextPart(
              '''Read this handwritten list.
              Return a JSON array of objects.
              Each object must have exactly two keys: "item" and "quantity".
              Do not include categories or any other data.
              Just the item name and how many.'''),
        ])
      ];

      print("--- GEMINI DEBUG 3: Sending to Google Servers... ---");
      final response = await model.generateContent(content);

      print("--- GEMINI DEBUG 4: Success! ---");
      return response.text ?? 'No text detected';
    } catch (e) {
      // THIS IS THE MOST IMPORTANT LINE
      print("--- GEMINI FATAL ERROR: $e ---");
      return "OCR Failed: $e";
    }
  }
}