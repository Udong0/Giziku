import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/food_item.dart';
import '../providers/food_library_provider.dart';
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

  Future<String?> _persistImage(String? source) async {
    if (source == null) return null;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final foodDir = Directory(p.join(docs.path, 'food_images'));
      if (!await foodDir.exists()) await foodDir.create(recursive: true);
      final ext = p.extension(source).isEmpty ? '.jpg' : p.extension(source);
      final destPath = p.join(foodDir.path, '${const Uuid().v4()}$ext');
      await File(source).copy(destPath);
      return destPath;
    } catch (_) {
      return source;
    }
  }

  Future<void> _save() async {
    final draft = _controller.toDraft();
    if (draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periksa lagi isian — ada yang kosong.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final storedPath = await _persistImage(draft.imagePath);
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
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      await context.read<FoodLibraryProvider>().add(item);
      messenger.showSnackBar(
        SnackBar(content: Text('"${item.name}" disimpan ke koleksi.')),
      );
      navigator.pop();
      navigator.push(
        MaterialPageRoute(builder: (_) => const FoodLibraryScreen()),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Analisis AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.analysis.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(widget.analysis.imagePath!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          if (widget.analysis.imagePath != null) const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome,
                    size: 16, color: scheme.onSecondaryContainer),
                const SizedBox(width: 6),
                Text(
                  '${widget.analysis.source.label} · keyakinan '
                  '${(widget.analysis.confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: scheme.onSecondaryContainer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FoodFormFields(controller: _controller),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Simpan ke Koleksi'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }
}
