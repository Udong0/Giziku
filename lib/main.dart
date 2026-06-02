import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/auth/providers/auth_provider.dart' as app_auth;
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

  // Firebase
  await Firebase.initializeApp();

  // Shared preferences
  final prefs = await SharedPreferences.getInstance();

  // Repositories
  final FoodRepository foodRepo = LocalFoodRepository(prefs);
  await foodRepo.init();

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