import 'package:flutter/material.dart';

class SemanticColors extends ThemeExtension<SemanticColors> {
  const SemanticColors({
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  static const defaultValues = SemanticColors(
    success: Color(0xFF059669), // emerald-600
    warning: Color(0xFFF59E0B), // amber-500
    error:   Color(0xFFEF4444), // red-500
    info:    Color(0xFF0EA5E9), // sky-500
  );

  static SemanticColors of(BuildContext context) =>
      Theme.of(context).extension<SemanticColors>() ?? defaultValues;

  @override
  SemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
  }) =>
      SemanticColors(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        error:   error   ?? this.error,
        info:    info    ?? this.info,
      );

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error:   Color.lerp(error,   other.error,   t)!,
      info:    Color.lerp(info,    other.info,    t)!,
    );
  }
}
