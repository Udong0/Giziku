import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/food_item.dart';
import '../providers/food_library_provider.dart';
import '../services/food_image_storage.dart';
import 'food_form.dart';

/// UPDATE (also handles "create from blank" when [isNew] is true).
class FoodEditScreen extends StatefulWidget {
  const FoodEditScreen({super.key, required this.item, this.isNew = false});

  final FoodItem item;
  final bool isNew;

  @override
  State<FoodEditScreen> createState() => _FoodEditScreenState();
}

class _FoodEditScreenState extends State<FoodEditScreen> {
  late final FoodFormController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = FoodFormController.fromItem(widget.item);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final storage = context.read<FoodImageStorage?>();
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _saving = true);
    final (path, uploadError) = await _persistImage(file.path, storage);
    if (!mounted) return;
    setState(() {
      _controller.imagePath = path;
      _saving = false;
    });
    if (uploadError != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Upload cloud gagal, simpan lokal.\n$uploadError'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  /// Prioritas: upload ke Supabase Storage. Fallback: salin ke app docs dir.
  /// Return `(path, errorMessage)` — errorMessage non-null kalau upload gagal.
  Future<(String?, String?)> _persistImage(
    String source,
    FoodImageStorage? storage,
  ) async {
    String? uploadError;
    if (storage != null) {
      try {
        final url = await storage.upload(File(source));
        debugPrint('[FoodEdit] ✅ Upload Supabase OK: $url');
        return (url, null);
      } catch (e) {
        uploadError = e.toString();
        debugPrint('[FoodEdit] ❌ Upload Supabase gagal: $e');
      }
    } else {
      uploadError = 'FoodImageStorage = null (Supabase belum di-init)';
      debugPrint('[FoodEdit] ⚠️ $uploadError');
    }
    try {
      final docs = await getApplicationDocumentsDirectory();
      final foodDir = Directory(p.join(docs.path, 'food_images'));
      if (!await foodDir.exists()) await foodDir.create(recursive: true);
      final ext = p.extension(source).isEmpty ? '.jpg' : p.extension(source);
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
        const SnackBar(content: Text('Nama makanan wajib diisi.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = widget.item.copyWith(
        name: draft.name,
        description: draft.description,
        calories: draft.calories,
        protein: draft.protein,
        carbs: draft.carbs,
        fat: draft.fat,
        servingSize: draft.servingSize,
        imagePath: _controller.imagePath,
        updatedAt: DateTime.now(),
      );
      final provider = context.read<FoodLibraryProvider>();
      if (widget.isNew) {
        await provider.add(updated);
      } else {
        await provider.update(updated);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isNew ? 'Makanan ditambahkan.' : 'Perubahan disimpan.'),
        ),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'Tambah Makanan' : 'Edit Makanan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ImagePreview(
            path: _controller.imagePath,
            onCamera: _saving ? null : () => _pickImage(ImageSource.camera),
            onGallery: _saving ? null : () => _pickImage(ImageSource.gallery),
            onClear: _saving || _controller.imagePath == null
                ? null
                : () => setState(() => _controller.imagePath = null),
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
            label: Text(widget.isNew ? 'Simpan' : 'Simpan Perubahan'),
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

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.path,
    required this.onCamera,
    required this.onGallery,
    required this.onClear,
  });

  final String? path;
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final VoidCallback? onClear;

  Widget _placeholder(ColorScheme scheme) => Container(
        color: scheme.surfaceContainerHighest,
        child: const Center(
          child: Icon(Icons.photo_outlined, size: 48),
        ),
      );

  Widget _buildPreview(ColorScheme scheme) {
    final p = path;
    if (p == null) return _placeholder(scheme);
    if (FoodImageStorage.isRemoteUrl(p)) {
      return Image.network(
        p,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(scheme),
      );
    }
    if (kIsWeb) return _placeholder(scheme);
    return Image.file(
      File(p),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(scheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildPreview(scheme),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Kamera'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Galeri'),
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Hapus foto',
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
