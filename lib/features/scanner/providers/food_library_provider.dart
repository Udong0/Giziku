import 'package:flutter/foundation.dart';

import '../data/food_repository.dart';
import '../models/food_item.dart';

class FoodLibraryProvider extends ChangeNotifier {
  FoodLibraryProvider(this._repo);

  final FoodRepository _repo;

  List<FoodItem> _items = const [];
  bool _loading = false;
  String? _error;

  List<FoodItem> get items => _items;
  bool get loading => _loading;
  String? get error => _error;
  bool get isEmpty => !_loading && _items.isEmpty;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _repo.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> add(FoodItem item) async {
    await _repo.add(item);
    await load();
  }

  Future<void> update(FoodItem item) async {
    await _repo.update(item);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }

  FoodItem? findById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }
}
