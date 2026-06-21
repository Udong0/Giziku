import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/nutrition_colors.dart';

import '../models/food_item.dart';
import '../providers/food_library_provider.dart';
import '../services/food_image_storage.dart';
import 'food_edit_screen.dart';

/// READ (detail) + entry point for UPDATE / DELETE.
class FoodDetailScreen extends StatelessWidget {
  const FoodDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FoodLibraryProvider>();
    final item = provider.findById(id);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail')),
        body: const Center(child: Text('Makanan tidak ditemukan.')),
      );
    }

    final hasImage = item.imagePath != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => FoodEditScreen(item: item)),
            ),
          ),
          IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, item),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.m),
        children: [
          // ── Image card or compact info row ──────────────────────────────
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildHeroImage(item),
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _InfoChip(
                    label: item.source.label,
                    icon: Icons.auto_awesome),
                _InfoChip(
                  label: 'Dibuat ${DateFormat('d MMM yyyy').format(item.createdAt)}',
                  icon: Icons.event,
                ),
              ],
            ),

          const SizedBox(height: AppSpacing.m),

          // Description
          if (item.description != null &&
              item.description!.isNotEmpty) ...[
            Text(
              item.description!,
              style: AppTheme.inter(size: 14).copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
          ],

          // Source & date chips (when image shown, show chips too)
          if (hasImage) ...[
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _InfoChip(
                    label: item.source.label,
                    icon: Icons.auto_awesome),
                _InfoChip(
                  label: 'Dibuat ${DateFormat('d MMM yyyy').format(item.createdAt)}',
                  icon: Icons.event,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
          ],

          // Nutrition grid title
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius:
                      BorderRadius.circular(AppRadius.full),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Nutrisi per ${item.servingSize.toStringAsFixed(0)} g',
                style: AppTheme.jakartaSemiBold(size: 15),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),

          // 2x2 Colored nutrition tiles
          _NutritionTileGrid(item: item),
          const SizedBox(height: AppSpacing.s),
          Center(
            child: Text(
              'Per ${item.servingSize.toStringAsFixed(0)}g sajian',
              style: AppTheme.inter(size: 12).copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
        ],
      ),
    );
  }

  Widget _buildHeroImage(FoodItem item) {
    final path = item.imagePath;
    if (path == null) return const SizedBox.shrink();

    if (FoodImageStorage.isRemoteUrl(path)) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: AppTheme.borderLight,
          child: const Icon(Icons.fastfood, size: 40),
        ),
      );
    }
    if (!kIsWeb) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: AppTheme.borderLight,
          child: const Icon(Icons.fastfood, size: 40),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _confirmDelete(BuildContext context, FoodItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus makanan?'),
        content: Text('"${item.name}" akan dihapus permanen dari koleksimu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<FoodLibraryProvider>().delete(item.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${item.name}" dihapus.')),
    );
    Navigator.of(context).pop();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2x2 colored nutrition grid
// ─────────────────────────────────────────────────────────────────────────────

class _NutritionTileGrid extends StatelessWidget {
  const _NutritionTileGrid({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final nc = NutritionColors.of(context);
    final tiles = [
      _NutritionTileData(
        label: 'Kalori',
        value: item.calories.toStringAsFixed(0),
        unit: 'kkal',
        color: nc.calorieColor,
        icon: Icons.local_fire_department_rounded,
      ),
      _NutritionTileData(
        label: 'Protein',
        value: item.protein.toStringAsFixed(1),
        unit: 'g',
        color: nc.proteinColor,
        icon: Icons.egg_alt_rounded,
      ),
      _NutritionTileData(
        label: 'Karbo',
        value: item.carbs.toStringAsFixed(1),
        unit: 'g',
        color: nc.carbsColor,
        icon: Icons.rice_bowl_rounded,
      ),
      _NutritionTileData(
        label: 'Lemak',
        value: item.fat.toStringAsFixed(1),
        unit: 'g',
        color: nc.fatColor,
        icon: Icons.water_drop_rounded,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.s,
      mainAxisSpacing: AppSpacing.s,
      childAspectRatio: 1.4,
      children: tiles.map((t) => _NutritionTile(data: t)).toList(),
    );
  }
}

class _NutritionTileData {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _NutritionTileData({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });
}

class _NutritionTile extends StatelessWidget {
  const _NutritionTile({required this.data});
  final _NutritionTileData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: data.color.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(data.icon, color: data.color, size: 18),
              const Spacer(),
              Text(
                data.unit,
                style: AppTheme.inter(size: 11).copyWith(
                  color: data.color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: AppTheme.digitStyle(size: 24).copyWith(
                  color: data.color.withValues(alpha: 0.9),
                ),
              ),
              Text(
                data.label,
                style: AppTheme.inter(size: 12).copyWith(
                  color: data.color.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info chip (source / date)
// ─────────────────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.inter(size: 12).copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
