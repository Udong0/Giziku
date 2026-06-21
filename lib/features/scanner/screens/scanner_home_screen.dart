import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../models/food_item.dart';
import '../providers/food_library_provider.dart';
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
    final gemini = context.read<GeminiService>();
    try {
      final result = await task();
      if (!mounted) return;
      if (gemini.lastError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AI tidak merespon — pakai estimasi offline. '
              '(${gemini.lastError})',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
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
      body: Container(
        decoration: AppTheme.meshBackgroundDecoration,
        child: AbsorbPointer(
        absorbing: _analyzing,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m, AppSpacing.m, AppSpacing.m, 120,
          ),
          children: [
            // Header card
            _HeaderCard(geminiConfigured: gemini.isConfigured),
            const SizedBox(height: AppSpacing.l),

            // Search text field
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Apa yang ingin kamu analisis?',
                hintText: 'cth: nasi padang, ayam geprek, sate ayam',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textController,
                  builder: (context, value, child) => value.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: _textController.clear,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _analyzeText(),
            ),
            const SizedBox(height: AppSpacing.s),

            // Analyze text button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _analyzing ? null : _analyzeText,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Analisis dari teks'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.l),

            // Section label
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Atau jepret langsung',
                  style: AppTheme.jakartaSemiBold(size: 15),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),

            // Camera / gallery action cards
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.photo_camera_rounded,
                    label: 'Kamera',
                    subtitle: 'Foto langsung',
                    color: AppTheme.primary,
                    onTap: _analyzing
                        ? null
                        : () => _pickAndAnalyze(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    subtitle: 'Pilih foto',
                    color: Theme.of(context).colorScheme.tertiary,
                    onTap: _analyzing
                        ? null
                        : () => _pickAndAnalyze(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),

            // Open library button
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FoodLibraryScreen()),
              ),
              icon: const Icon(Icons.list_alt_rounded),
              label: const Text('Buka Koleksi Makananku'),
            ),

            // Loading overlay
            if (_analyzing) ...[
              const SizedBox(height: AppSpacing.l),
              Container(
                padding: const EdgeInsets.all(AppSpacing.l),
                decoration: AppTheme.glassPanelHeavyDecoration(radius: AppRadius.extraLarge),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primary),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Menganalisis dengan AI...',
                      style: AppTheme.inter(size: 14).copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        ), // AbsorbPointer
      ), // Container mesh
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header card
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.geminiConfigured});
  final bool geminiConfigured;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        boxShadow: const [
          BoxShadow(color: Color(0x3310B981), blurRadius: 20, offset: Offset(0, 8), spreadRadius: -4),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scanner Makanan', style: AppTheme.jakartaSemiBold(size: 18, color: Colors.white)),
                Text(
                  'Foto atau ketik makanan, AI estimasi gizi.',
                  style: AppTheme.inter(size: 12, color: Colors.white.withValues(alpha: 0.85)),
                ),
                Consumer<FoodLibraryProvider>(
                  builder: (context, library, _) => Text(
                    '${library.items.length} makanan tersimpan',
                    style: AppTheme.inter(size: 11, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: geminiConfigured
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.orange.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Text(
              geminiConfigured ? 'AI Aktif' : 'Offline',
              style: AppTheme.inter(size: 11, color: Colors.white, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action card (camera / gallery)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return AspectRatio(
      aspectRatio: 1.1,
      child: Card(
        elevation: 0,
        color: const Color(0xD1FFFFFF),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0xB3FFFFFF)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: disabled
                        ? Theme.of(context).colorScheme.surfaceContainerLow
                        : color.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: disabled
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: AppTheme.jakartaSemiBold(size: 14).copyWith(
                    color: disabled
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : AppTheme.charcoal,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTheme.inter(size: 12).copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
