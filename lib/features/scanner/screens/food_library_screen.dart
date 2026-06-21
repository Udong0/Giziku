import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/semantic_colors.dart';

import '../models/food_item.dart';
import '../providers/food_library_provider.dart';
import '../services/food_image_storage.dart';
import 'food_detail_screen.dart';
import 'food_edit_screen.dart';

/// READ: list of every food the user has saved.
class FoodLibraryScreen extends StatefulWidget {
  const FoodLibraryScreen({super.key});

  @override
  State<FoodLibraryScreen> createState() => _FoodLibraryScreenState();
}

class _FoodLibraryScreenState extends State<FoodLibraryScreen> {
  String _searchQuery = '';

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
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Tambah Manual', style: AppTheme.inter(size: 14).copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Container(
        decoration: AppTheme.meshBackgroundDecoration,
        child: _buildBody(context, provider),
      ),
    );
  }

  Widget _buildBody(BuildContext context, FoodLibraryProvider provider) {
    if (provider.loading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: SemanticColors.of(context).error.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline,
                    size: 40, color: SemanticColors.of(context).error),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: AppTheme.inter(size: 14),
              ),
              const SizedBox(height: AppSpacing.s),
              FilledButton(
                onPressed: provider.load,
                style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (provider.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.l),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.collections_bookmark_outlined,
                  size: 48,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                'Belum ada makanan tersimpan',
                style: AppTheme.jakartaSemiBold(size: 16),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Pakai Scanner atau tombol "Tambah Manual" untuk mulai.',
                textAlign: TextAlign.center,
                style: AppTheme.inter(size: 13).copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              FilledButton.icon(
                onPressed: () => _addManual(context),
                icon: const Icon(Icons.add),
                label: const Text('+ Tambah Makanan'),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
              ),
            ],
          ),
        ),
      );
    }

    final filteredItems = _searchQuery.isEmpty
        ? provider.items
        : provider.items
            .where((item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m, vertical: AppSpacing.s),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Cari makanan...',
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
        ),
        // Empty search state
        if (filteredItems.isEmpty && _searchQuery.isNotEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Tidak ditemukan',
                      style: AppTheme.jakartaSemiBold(size: 15),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '"$_searchQuery" tidak ada di koleksimu.',
                      textAlign: TextAlign.center,
                      style: AppTheme.inter(size: 13).copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    TextButton(
                      onPressed: () => setState(() => _searchQuery = ''),
                      child: const Text('Hapus pencarian'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: provider.load,
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.m, AppSpacing.s, AppSpacing.m, 100),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.s,
                  mainAxisSpacing: AppSpacing.s,
                  childAspectRatio: 0.85,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (_, i) => _FoodCard(item: filteredItems[i]),
              ),
            ),
          ),
      ],
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

  Widget _buildImage(FoodItem item, ColorScheme scheme) {
    final path = item.imagePath;
    final firstLetter =
        item.name.isNotEmpty ? item.name[0].toUpperCase() : '?';

    if (path != null) {
      Widget imageWidget;
      if (FoodImageStorage.isRemoteUrl(path)) {
        imageWidget = Image.network(
          path,
          height: 80,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _letterAvatar(firstLetter),
        );
      } else if (!kIsWeb) {
        imageWidget = Image.file(
          File(path),
          height: 80,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _letterAvatar(firstLetter),
        );
      } else {
        imageWidget = _letterAvatar(firstLetter);
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(height: 80, width: double.infinity, child: imageWidget),
      );
    }
    return _letterAvatar(firstLetter);
  }

  Widget _letterAvatar(String letter) {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          letter,
          style: AppTheme.jakartaBold(size: 28).copyWith(
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FoodDetailScreen(id: item.id)),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.glassPanelDecoration(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: letter avatar or image
            _buildImage(item, Theme.of(context).colorScheme),
            const SizedBox(height: 8),
            // Food name
            Text(
              item.name,
              style: AppTheme.jakartaSemiBold(size: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // Bottom row
            Row(
              children: [
                Text(
                  '${item.calories.toStringAsFixed(0)} kkal',
                  style: AppTheme.digitStyle(size: 13, color: AppTheme.primary)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _SourceBadge(item.source.label),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTheme.inter(size: 10).copyWith(
          color: AppTheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
