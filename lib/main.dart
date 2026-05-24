import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/scanner/data/food_repository.dart';
import 'features/scanner/data/local_food_repository.dart';
import 'features/scanner/providers/food_library_provider.dart';
import 'features/scanner/services/gemini_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final FoodRepository repo = LocalFoodRepository(prefs);
  await repo.init();

  final gemini = GeminiService.fromEnvironment();

  runApp(
    MultiProvider(
      providers: [
        Provider<FoodRepository>.value(value: repo),
        Provider<GeminiService>.value(value: gemini),
        ChangeNotifierProvider(
          create: (_) => FoodLibraryProvider(repo)..load(),
        ),
      ],
      child: const GiziKuApp(),
    ),
  );
}
