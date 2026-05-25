import 'dart:convert';

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get label => switch (this) {
        MealType.breakfast => 'Sarapan',
        MealType.lunch => 'Makan Siang',
        MealType.dinner => 'Makan Malam',
        MealType.snack => 'Camilan',
      };
}

/// Satu catatan makanan dalam jurnal harian.
///
/// Mengikuti pola INTEGRATION.md §3.1: simpan [servings] sebagai multiplier,
/// kalori dihitung on-the-fly ([caloriesPerServing] × [servings]).
/// Nutrisi disimpan sebagai snapshot per-serving agar entry manual (tanpa
/// [foodItemId]) tetap memiliki data gizi yang lengkap.
class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.foodName,
    required this.date,
    required this.mealType,
    required this.servings,
    required this.caloriesPerServing,
    required this.proteinPerServing,
    required this.carbsPerServing,
    required this.fatPerServing,
    required this.servingSizeG,
    required this.createdAt,
    required this.updatedAt,
    this.foodItemId,
  });

  final String id;
  final String? foodItemId;       // null = input manual (tidak dari library)
  final String foodName;          // snapshot nama untuk display
  final DateTime date;            // tanggal makan (jam diabaikan saat grouping)
  final MealType mealType;
  final double servings;          // multiplier porsi: 0.5, 1.0, 1.5, …
  final double caloriesPerServing;
  final double proteinPerServing;
  final double carbsPerServing;
  final double fatPerServing;
  final double servingSizeG;      // gram per 1 porsi
  final DateTime createdAt;
  final DateTime updatedAt;

  // Hitung on-the-fly — tidak disimpan ke storage.
  double get totalCalories => caloriesPerServing * servings;
  double get totalProtein => proteinPerServing * servings;
  double get totalCarbs => carbsPerServing * servings;
  double get totalFat => fatPerServing * servings;

  /// Key untuk query Firestore: `.where('dateKey', isEqualTo: dateKey)`.
  String get dateKey => dateKeyOf(date);

  static String dateKeyOf(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  DiaryEntry copyWith({
    String? foodName,
    MealType? mealType,
    double? servings,
    double? caloriesPerServing,
    double? proteinPerServing,
    double? carbsPerServing,
    double? fatPerServing,
    double? servingSizeG,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id,
      foodItemId: foodItemId,
      foodName: foodName ?? this.foodName,
      date: date,
      mealType: mealType ?? this.mealType,
      servings: servings ?? this.servings,
      caloriesPerServing: caloriesPerServing ?? this.caloriesPerServing,
      proteinPerServing: proteinPerServing ?? this.proteinPerServing,
      carbsPerServing: carbsPerServing ?? this.carbsPerServing,
      fatPerServing: fatPerServing ?? this.fatPerServing,
      servingSizeG: servingSizeG ?? this.servingSizeG,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'foodItemId': foodItemId,
        'foodName': foodName,
        'date': date.toIso8601String(),
        'mealType': mealType.name,
        'servings': servings,
        'caloriesPerServing': caloriesPerServing,
        'proteinPerServing': proteinPerServing,
        'carbsPerServing': carbsPerServing,
        'fatPerServing': fatPerServing,
        'servingSizeG': servingSizeG,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
        id: json['id'] as String,
        foodItemId: json['foodItemId'] as String?,
        foodName: json['foodName'] as String,
        date: DateTime.parse(json['date'] as String),
        mealType: MealType.values.firstWhere(
          (m) => m.name == json['mealType'],
          orElse: () => MealType.lunch,
        ),
        servings: (json['servings'] as num).toDouble(),
        caloriesPerServing: (json['caloriesPerServing'] as num).toDouble(),
        proteinPerServing: (json['proteinPerServing'] as num).toDouble(),
        carbsPerServing: (json['carbsPerServing'] as num).toDouble(),
        fatPerServing: (json['fatPerServing'] as num).toDouble(),
        servingSizeG: (json['servingSizeG'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  static String encodeList(List<DiaryEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());

  static List<DiaryEntry> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}