import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/auth/providers/auth_provider.dart' as app_auth;
import 'features/planner/data/local_meal_plan_repository.dart';
import 'features/planner/data/meal_plan_repository.dart';
import 'features/planner/providers/meal_plan_provider.dart';
import 'features/planner/services/notification_service.dart';
import 'features/profile/providers/user_prefs_provider.dart';
import 'features/scanner/data/food_repository.dart';
import 'features/scanner/data/local_food_repository.dart';
import 'features/scanner/providers/food_library_provider.dart';
import 'features/scanner/services/gemini_service.dart';
import 'features/tracker/data/diary_repository.dart';
import 'features/tracker/data/firestore_diary_repository.dart';
import 'features/tracker/providers/diary_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env — muat GEMINI_API_KEY dll. Diam-diam kalau file tidak ada
  // (mis. di CI / fresh checkout).
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[main] .env tidak ditemukan — fallback ke --dart-define: $e');
  }

  // Firebase — wajib sebelum Firestore / Auth / FCM dipakai.
  await Firebase.initializeApp();

  // Notification & timezone init (skip di web — flutter_local_notifications
  // tidak support web).
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

  final DiaryRepository diaryRepo =
      FirestoreDiaryRepository(FirebaseFirestore.instance);
  await diaryRepo.init();

  // Reload diary data tiap kali user login (user baru → data baru).
  final diaryProvider = DiaryProvider(diaryRepo);
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) diaryProvider.reload();
  });

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

        // Auth
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),

        // Tracker
        Provider<DiaryRepository>.value(value: diaryRepo),
        ChangeNotifierProvider.value(value: diaryProvider),
        ChangeNotifierProvider(
          create: (_) => UserPrefsProvider(prefs),
        ),
      ],
      child: const GiziKuApp(),
    ),
  );
}
