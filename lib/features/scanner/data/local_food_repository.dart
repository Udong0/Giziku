import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_item.dart';
import 'food_repository.dart';

/// SharedPreferences-backed repository.
///
/// Placeholder until the team wires Firestore — swap this for a
/// `FirestoreFoodRepository` and the rest of the app stays untouched.
class LocalFoodRepository implements FoodRepository {
  LocalFoodRepository(this._prefs);

  static const _key = 'food_library_v1';

  final SharedPreferences _prefs;
  List<FoodItem> _cache = [];

  @override
  Future<void> init() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      _cache = [];
      return;
    }
    try {
      _cache = FoodItem.decodeList(raw);
    } catch (_) {
      _cache = [];
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, FoodItem.encodeList(_cache));
  }

  @override
  Future<List<FoodItem>> getAll() async {
    final sorted = [..._cache]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  @override
  Future<FoodItem?> getById(String id) async {
    for (final item in _cache) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<void> add(FoodItem item) async {
    _cache = [..._cache, item];
    await _persist();
  }

  @override
  Future<void> update(FoodItem item) async {
    _cache = [
      for (final f in _cache) if (f.id == item.id) item else f,
    ];
    await _persist();
  }

  @override
  Future<void> delete(String id) async {
    _cache = _cache.where((f) => f.id != id).toList();
    await _persist();
  }
}
