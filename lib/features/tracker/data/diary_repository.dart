import '../models/diary_entry.dart';

abstract class DiaryRepository {
  Future<void> init();

  /// Untuk Firestore: collection('diary').where('dateKey', isEqualTo: dateKey)
  Future<List<DiaryEntry>> getEntriesForDate(String dateKey);

  Future<void> addEntry(DiaryEntry entry);
  Future<void> updateEntry(DiaryEntry entry);
  Future<void> deleteEntry(String id);
}