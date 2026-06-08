import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPrefsProvider extends ChangeNotifier {
  UserPrefsProvider(this._prefs) {
    _calorieGoal = _prefs.getDouble(_keyCalorieGoal) ?? 2000;
    _proteinGoal = _prefs.getDouble(_keyProteinGoal) ?? 0;
    _carbsGoal   = _prefs.getDouble(_keyCarbsGoal)   ?? 0;
    _fatGoal     = _prefs.getDouble(_keyFatGoal)     ?? 0;
  }

  final SharedPreferences _prefs;
  static const _keyCalorieGoal = 'calorie_goal';
  static const _keyProteinGoal = 'protein_goal';
  static const _keyCarbsGoal   = 'carbs_goal';
  static const _keyFatGoal     = 'fat_goal';

  late double _calorieGoal;
  late double _proteinGoal;
  late double _carbsGoal;
  late double _fatGoal;

  double get calorieGoal => _calorieGoal;
  double get proteinGoal => _proteinGoal;
  double get carbsGoal   => _carbsGoal;
  double get fatGoal     => _fatGoal;

  Future<void> setCalorieGoal(double value) async {
    _calorieGoal = value;
    await _prefs.setDouble(_keyCalorieGoal, value);
    notifyListeners();
  }

  Future<void> setMacroGoals({
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    _proteinGoal = protein;
    _carbsGoal   = carbs;
    _fatGoal     = fat;
    await Future.wait([
      _prefs.setDouble(_keyProteinGoal, protein),
      _prefs.setDouble(_keyCarbsGoal, carbs),
      _prefs.setDouble(_keyFatGoal, fat),
    ]);
    notifyListeners();
  }
}