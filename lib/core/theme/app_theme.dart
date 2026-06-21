import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_spacing.dart';
import 'nutrition_colors.dart';
import 'semantic_colors.dart';

class AppTheme {
  AppTheme._();

  // ── Core Color Tokens ─────────────────────────────────────────────────────
  static const primary       = Color(0xFF10B981); // emerald-500
  static const secondary     = Color(0xFF0D9488); // teal-600
  static const tertiary      = Color(0xFF0EA5E9); // sky-500
  static const accent        = Color(0xFF84CC16); // lime-400
  static const background    = Color(0xFFF7FAF9); // tea-mint base
  static const surface       = Color(0xFFFFFFFF);
  static const charcoal      = Color(0xFF1E293B); // slate-800 — primary text
  static const textSecondary = Color(0xFF475569); // slate-600
  static const textMuted     = Color(0xFF64748B); // slate-500
  static const border        = Color(0xFFE2E8F0); // slate-200
  static const borderLight   = Color(0xFFF1F5F9); // slate-100
  static const creamyBorder  = border; // alias — keeps existing screens compiling

  // ── Gradient ──────────────────────────────────────────────────────────────
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF0D9488)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const primaryGradientVertical = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF0D9488)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static BoxDecoration gradientButtonDecoration({double radius = 28}) => BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4010B981),
            blurRadius: 16,
            offset: Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      );

  // ── Typography (Outfit + Inter) ───────────────────────────────────────────
  static TextStyle jakartaBold({double size = 16, Color? color}) =>
      GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: size, color: color ?? charcoal);

  static TextStyle jakartaSemiBold({double size = 16, Color? color}) =>
      GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: size, color: color ?? charcoal);

  static TextStyle inter({double size = 14, Color? color, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color ?? charcoal);

  static TextStyle digitStyle({double size = 16, Color? color, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.outfit(fontSize: size, fontWeight: weight, color: color ?? charcoal);

  static TextStyle sectionLabel({Color? color}) => GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: color ?? textMuted,
      );

  // ── Glass Decorations ─────────────────────────────────────────────────────

  static BoxDecoration glassPanelDecoration({double radius = 20}) => BoxDecoration(
        color: const Color(0xD1FFFFFF),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xB3FFFFFF)),
        boxShadow: const [
          BoxShadow(color: Color(0x0D10B981), blurRadius: 30, offset: Offset(0, 10), spreadRadius: -5),
          BoxShadow(color: Color(0x05000000), blurRadius: 12, offset: Offset(0, 4), spreadRadius: -2),
        ],
      );

  static BoxDecoration glassPanelHeavyDecoration({double radius = 20}) => BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0x2610B981)),
        boxShadow: const [
          BoxShadow(color: Color(0x1E0F172A), blurRadius: 40, offset: Offset(0, 20), spreadRadius: -10),
        ],
      );

  static BoxDecoration glassAccentDecoration({double radius = 16}) => BoxDecoration(
        color: const Color(0xA6FFFFFF),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xCCFFFFFF)),
      );

  static BoxDecoration glassAccentActiveDecoration({double radius = 16}) => BoxDecoration(
        color: const Color(0x1A10B981),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0x3310B981)),
      );

  static BoxDecoration heroCardDecoration = BoxDecoration(
    color: const Color(0xFFECFDF5),
    borderRadius: BorderRadius.circular(AppRadius.large),
    border: Border.all(color: const Color(0xFFA7F3D0)),
  );

  // ── Mesh Background ───────────────────────────────────────────────────────
  static const meshBackgroundDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFECFDF5), // emerald-50 top-left
        Color(0xFFF7FAF9), // base mid
        Color(0xFFF0F9FF), // sky-50 bottom-right
      ],
      stops: [0.0, 0.5, 1.0],
    ),
  );

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> get thinShadow => const [
        BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
      ];

  static List<BoxShadow> get cardShadow => const [
        BoxShadow(color: Color(0x0A10B981), blurRadius: 20, offset: Offset(0, 4), spreadRadius: -2),
        BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
      ];

  static List<BoxShadow> get floatingShadow => const [
        BoxShadow(color: Color(0x1A10B981), blurRadius: 32, offset: Offset(0, 8), spreadRadius: -4),
        BoxShadow(color: Color(0x140F172A), blurRadius: 16, offset: Offset(0, 4)),
      ];

  // ── Theme ─────────────────────────────────────────────────────────────────
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      surface: surface,
      onSurface: charcoal,
      outline: border,
      error: const Color(0xFFEF4444),
      brightness: Brightness.light,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      extensions: const [
        NutritionColors.defaultValues,
        SemanticColors.defaultValues,
      ],
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge:   jakartaBold(size: 57),
        displayMedium:  jakartaBold(size: 45),
        displaySmall:   jakartaBold(size: 36),
        headlineLarge:  jakartaBold(size: 32),
        headlineMedium: jakartaSemiBold(size: 28),
        headlineSmall:  jakartaSemiBold(size: 24),
        titleLarge:     jakartaSemiBold(size: 22),
        titleMedium:    jakartaSemiBold(size: 16),
        titleSmall:     jakartaSemiBold(size: 14),
        bodyLarge:      inter(size: 16),
        bodyMedium:     inter(size: 14),
        bodySmall:      inter(size: 12),
        labelLarge:  GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: charcoal),
        labelMedium: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: charcoal),
        labelSmall:  GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: charcoal),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xEBFFFFFF),
        foregroundColor: charcoal,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: jakartaSemiBold(size: 18),
        shape: const Border(
          bottom: BorderSide(color: Color(0x1AE2E8F0), width: 0.5),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: const Color(0xD1FFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: Color(0xB3FFFFFF)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: textMuted),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: charcoal),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: const Color(0x2010B981),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0), space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFECFDF5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFA7F3D0)),
        ),
        labelStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF065F46),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xF5FFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: jakartaSemiBold(size: 18),
        contentTextStyle: inter(size: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xF5FFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: charcoal,
        contentTextStyle: inter(size: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
