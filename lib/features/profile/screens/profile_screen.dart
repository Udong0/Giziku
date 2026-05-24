import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../scanner/providers/food_library_provider.dart';
import '../../scanner/services/gemini_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<FoodLibraryProvider>();
    final gemini = context.watch<GeminiService>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: scheme.surface,
                  child: Icon(Icons.person, color: scheme.primary, size: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tamu GiziKu',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Hubungkan Firebase Auth untuk login.',
                        style: TextStyle(color: scheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.collections_bookmark_outlined),
              title: const Text('Koleksi Makanan'),
              subtitle: Text('${library.items.length} item tersimpan'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(
                gemini.isConfigured ? Icons.check_circle : Icons.info_outline,
                color: gemini.isConfigured ? Colors.green : Colors.orange,
              ),
              title: const Text('Gemini API'),
              subtitle: Text(
                gemini.isConfigured
                    ? 'Aktif (${gemini.modelName})'
                    : 'Belum disetel — jalankan dengan --dart-define=GEMINI_API_KEY=...',
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'GiziKu · Final Project PPB',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
