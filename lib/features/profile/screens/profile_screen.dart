import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart' as app_auth;
import '../../scanner/providers/food_library_provider.dart';
import '../../scanner/services/gemini_service.dart';
import '../providers/user_prefs_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editCalorieGoal(
      BuildContext context, UserPrefsProvider prefs) async {
    final result = await showDialog<double>(
      context: context,
      builder: (_) => _CalorieGoalDialog(initialValue: prefs.calorieGoal),
    );
    if (result != null && context.mounted) {
      await prefs.setCalorieGoal(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();
    final library = context.watch<FoodLibraryProvider>();
    final gemini = context.watch<GeminiService>();
    final prefs = context.watch<UserPrefsProvider>();
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
                        auth.email ?? 'Pengguna GiziKu',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: auth.signOut,
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text('Keluar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.onPrimaryContainer,
                          side: BorderSide(
                              color: scheme.onPrimaryContainer.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
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
              leading: const Icon(Icons.local_fire_department_outlined),
              title: const Text('Target Kalori Harian'),
              subtitle: Text('${prefs.calorieGoal.toStringAsFixed(0)} kkal / hari'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editCalorieGoal(context, prefs),
            ),
          ),
          const SizedBox(height: 8),
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

class _CalorieGoalDialog extends StatefulWidget {
  const _CalorieGoalDialog({required this.initialValue});
  final double initialValue;

  @override
  State<_CalorieGoalDialog> createState() => _CalorieGoalDialogState();
}

class _CalorieGoalDialogState extends State<_CalorieGoalDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Target Kalori Harian'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          suffixText: 'kkal',
          hintText: '2000',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final v = double.tryParse(_controller.text);
            if (v != null && v > 0) Navigator.pop(context, v);
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
