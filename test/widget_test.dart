import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:giziku1/features/planner/models/meal_plan.dart';
import 'package:giziku1/features/planner/providers/meal_plan_provider.dart';
import 'package:giziku1/features/planner/screens/planner_screen.dart';
import 'package:giziku1/features/scanner/providers/food_library_provider.dart';

// ── Fake implementations untuk test ─────────────────────────────
import 'package:giziku1/features/planner/data/meal_plan_repository.dart';
import 'package:giziku1/features/scanner/data/food_repository.dart';
import 'package:giziku1/features/scanner/models/food_item.dart';

class _FakeMealPlanRepo implements MealPlanRepository {
  final List<MealPlan> _store = [];

  @override
  Future<void> init() async {}
  @override
  Future<List<MealPlan>> getAll() async => List.unmodifiable(_store);
  @override
  Future<MealPlan?> getById(String id) async =>
      _store.cast<MealPlan?>().firstWhere((p) => p?.id == id, orElse: () => null);
  @override
  Future<void> add(MealPlan plan) async => _store.add(plan);
  @override
  Future<void> update(MealPlan plan) async {
    final i = _store.indexWhere((p) => p.id == plan.id);
    if (i != -1) _store[i] = plan;
  }
  @override
  Future<void> delete(String id) async => _store.removeWhere((p) => p.id == id);
}

class _FakeFoodRepo implements FoodRepository {
  @override
  Future<void> init() async {}
  @override
  Future<List<FoodItem>> getAll() async => [];
  @override
  Future<FoodItem?> getById(String id) async => null;
  @override
  Future<void> add(FoodItem item) async {}
  @override
  Future<void> update(FoodItem item) async {}
  @override
  Future<void> delete(String id) async {}
}

Widget _buildUnderTest({Widget? child}) {
  final mealRepo = _FakeMealPlanRepo();
  final foodRepo = _FakeFoodRepo();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
          create: (_) => MealPlanProvider(mealRepo)..load()),
      ChangeNotifierProvider(
          create: (_) => FoodLibraryProvider(foodRepo)..load()),
    ],
    child: MaterialApp(home: child ?? const PlannerScreen()),
  );
}

void main() {
  testWidgets('PlannerScreen menampilkan empty state saat tidak ada rencana', (tester) async {
    await tester.pumpWidget(_buildUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Belum ada rencana makan'), findsOneWidget);
    expect(find.text('Tambah Rencana'), findsOneWidget); // FAB label
  });

  testWidgets('PlannerScreen memiliki FloatingActionButton', (tester) async {
    await tester.pumpWidget(_buildUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  test('MealPlan serialisasi round-trip', () {
    final now = DateTime(2025, 6, 1, 12, 0);
    final plan = MealPlan(
      id: 'test-id',
      customName: 'Nasi Goreng',
      scheduledAt: now,
      mealType: MealType.lunch,
      reminderEnabled: true,
      createdAt: now,
      updatedAt: now,
    );

    final encoded = MealPlan.encodeList([plan]);
    final decoded = MealPlan.decodeList(encoded);

    expect(decoded.length, 1);
    expect(decoded.first.id, plan.id);
    expect(decoded.first.customName, plan.customName);
    expect(decoded.first.mealType, plan.mealType);
    expect(decoded.first.scheduledAt, plan.scheduledAt);
  });

  test('MealType label dan emoji tidak kosong', () {
    for (final type in MealType.values) {
      expect(type.label.isNotEmpty, isTrue);
      expect(type.emoji.isNotEmpty, isTrue);
    }
  });

  test('MealPlanProvider plansForDate mengembalikan filter yang benar', () async {
    final repo = _FakeMealPlanRepo();
    final today = DateTime(2025, 6, 1, 12, 0);
    final tomorrow = DateTime(2025, 6, 2, 8, 0);

    await repo.add(MealPlan(
      id: '1',
      customName: 'Sarapan Hari Ini',
      scheduledAt: today,
      mealType: MealType.breakfast,
      createdAt: today,
      updatedAt: today,
    ));
    await repo.add(MealPlan(
      id: '2',
      customName: 'Besok',
      scheduledAt: tomorrow,
      mealType: MealType.lunch,
      createdAt: today,
      updatedAt: today,
    ));

    final provider = MealPlanProvider(repo);
    await provider.load();

    expect(provider.plansForDate(today).length, 1);
    expect(provider.plansForDate(today).first.id, '1');
    expect(provider.plansForDate(tomorrow).length, 1);
    expect(provider.distinctDates.length, 2);
  });
}
