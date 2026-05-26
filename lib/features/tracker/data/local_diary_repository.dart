import 'package:shared_preferences/shared_preferences.dart';

import '../models/diary_entry.dart';
import 'diary_repository.dart';

/// SharedPreferences-backed diary repository.
///
/// Placeholder sampai tim migrasi ke Firestore — cukup bikin
/// FirestoreDiaryRepository implements DiaryRepository dan swap di main.dart.
/// Screen tidak perlu diubah sama sekali (lihat INTEGRATION.md §5).
class LocalDiaryRepository implements DiaryRepository {
  LocalDiaryRepository(this._prefs);

  static const _key = 'diary_entries_v1';

  final SharedPreferences _prefs;
  List<DiaryEntry> _cache = [];

  @override
  Future<void> init() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      _cache = [];
      return;
    }
    try {
      _cache = DiaryEntry.decodeList(raw);
    } catch (_) {
      _cache = [];
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, DiaryEntry.encodeList(_cache));
  }

  @override
  Future<List<DiaryEntry>> getEntriesForDate(String dateKey) async {
    return _cache.where((e) => e.dateKey == dateKey).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<void> addEntry(DiaryEntry entry) async {
    _cache = [..._cache, entry];
    await _persist();
  }

  @override
  Future<void> updateEntry(DiaryEntry entry) async {
    _cache = [
      for (final e in _cache) if (e.id == entry.id) entry else e,
    ];
    await _persist();
  }

  @override
  Future<void> deleteEntry(String id) async {
    _cache = _cache.where((e) => e.id != id).toList();
    await _persist();
  }
}
