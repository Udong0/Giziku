import 'package:flutter/material.dart';

class NutritionColors extends ThemeExtension<NutritionColors> {
  const NutritionColors({
    required this.calorieColor,
    required this.proteinColor,
    required this.carbsColor,
    required this.fatColor,
  });

  final Color calorieColor;
  final Color proteinColor;
  final Color carbsColor;
  final Color fatColor;

  static const defaultValues = NutritionColors(
    calorieColor: Color(0xFFEF4444), // red-500
    proteinColor: Color(0xFF10B981), // emerald-500
    carbsColor:   Color(0xFFF59E0B), // amber-500
    fatColor:     Color(0xFF8B5CF6), // violet-500
  );

  static NutritionColors of(BuildContext context) =>
      Theme.of(context).extension<NutritionColors>() ?? defaultValues;

  @override
  NutritionColors copyWith({
    Color? calorieColor,
    Color? proteinColor,
    Color? carbsColor,
    Color? fatColor,
  }) =>
      NutritionColors(
        calorieColor: calorieColor ?? this.calorieColor,
        proteinColor: proteinColor ?? this.proteinColor,
        carbsColor:   carbsColor   ?? this.carbsColor,
        fatColor:     fatColor     ?? this.fatColor,
      );

  @override
  NutritionColors lerp(ThemeExtension<NutritionColors>? other, double t) {
    if (other is! NutritionColors) return this;
    return NutritionColors(
      calorieColor: Color.lerp(calorieColor, other.calorieColor, t)!,
      proteinColor: Color.lerp(proteinColor, other.proteinColor, t)!,
      carbsColor:   Color.lerp(carbsColor,   other.carbsColor,   t)!,
      fatColor:     Color.lerp(fatColor,     other.fatColor,     t)!,
    );
  }
}
