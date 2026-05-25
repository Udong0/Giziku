import 'dart:convert';

// Shared dengan Tracker — import dari sini agar tidak duplikat.
// Jika Anggota 2 sudah buat enum ini, hapus definisi di sini dan import dari tracker.
enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeLabel on MealType {
  String get label => switch (this) {
        MealType.breakfast => 'Sarapan',
        MealType.lunch => 'Makan Siang',
        MealType.dinner => 'Makan Malam',
        MealType.snack => 'Camilan',
      };

  String get emoji => switch (this) {
        MealType.breakfast => '🌅',
        MealType.lunch => '☀️',
        MealType.dinner => '🌙',
        MealType.snack => '🍎',
      };
}

class MealPlan {
  final String id;
  final String? foodItemId;       // referensi ke FoodLibrary (nullable)
  final String? customName;       // dipakai kalau tidak refer ke library
  final DateTime scheduledAt;     // tanggal + jam reminder
  final MealType mealType;
  final bool reminderEnabled;
  final int? notificationId;      // ID dari flutter_local_notifications untuk cancel
  final DateTime createdAt;
  final DateTime updatedAt;

  const MealPlan({
    required this.id,
    required this.scheduledAt,
    required this.mealType,
    required this.createdAt,
    required this.updatedAt,
    this.foodItemId,
    this.customName,
    this.reminderEnabled = true,
    this.notificationId,
  }) : assert(
          foodItemId != null || customName != null,
          'Harus isi foodItemId atau customName',
        );

  /// Nama yang ditampilkan di UI (custom name lebih prioritas).
  String get displayName => customName ?? '(Pilih dari Library)';

  MealPlan copyWith({
    String? foodItemId,
    String? customName,
    DateTime? scheduledAt,
    MealType? mealType,
    bool? reminderEnabled,
    int? notificationId,
    DateTime? updatedAt,
    bool clearFoodItemId = false,
    bool clearCustomName = false,
    bool clearNotificationId = false,
  }) {
    return MealPlan(
      id: id,
      foodItemId: clearFoodItemId ? null : (foodItemId ?? this.foodItemId),
      customName: clearCustomName ? null : (customName ?? this.customName),
      scheduledAt: scheduledAt ?? this.scheduledAt,
      mealType: mealType ?? this.mealType,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      notificationId:
          clearNotificationId ? null : (notificationId ?? this.notificationId),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // ── Serialisasi ──────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'id': id,
        'foodItemId': foodItemId,
        'customName': customName,
        'scheduledAt': scheduledAt.toIso8601String(),
        'mealType': mealType.name,
        'reminderEnabled': reminderEnabled,
        'notificationId': notificationId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json['id'] as String,
      foodItemId: json['foodItemId'] as String?,
      customName: json['customName'] as String?,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      mealType:
          MealType.values.firstWhere((e) => e.name == json['mealType']),
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      notificationId: json['notificationId'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static String encodeList(List<MealPlan> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<MealPlan> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => MealPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
