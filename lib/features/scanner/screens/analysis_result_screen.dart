import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/nutrition_colors.dart';
import '../../../core/theme/semantic_colors.dart';

import '../models/food_item.dart';
import '../providers/food_library_provider.dart';
import '../services/food_image_storage.dart';
import 'food_form.dart';
import 'food_library_screen.dart';

/// Review screen shown right after a Gemini analysis.
/// User can tweak fields, then save to library (CREATE).
class AnalysisResultScreen extends StatefulWidget {
  const AnalysisResultScreen({super.key, required this.analysis});

  final FoodAnalysis analysis;

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  late FoodFormController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = FoodFormController.fromAnalysis(widget.analysis);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Prioritas: upload ke Supabase Storage. Fallback: salin ke app docs dir.
  Future<(String?, String?)> _persistImage(
    String? source,
    FoodImageStorage? storage,
  ) async {
    if (source == null) return (null, null);
    String? uploadError;
    if (storage != null) {
      try {
        final url = await storage.upload(File(source));
        debugPrint('[AnalysisResult] ✅ Upload Supabase OK: $url');
        return (url, null);
      } catch (e) {
        uploadError = e.toString();
        debugPrint('[AnalysisResult] ❌ Upload Supabase gagal: $e');
      }
    } else {
      uploadError = 'FoodImageStorage = null (Supabase belum di-init)';
      debugPrint('[AnalysisResult] ⚠️ $uploadError');
    }
    try {
      final docs = await getApplicationDocumentsDirectory();
      final foodDir = Directory(p.join(docs.path, 'food_images'));
      if (!await foodDir.exists()) await foodDir.create(recursive: true);
      final ext =
          p.extension(source).isEmpty ? '.jpg' : p.extension(source);
      final destPath = p.join(foodDir.path, '${const Uuid().v4()}$ext');
      await File(source).copy(destPath);
      return (destPath, uploadError);
    } catch (_) {
      return (source, uploadError);
    }
  }

  Future<void> _save() async {
    final draft = _controller.toDraft();
    if (draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Periksa lagi isian — ada yang kosong.')),
      );
      return;
    }

    final storage = context.read<FoodImageStorage?>();
    final libProvider = context.read<FoodLibraryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _saving = true);
    try {
      final (storedPath, uploadError) =
          await _persistImage(draft.imagePath, storage);
      final now = DateTime.now();
      final item = FoodItem(
        id: const Uuid().v4(),
        name: draft.name,
        description: draft.description,
        calories: draft.calories,
        protein: draft.protein,
        carbs: draft.carbs,
        fat: draft.fat,
        servingSize: draft.servingSize,
        imagePath: storedPath,
        source: widget.analysis.source,
        createdAt: now,
        updatedAt: now,
      );
      if (!mounted) return;
      await libProvider.add(item);
      if (uploadError != null) {
        messenger.showSnackBar(
          SnackBar(
            content:
                Text('Upload cloud gagal, simpan lokal.\n$uploadError'),
            duration: const Duration(seconds: 8),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('"${item.name}" disimpan ke koleksi.')),
        );
      }
      navigator.pop();
      navigator.push(
        MaterialPageRoute(builder: (_) => const FoodLibraryScreen()),
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.analysis.imagePath != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Analisis AI'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Hero image card (only when image exists) ─────────────────
          if (hasImage)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.m, AppSpacing.m, AppSpacing.m, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: AppTheme.glassPanelDecoration(radius: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(widget.analysis.imagePath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xs),

                // Source & confidence badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 14, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.analysis.source.label} · keyakinan ',
                        style: AppTheme.inter(size: 12).copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(widget.analysis.confidence * 100).toStringAsFixed(0)}%',
                        style: AppTheme.digitStyle(size: 11, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 40,
                        height: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          child: LinearProgressIndicator(
                            value: widget.analysis.confidence,
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.l),

                // Nutrition preview tiles
                _NutritionPreviewGrid(analysis: widget.analysis),
                const SizedBox(height: AppSpacing.l),

                // Divider
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
                      'Edit sebelum menyimpan',
                      style: AppTheme.jakartaSemiBold(size: 15),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),

                // Editable form
                FoodFormFields(controller: _controller),
                const SizedBox(height: AppSpacing.l),

                // CTA: Save
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Simpan ke Koleksi'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                // CTA: Discard
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: SemanticColors.of(context).error),
                    label: Text(
                      'Buang Hasil',
                      style: TextStyle(color: SemanticColors.of(context).error),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nutrition preview (read-only, from FoodAnalysis data)
// ─────────────────────────────────────────────────────────────────────────────

class _NutritionPreviewGrid extends StatelessWidget {
  const _NutritionPreviewGrid({required this.analysis});
  final FoodAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final nc = NutritionColors.of(context);
    final tiles = [
      _NutritionPreviewTile(
        label: 'Kalori',
        value: analysis.calories.toStringAsFixed(0),
        unit: 'kkal',
        color: nc.calorieColor,
        icon: Icons.local_fire_department_rounded,
      ),
      _NutritionPreviewTile(
        label: 'Protein',
        value: analysis.protein.toStringAsFixed(1),
        unit: 'g',
        color: nc.proteinColor,
        icon: Icons.egg_alt_rounded,
      ),
      _NutritionPreviewTile(
        label: 'Karbo',
        value: analysis.carbs.toStringAsFixed(1),
        unit: 'g',
        color: nc.carbsColor,
        icon: Icons.rice_bowl_rounded,
      ),
      _NutritionPreviewTile(
        label: 'Lemak',
        value: analysis.fat.toStringAsFixed(1),
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
      children: tiles,
    );
  }
}

class _NutritionPreviewTile extends StatelessWidget {
  const _NutritionPreviewTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
              Text(
                unit,
                style: AppTheme.inter(size: 11).copyWith(
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTheme.digitStyle(size: 22).copyWith(
                  color: color.withValues(alpha: 0.9),
                ),
              ),
              Text(
                label,
                style: AppTheme.inter(size: 12).copyWith(
                  color: color.withValues(alpha: 0.7),
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
