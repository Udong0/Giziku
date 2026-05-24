import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/food_item.dart';
import '../providers/food_library_provider.dart';
import 'food_detail_screen.dart';
import 'food_edit_screen.dart';

/// READ: list of every food the user has saved.
class FoodLibraryScreen extends StatelessWidget {
  const FoodLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FoodLibraryProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koleksi Makananku'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: provider.load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addManual(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Manual'),
      ),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, FoodLibraryProvider provider) {
    if (provider.loading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(provider.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: provider.load, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }
    if (provider.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.collections_bookmark_outlined, size: 64),
              const SizedBox(height: 12),
              Text(
                'Belum ada makanan tersimpan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Pakai Scanner atau tombol "Tambah Manual" untuk mulai.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: provider.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _FoodCard(item: provider.items[i]),
      ),
    );
  }

  Future<void> _addManual(BuildContext context) async {
    final now = DateTime.now();
    final blank = FoodItem(
      id: const Uuid().v4(),
      name: '',
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      servingSize: 100,
      source: FoodSource.manual,
      createdAt: now,
      updatedAt: now,
    );
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FoodEditScreen(item: blank, isNew: true),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FoodDetailScreen(id: item.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: item.imagePath != null && File(item.imagePath!).existsSync()
                      ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
                      : Container(
                          color: scheme.surfaceContainerHighest,
                          child: const Icon(Icons.fastfood, size: 28),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.calories.toStringAsFixed(0)} kcal · '
                      '${item.servingSize.toStringAsFixed(0)} g',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Tag(item.source.label),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('d MMM yy').format(item.updatedAt),
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
