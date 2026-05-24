import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/food_item.dart';

/// Wraps Gemini multimodal calls and forces a structured JSON response.
///
/// Provide your API key at run time:
///   flutter run --dart-define=GEMINI_API_KEY=your_key_here
///
/// When the key is missing (or the API call fails) the service returns a
/// deterministic mock so the rest of the app stays demo-able.
class GeminiService {
  GeminiService({this.apiKey, this.modelName = 'gemini-1.5-flash'});

  factory GeminiService.fromEnvironment() {
    const key = String.fromEnvironment('GEMINI_API_KEY');
    return GeminiService(apiKey: key.isEmpty ? null : key);
  }

  final String? apiKey;
  final String modelName;

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  static const _systemPrompt = '''
You are a nutrition assistant for an Indonesian food tracking app called GiziKu.
Given a description or photo of a meal, return ONE JSON object with the schema:
{
  "name": string (short dish name, in Indonesian if applicable),
  "description": string (one short sentence),
  "serving_size_g": number (estimated grams in the depicted serving),
  "calories_kcal": number,
  "protein_g": number,
  "carbs_g": number,
  "fat_g": number,
  "confidence": number between 0 and 1
}
Return ONLY the JSON, no markdown fences, no commentary.
If the input is not food, return name "Unknown" and zeros.
''';

  Future<FoodAnalysis> analyzeText(String description) async {
    if (!isConfigured) return _mock(name: description, source: FoodSource.aiText);
    try {
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey!,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
        systemInstruction: Content.system(_systemPrompt),
      );
      final response = await model.generateContent([
        Content.text('Analyze this meal description: "$description"'),
      ]);
      return _parse(response.text ?? '', source: FoodSource.aiText);
    } catch (_) {
      return _mock(name: description, source: FoodSource.aiText);
    }
  }

  Future<FoodAnalysis> analyzeImage(File image, {String? hint}) async {
    if (!isConfigured) {
      return _mock(
        name: hint?.isNotEmpty == true ? hint! : 'Makanan dari foto',
        source: FoodSource.aiImage,
        imagePath: image.path,
      );
    }
    try {
      final bytes = await image.readAsBytes();
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey!,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
        systemInstruction: Content.system(_systemPrompt),
      );
      final prompt = hint == null || hint.isEmpty
          ? 'Identify the meal in this photo and estimate the nutrition.'
          : 'Identify the meal in this photo (user hint: "$hint") and estimate the nutrition.';
      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ]),
      ]);
      return _parse(
        response.text ?? '',
        source: FoodSource.aiImage,
        imagePath: image.path,
      );
    } catch (_) {
      return _mock(
        name: hint?.isNotEmpty == true ? hint! : 'Makanan dari foto',
        source: FoodSource.aiImage,
        imagePath: image.path,
      );
    }
  }

  FoodAnalysis _parse(
    String raw, {
    required FoodSource source,
    String? imagePath,
  }) {
    final cleaned = raw.trim().replaceAll(RegExp(r'^```(?:json)?|```$'), '').trim();
    try {
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      double num0(String k) => (json[k] as num?)?.toDouble() ?? 0;
      return FoodAnalysis(
        name: (json['name'] as String?)?.trim().isNotEmpty == true
            ? json['name'] as String
            : 'Tidak diketahui',
        description: json['description'] as String?,
        servingSize: num0('serving_size_g'),
        calories: num0('calories_kcal'),
        protein: num0('protein_g'),
        carbs: num0('carbs_g'),
        fat: num0('fat_g'),
        confidence: (json['confidence'] as num?)?.toDouble().clamp(0, 1) ?? 0.6,
        source: source,
        imagePath: imagePath,
      );
    } catch (_) {
      return _mock(name: 'Hasil tidak dapat dibaca', source: source, imagePath: imagePath);
    }
  }

  FoodAnalysis _mock({
    required String name,
    required FoodSource source,
    String? imagePath,
  }) {
    final r = Random(name.hashCode);
    final calories = 200 + r.nextInt(400);
    return FoodAnalysis(
      name: name.isEmpty ? 'Makanan' : name,
      description: 'Estimasi offline — pasang GEMINI_API_KEY untuk hasil nyata.',
      servingSize: 150 + r.nextInt(150).toDouble(),
      calories: calories.toDouble(),
      protein: 5 + r.nextInt(25).toDouble(),
      carbs: 20 + r.nextInt(50).toDouble(),
      fat: 3 + r.nextInt(20).toDouble(),
      confidence: 0.5,
      source: source,
      imagePath: imagePath,
    );
  }
}
