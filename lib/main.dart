import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/planner/data/local_meal_plan_repository.dart';
import 'features/planner/data/meal_plan_repository.dart';
import 'features/planner/providers/meal_plan_provider.dart';
import 'features/planner/services/notification_service.dart';
import 'features/scanner/data/food_repository.dart';
import 'features/scanner/data/local_food_repository.dart';
import 'features/scanner/providers/food_library_provider.dart';
import 'features/scanner/services/gemini_service.dart';
import 'features/tracker/data/diary_repository.dart';
import 'features/tracker/data/local_diary_repository.dart';
import 'features/tracker/providers/diary_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Notification & timezone init
  // Harus sebelum runApp agar timezone sudah siap saat pertama build.
  // flutter_local_notifications tidak support web — skip di Chrome.
  if (!kIsWeb) {
    await NotificationService.instance.initialize();
  }

  // Shared preferences
  final prefs = await SharedPreferences.getInstance();

  // Repositories
  final FoodRepository foodRepo = LocalFoodRepository(prefs);
  await foodRepo.init();

  final MealPlanRepository mealPlanRepo = LocalMealPlanRepository(prefs);
  await mealPlanRepo.init();

  final DiaryRepository diaryRepo = LocalDiaryRepository(prefs);
  await diaryRepo.init();

  // Services
  final gemini = GeminiService.fromEnvironment();

  // Run
  runApp(
    MultiProvider(
      providers: [
        // Scanner
        Provider<FoodRepository>.value(value: foodRepo),
        Provider<GeminiService>.value(value: gemini),
        ChangeNotifierProvider(
          create: (_) => FoodLibraryProvider(foodRepo)..load(),
        ),

        // Planner + Reminder
        Provider<MealPlanRepository>.value(value: mealPlanRepo),
        ChangeNotifierProvider(
          create: (_) => MealPlanProvider(mealPlanRepo)..load(),
        ),
        // Tracker
        Provider<DiaryRepository>.value(value: diaryRepo),
        ChangeNotifierProvider(
          create: (_) => DiaryProvider(diaryRepo),
        ),
      ],
      child: const GiziKuApp(),
    ),
  );
}
