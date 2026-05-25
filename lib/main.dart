import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/scanner/data/food_repository.dart';
import 'features/scanner/data/local_food_repository.dart';
import 'features/scanner/providers/food_library_provider.dart';
import 'features/scanner/services/gemini_service.dart';
import 'features/tracker/data/diary_repository.dart';
import 'features/tracker/data/local_diary_repository.dart';
import 'features/tracker/providers/diary_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final FoodRepository foodRepo = LocalFoodRepository(prefs);
  await foodRepo.init();

  final DiaryRepository diaryRepo = LocalDiaryRepository(prefs);
  await diaryRepo.init();

  final gemini = GeminiService.fromEnvironment();

  runApp(
    MultiProvider(
      providers: [
        Provider<FoodRepository>.value(value: foodRepo),
        Provider<GeminiService>.value(value: gemini),
        ChangeNotifierProvider(
          create: (_) => FoodLibraryProvider(foodRepo)..load(),
        ),
        Provider<DiaryRepository>.value(value: diaryRepo),
        ChangeNotifierProvider(
          create: (_) => DiaryProvider(diaryRepo),
        ),
      ],
      child: const GiziKuApp(),
    ),
  );
}
