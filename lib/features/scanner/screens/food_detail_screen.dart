import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/food_item.dart';
import '../providers/food_library_provider.dart';
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
      // Most likely the user just deleted it from this very screen.
      return Scaffold(
        appBar: AppBar(title: const Text('Detail')),
        body: const Center(child: Text('Makanan tidak ditemukan.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => FoodEditScreen(item: item)),
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
        padding: const EdgeInsets.all(16),
        children: [
          if (item.imagePath != null && !kIsWeb)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(item.imagePath!),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          if (item.imagePath != null) const SizedBox(height: 16),
          Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
          if (item.description != null) ...[
            const SizedBox(height: 4),
            Text(item.description!,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(label: item.source.label, icon: Icons.auto_awesome),
              _Chip(
                label:
                    'Dibuat ${DateFormat('d MMM yyyy').format(item.createdAt)}',
                icon: Icons.event,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Nutrisi per ${item.servingSize.toStringAsFixed(0)} g',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _NutritionGrid(item: item),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => FoodEditScreen(item: item)),
            ),
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context, item),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Hapus dari koleksi'),
          ),
        ],
      ),
    );
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

class _NutritionGrid extends StatelessWidget {
  const _NutritionGrid({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('Kalori', '${item.calories.toStringAsFixed(0)} kcal',
          Icons.local_fire_department),
      ('Protein', '${item.protein.toStringAsFixed(1)} g', Icons.egg_alt),
      ('Karbo', '${item.carbs.toStringAsFixed(1)} g', Icons.rice_bowl),
      ('Lemak', '${item.fat.toStringAsFixed(1)} g', Icons.water_drop),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: tiles
          .map((t) => _NutritionTile(label: t.$1, value: t.$2, icon: t.$3))
          .toList(),
    );
  }
}

class _NutritionTile extends StatelessWidget {
  const _NutritionTile({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(color: scheme.onSecondaryContainer, fontSize: 12)),
        ],
      ),
    );
  }
}
