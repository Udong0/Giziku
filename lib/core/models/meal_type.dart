enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get label => switch (this) {
        MealType.breakfast => 'Sarapan',
        MealType.lunch => 'Makan Siang',
        MealType.dinner => 'Makan Malam',
        MealType.snack => 'Camilan',
      };

  String get emoji => switch (this) {
        MealType.breakfast => '🌅',
        MealType.lunch => '☀️',
        MealType.dinner => '🌙',
        MealType.snack => '🍎',
      };
}
