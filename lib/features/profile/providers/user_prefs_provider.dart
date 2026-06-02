import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPrefsProvider extends ChangeNotifier {
  UserPrefsProvider(this._prefs) {
    _calorieGoal = _prefs.getDouble(_keyCalorieGoal) ?? 2000;
  }

  final SharedPreferences _prefs;
  static const _keyCalorieGoal = 'calorie_goal';

  late double _calorieGoal;
  double get calorieGoal => _calorieGoal;

  Future<void> setCalorieGoal(double value) async {
    _calorieGoal = value;
    await _prefs.setDouble(_keyCalorieGoal, value);
    notifyListeners();
  }
}