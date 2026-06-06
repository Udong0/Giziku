import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/food_item.dart';
import 'food_repository.dart';

/// Supabase-backed food repository.
///
/// Tabel `public.food_items` (lihat SQL schema di INTEGRATION.md / setup notes).
/// Sekarang shared (RLS disabled). Migrasi ke per-user pakai Supabase Auth nanti.
class SupabaseFoodRepository implements FoodRepository {
  SupabaseFoodRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'food_items';

  @override
  Future<void> init() async {
    // Supabase client sudah di-initialize di main.dart.
    // Method ini ada untuk memenuhi kontrak FoodRepository.
  }

  @override
  Future<List<FoodItem>> getAll() async {
    final rows = await _client
        .from(_table)
        .select()
        .order('updated_at', ascending: false);
    return rows.map<FoodItem>(_fromRow).toList();
  }

  @override
  Future<FoodItem?> getById(String id) async {
    final rows = await _client.from(_table).select().eq('id', id).limit(1);
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<void> add(FoodItem item) async {
    await _client.from(_table).insert(_toRow(item));
  }

  @override
  Future<void> update(FoodItem item) async {
    await _client.from(_table).update(_toRow(item)).eq('id', item.id);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  // ── Mapping antara FoodItem (camelCase) ↔ Postgres row (snake_case) ──

  Map<String, dynamic> _toRow(FoodItem item) => {
        'id': item.id,
        'name': item.name,
        'description': item.description,
        'calories': item.calories,
        'protein': item.protein,
        'carbs': item.carbs,
        'fat': item.fat,
        'serving_size': item.servingSize,
        'image_path': item.imagePath,
        'source': item.source.name,
        'created_at': item.createdAt.toIso8601String(),
        'updated_at': item.updatedAt.toIso8601String(),
      };

  FoodItem _fromRow(Map<String, dynamic> row) => FoodItem(
        id: row['id'] as String,
        name: row['name'] as String,
        description: row['description'] as String?,
        calories: (row['calories'] as num).toDouble(),
        protein: (row['protein'] as num).toDouble(),
        carbs: (row['carbs'] as num).toDouble(),
        fat: (row['fat'] as num).toDouble(),
        servingSize: (row['serving_size'] as num).toDouble(),
        imagePath: row['image_path'] as String?,
        source: FoodSource.values.firstWhere(
          (s) => s.name == row['source'],
          orElse: () => FoodSource.manual,
        ),
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
      );
}
