import '../models/meal_plan.dart';

abstract class MealPlanRepository {
  Future<void> init();
  Future<List<MealPlan>> getAll();
  Future<MealPlan?> getById(String id);
  Future<void> add(MealPlan plan);
  Future<void> update(MealPlan plan);
  Future<void> delete(String id);
}
