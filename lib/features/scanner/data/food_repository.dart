import '../models/food_item.dart';

abstract class FoodRepository {
  Future<void> init();
  Future<List<FoodItem>> getAll();
  Future<FoodItem?> getById(String id);
  Future<void> add(FoodItem item);
  Future<void> update(FoodItem item);
  Future<void> delete(String id);
}
