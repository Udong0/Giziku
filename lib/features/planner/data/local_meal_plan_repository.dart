import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal_plan.dart';
import 'meal_plan_repository.dart';

/// SharedPreferences-backed repository.
///
/// Placeholder sampai tim migrasi ke Firestore — swap class ini dengan
/// `FirestoreMealPlanRepository` dan screen tidak perlu diubah sama sekali.
class LocalMealPlanRepository implements MealPlanRepository {
  LocalMealPlanRepository(this._prefs);

  static const _key = 'meal_plans_v1';

  final SharedPreferences _prefs;
  List<MealPlan> _cache = [];

  @override
  Future<void> init() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      _cache = [];
      return;
    }
    try {
      _cache = MealPlan.decodeList(raw);
    } catch (_) {
      _cache = [];
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, MealPlan.encodeList(_cache));
  }

  @override
  Future<List<MealPlan>> getAll() async {
    final sorted = [..._cache]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return sorted;
  }

  @override
  Future<MealPlan?> getById(String id) async {
    for (final plan in _cache) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  @override
  Future<void> add(MealPlan plan) async {
    _cache.add(plan);
    await _persist();
  }

  @override
  Future<void> update(MealPlan plan) async {
    final idx = _cache.indexWhere((p) => p.id == plan.id);
    if (idx != -1) {
      _cache[idx] = plan;
      await _persist();
    }
  }

  @override
  Future<void> delete(String id) async {
    _cache.removeWhere((p) => p.id == id);
    await _persist();
  }
}
