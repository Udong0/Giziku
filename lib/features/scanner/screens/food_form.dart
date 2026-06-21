import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_spacing.dart';
import '../models/food_item.dart';

class FoodDraft {
  final String name;
  final String? description;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double servingSize;
  final String? imagePath;

  const FoodDraft({
    required this.name,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    required this.imagePath,
  });
}

/// Holds controllers for the food form so screens can share the same fields.
class FoodFormController {
  FoodFormController({
    required this.name,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    this.imagePath,
  });

  factory FoodFormController.fromAnalysis(FoodAnalysis a) {
    return FoodFormController(
      name: TextEditingController(text: a.name),
      description: TextEditingController(text: a.description ?? ''),
      calories: TextEditingController(text: a.calories.toStringAsFixed(0)),
      protein: TextEditingController(text: a.protein.toStringAsFixed(1)),
      carbs: TextEditingController(text: a.carbs.toStringAsFixed(1)),
      fat: TextEditingController(text: a.fat.toStringAsFixed(1)),
      servingSize: TextEditingController(text: a.servingSize.toStringAsFixed(0)),
      imagePath: a.imagePath,
    );
  }

  factory FoodFormController.fromItem(FoodItem f) {
    return FoodFormController(
      name: TextEditingController(text: f.name),
      description: TextEditingController(text: f.description ?? ''),
      calories: TextEditingController(text: f.calories.toStringAsFixed(0)),
      protein: TextEditingController(text: f.protein.toStringAsFixed(1)),
      carbs: TextEditingController(text: f.carbs.toStringAsFixed(1)),
      fat: TextEditingController(text: f.fat.toStringAsFixed(1)),
      servingSize: TextEditingController(text: f.servingSize.toStringAsFixed(0)),
      imagePath: f.imagePath,
    );
  }

  factory FoodFormController.blank() => FoodFormController(
        name: TextEditingController(),
        description: TextEditingController(),
        calories: TextEditingController(text: '0'),
        protein: TextEditingController(text: '0'),
        carbs: TextEditingController(text: '0'),
        fat: TextEditingController(text: '0'),
        servingSize: TextEditingController(text: '100'),
      );

  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController calories;
  final TextEditingController protein;
  final TextEditingController carbs;
  final TextEditingController fat;
  final TextEditingController servingSize;
  String? imagePath;

  void dispose() {
    name.dispose();
    description.dispose();
    calories.dispose();
    protein.dispose();
    carbs.dispose();
    fat.dispose();
    servingSize.dispose();
  }

  FoodDraft? toDraft() {
    final n = name.text.trim();
    if (n.isEmpty) return null;
    double parse(TextEditingController c) =>
        double.tryParse(c.text.replaceAll(',', '.')) ?? 0;
    return FoodDraft(
      name: n,
      description: description.text.trim().isEmpty ? null : description.text.trim(),
      calories: parse(calories),
      protein: parse(protein),
      carbs: parse(carbs),
      fat: parse(fat),
      servingSize: parse(servingSize),
      imagePath: imagePath,
    );
  }
}

class FoodFormFields extends StatelessWidget {
  const FoodFormFields({super.key, required this.controller});

  final FoodFormController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller.name,
          decoration: const InputDecoration(
            labelText: 'Nama makanan',
            prefixIcon: Icon(Icons.fastfood),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        TextField(
          controller: controller.description,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Deskripsi (opsional)',
            prefixIcon: Icon(Icons.notes),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        _NumberField(
          controller: controller.servingSize,
          label: 'Porsi (gram)',
          icon: Icons.scale,
        ),
        const SizedBox(height: AppSpacing.s),
        _NumberField(
          controller: controller.calories,
          label: 'Kalori (kcal)',
          icon: Icons.local_fire_department,
        ),
        const SizedBox(height: AppSpacing.m),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.m),
        // Section header: Informasi Gizi
        Text(
          'INFORMASI GIZI',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: const Color(0xFF9E9E9E),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _NumberField(
                controller: controller.protein,
                label: 'Protein (g)',
                icon: Icons.egg_alt,
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: _NumberField(
                controller: controller.carbs,
                label: 'Karbo (g)',
                icon: Icons.rice_bowl,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        _NumberField(
          controller: controller.fat,
          label: 'Lemak (g)',
          icon: Icons.water_drop,
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}
