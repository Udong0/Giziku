import 'dart:convert';

enum FoodSource { aiImage, aiText, manual }

extension FoodSourceLabel on FoodSource {
  String get label => switch (this) {
        FoodSource.aiImage => 'AI · Foto',
        FoodSource.aiText => 'AI · Teks',
        FoodSource.manual => 'Manual',
      };
}

class FoodItem {
  final String id;
  final String name;
  final String? description;
  final double calories; // kcal per serving
  final double protein; // g
  final double carbs; // g
  final double fat; // g
  final double servingSize; // gram
  final String? imagePath; // local file path (later: Cloud Storage URL)
  final FoodSource source;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.imagePath,
  });

  FoodItem copyWith({
    String? name,
    String? description,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? servingSize,
    String? imagePath,
    FoodSource? source,
    DateTime? updatedAt,
  }) {
    return FoodItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      servingSize: servingSize ?? this.servingSize,
      imagePath: imagePath ?? this.imagePath,
      source: source ?? this.source,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'servingSize': servingSize,
        'imagePath': imagePath,
        'source': source.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        calories: (json['calories'] as num).toDouble(),
        protein: (json['protein'] as num).toDouble(),
        carbs: (json['carbs'] as num).toDouble(),
        fat: (json['fat'] as num).toDouble(),
        servingSize: (json['servingSize'] as num).toDouble(),
        imagePath: json['imagePath'] as String?,
        source: FoodSource.values.firstWhere(
          (s) => s.name == json['source'],
          orElse: () => FoodSource.manual,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  static String encodeList(List<FoodItem> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<FoodItem> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Raw AI analysis result before the user decides to save it.
class FoodAnalysis {
  final String name;
  final String? description;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double servingSize;
  final String? imagePath;
  final FoodSource source;
  final double confidence; // 0..1 — useful for UI hints

  const FoodAnalysis({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    required this.source,
    this.description,
    this.imagePath,
    this.confidence = 0.7,
  });
}
