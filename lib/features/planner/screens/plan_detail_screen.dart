import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/nutrition_colors.dart';

import '../../../features/scanner/providers/food_library_provider.dart';
import '../models/meal_plan.dart';
import '../providers/meal_plan_provider.dart';
import 'plan_form_screen.dart';

class PlanDetailScreen extends StatelessWidget {
  const PlanDetailScreen({super.key, required this.plan});

  final MealPlan plan;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final library = context.watch<FoodLibraryProvider>();
    final food = plan.foodItemId != null ? library.findById(plan.foodItemId!) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Rencana'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => PlanFormScreen(plan: plan)),
              );
              if (result == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: cs.error),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.meshBackgroundDecoration,
        child: ListView(
        padding: const EdgeInsets.all(AppSpacing.m),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: AppTheme.glassPanelHeavyDecoration(radius: 16),
            child: Row(
              children: [
                Text(
                  plan.mealType.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.foodItemId != null
                            ? (food?.name ?? '⚠️ Makanan dihapus')
                            : (plan.customName ?? '-'),
                        style: AppTheme.jakartaBold(size: 16),
                      ),
                      Text(
                        plan.mealType.label,
                        style: AppTheme.inter(size: 13).copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.m),

          // Info tiles
          _InfoTile(
            icon: Icons.calendar_today_outlined,
            title: 'Tanggal',
            value: DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(plan.scheduledAt),
          ),
          _InfoTile(
            icon: Icons.access_time_outlined,
            title: 'Jam',
            value: DateFormat('HH:mm').format(plan.scheduledAt),
          ),
          _InfoTile(
            icon: plan.reminderEnabled
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            title: 'Pengingat',
            value: plan.reminderEnabled ? 'Aktif' : 'Nonaktif',
            valueColor: plan.reminderEnabled ? cs.primary : cs.outline,
          ),

          // Nutrisi dari library (jika ada)
          if (food != null) ...[
            const SizedBox(height: AppSpacing.m),
            Text('Informasi Nutrisi',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.primary,
                    )),
            const SizedBox(height: AppSpacing.xs),
            _NutritionCard(food: food),
          ],

          // Peringatan jika makanan dihapus dari library
          if (plan.foodItemId != null && food == null) ...[
            const SizedBox(height: AppSpacing.m),
            Card(
              color: cs.errorContainer,
              child: ListTile(
                leading: Icon(Icons.warning_amber_outlined, color: cs.error),
                title: Text(
                  'Makanan ini sudah dihapus dari library.',
                  style: TextStyle(color: cs.onErrorContainer),
                ),
                subtitle: Text(
                  'Edit rencana untuk memilih makanan baru.',
                  style: TextStyle(color: cs.onErrorContainer),
                ),
              ),
            ),
          ],
        ],
        ), // ListView
      ), // Container mesh
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Rencana?'),
        content: Text(
          'Rencana "${plan.displayName}" akan dihapus. '
          '${plan.reminderEnabled ? 'Pengingat notifikasi juga akan dibatalkan.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<MealPlanProvider>().delete(plan.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(title,
            style: AppTheme.inter(size: 12).copyWith(color: cs.onSurfaceVariant)),
        subtitle: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xxs),
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard({required this.food});
  final dynamic food; // FoodItem

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Builder(
          builder: (context) {
            final cs = Theme.of(context).colorScheme;
            final nc = NutritionColors.of(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Per ${food.servingSize.toStringAsFixed(0)}g',
                  style: AppTheme.inter(size: 12).copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.s),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NutriChip(label: 'Kalori', value: '${food.calories.toStringAsFixed(0)} kcal', color: nc.calorieColor),
                    _NutriChip(label: 'Protein', value: '${food.protein.toStringAsFixed(1)}g', color: nc.proteinColor),
                    _NutriChip(label: 'Karbo', value: '${food.carbs.toStringAsFixed(1)}g', color: nc.carbsColor),
                    _NutriChip(label: 'Lemak', value: '${food.fat.toStringAsFixed(1)}g', color: nc.fatColor),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NutriChip extends StatelessWidget {
  const _NutriChip({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value, style: AppTheme.digitStyle(size: 13, color: color)),
          Text(label, style: AppTheme.inter(size: 11).copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      );
}
