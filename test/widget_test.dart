import 'package:flutter_test/flutter_test.dart';

import 'package:giziku1/features/scanner/models/food_item.dart';

void main() {
  test('FoodItem round-trips through JSON', () {
    final now = DateTime.parse('2026-05-24T10:00:00.000Z');
    final item = FoodItem(
      id: 'abc',
      name: 'Nasi Goreng',
      description: 'Sample',
      calories: 450,
      protein: 12,
      carbs: 60,
      fat: 15,
      servingSize: 250,
      source: FoodSource.aiText,
      createdAt: now,
      updatedAt: now,
    );

    final encoded = FoodItem.encodeList([item]);
    final decoded = FoodItem.decodeList(encoded).single;

    expect(decoded.id, item.id);
    expect(decoded.name, item.name);
    expect(decoded.calories, item.calories);
    expect(decoded.source, FoodSource.aiText);
  });
}
