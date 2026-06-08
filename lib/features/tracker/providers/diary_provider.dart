import 'package:flutter/foundation.dart';

import '../data/diary_repository.dart';
import '../models/diary_entry.dart';

class DiaryProvider extends ChangeNotifier {
  DiaryProvider(this._repo) {
    loadDate(DateTime.now());
    _loadWeeklyData();
  }

  final DiaryRepository _repo;

  DateTime _selectedDate = DateTime.now();
  List<DiaryEntry> _entries = const [];
  bool _loading = false;
  String? _error;

  Map<String, double> _weeklyCalories = {};
  bool _weeklyLoading = false;

  DateTime get selectedDate => _selectedDate;
  List<DiaryEntry> get entries => _entries;
  bool get loading => _loading;
  String? get error => _error;
  String get selectedDateKey => DiaryEntry.dateKeyOf(_selectedDate);

  Map<String, double> get weeklyCalories => Map.unmodifiable(_weeklyCalories);
  bool get weeklyLoading => _weeklyLoading;

  double get totalCalories => _entries.fold(0, (s, e) => s + e.totalCalories);
  double get totalProtein  => _entries.fold(0, (s, e) => s + e.totalProtein);
  double get totalCarbs    => _entries.fold(0, (s, e) => s + e.totalCarbs);
  double get totalFat      => _entries.fold(0, (s, e) => s + e.totalFat);

  List<DiaryEntry> entriesForMeal(MealType mealType) =>
      _entries.where((e) => e.mealType == mealType).toList();

  Future<void> loadDate(DateTime date) async {
    _selectedDate = date;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _entries = await _repo.getEntriesForDate(DiaryEntry.dateKeyOf(date));
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> reload() => loadDate(_selectedDate);

  void previousDay() =>
      loadDate(_selectedDate.subtract(const Duration(days: 1)));

  void nextDay() => loadDate(_selectedDate.add(const Duration(days: 1)));

  Future<void> addEntry(DiaryEntry entry) async {
    await _repo.addEntry(entry);
    await reload();
    _loadWeeklyData();
  }

  Future<void> updateEntry(DiaryEntry entry) async {
    await _repo.updateEntry(entry);
    await reload();
    _loadWeeklyData();
  }

  Future<void> deleteEntry(String id) async {
    await _repo.deleteEntry(id);
    await reload();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    _weeklyLoading = true;
    notifyListeners();
    final today = DateTime.now();
    final map = <String, double>{};
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final key = DiaryEntry.dateKeyOf(date);
      try {
        final list = await _repo.getEntriesForDate(key);
        map[key] = list.fold(0.0, (s, e) => s + e.totalCalories);
      } catch (_) {
        map[key] = 0.0;
      }
    }
    _weeklyCalories = map;
    _weeklyLoading = false;
    notifyListeners();
  }
}