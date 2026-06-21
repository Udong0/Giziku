/// Design tokens — spacing, radius, icon size.
/// Semua berbasis grid 8dp.
library;

class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs  = 8;
  static const double s   = 12;
  static const double m   = 16;
  static const double l   = 24;
  static const double xl  = 32;
}

class AppRadius {
  AppRadius._();

  static const double small      = 4;
  static const double medium     = 12;
  static const double large      = 16;
  static const double extraLarge = 24;
  static const double full       = 999;
}

class AppIconSize {
  AppIconSize._();

  static const double small  = 16;
  static const double medium = 24;
  static const double large  = 32;
}
