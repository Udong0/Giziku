import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/food_item.dart';
import '../services/gemini_service.dart';
import 'analysis_result_screen.dart';
import 'food_library_screen.dart';

class ScannerHomeScreen extends StatefulWidget {
  const ScannerHomeScreen({super.key});

  @override
  State<ScannerHomeScreen> createState() => _ScannerHomeScreenState();
}

class _ScannerHomeScreenState extends State<ScannerHomeScreen> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  bool _analyzing = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis(Future<FoodAnalysis> Function() task) async {
    setState(() => _analyzing = true);
    try {
      final result = await task();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AnalysisResultScreen(analysis: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analisis gagal: $e')),
      );
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final gemini = context.read<GeminiService>();
    final XFile? file = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (file == null) return;
    await _runAnalysis(() => gemini.analyzeImage(
          File(file.path),
          hint: _textController.text.trim(),
        ));
  }

  Future<void> _analyzeText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ketik nama makanan dulu')),
      );
      return;
    }
    final gemini = context.read<GeminiService>();
    await _runAnalysis(() => gemini.analyzeText(text));
  }

  @override
  Widget build(BuildContext context) {
    final gemini = context.watch<GeminiService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('GiziKu Scanner'),
        actions: [
          IconButton(
            tooltip: 'Koleksi Makananku',
            icon: const Icon(Icons.collections_bookmark_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FoodLibraryScreen()),
            ),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _analyzing,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(geminiConfigured: gemini.isConfigured),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Apa yang ingin kamu analisis?',
                hintText: 'cth: nasi padang, ayam geprek, sate ayam',
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _analyzeText(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _analyzing ? null : _analyzeText,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Analisis dari teks'),
            ),
            const SizedBox(height: 28),
            Text(
              'Atau jepret langsung',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _BigActionCard(
                    icon: Icons.photo_camera,
                    label: 'Kamera',
                    onTap: _analyzing
                        ? null
                        : () => _pickAndAnalyze(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BigActionCard(
                    icon: Icons.image_outlined,
                    label: 'Galeri',
                    onTap: _analyzing
                        ? null
                        : () => _pickAndAnalyze(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FoodLibraryScreen()),
              ),
              icon: const Icon(Icons.list_alt),
              label: const Text('Buka Koleksi Makananku'),
            ),
            if (_analyzing) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Center(child: Text('Menganalisis dengan AI...')),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.geminiConfigured});

  final bool geminiConfigured;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco, color: scheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                'AI Food Scanner',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Foto atau ketik makanannya, AI akan estimasi kandungan gizi-nya. '
            'Simpan ke koleksi pribadi untuk dipakai di Tracker harian.',
            style: TextStyle(color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  geminiConfigured ? Icons.check_circle : Icons.info_outline,
                  size: 16,
                  color: geminiConfigured ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  geminiConfigured
                      ? 'Gemini aktif'
                      : 'Mode offline (mock) — set GEMINI_API_KEY',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BigActionCard extends StatelessWidget {
  const _BigActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
