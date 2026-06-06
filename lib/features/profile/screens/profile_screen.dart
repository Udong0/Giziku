import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart' as app_auth;
import '../../planner/providers/meal_plan_provider.dart';
import '../../scanner/providers/food_library_provider.dart';
import '../../scanner/services/gemini_service.dart';
import '../../tracker/providers/diary_provider.dart';
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
    final diary = context.watch<DiaryProvider>();
    final planner = context.watch<MealPlanProvider>();
    final scheme = Theme.of(context).colorScheme;

    // Supabase aktif kalau client sudah pernah di-init.
    final supabaseActive = _isSupabaseActive();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(
            email: auth.email ?? 'Pengguna GiziKu',
            onSignOut: auth.signOut,
            scheme: scheme,
          ),
          const SizedBox(height: 16),

          // Stats antar fitur
          _StatsRow(
            scheme: scheme,
            items: [
              _StatItem(
                icon: Icons.collections_bookmark_outlined,
                label: 'Koleksi',
                value: '${library.items.length}',
              ),
              _StatItem(
                icon: Icons.calendar_month_outlined,
                label: 'Rencana',
                value: '${planner.items.length}',
              ),
              _StatItem(
                icon: Icons.menu_book_outlined,
                label: 'Diary',
                value: '${diary.entries.length}',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress kalori hari ini
          _CalorieProgressCard(
            consumed: diary.totalCalories,
            goal: prefs.calorieGoal,
            scheme: scheme,
          ),
          const SizedBox(height: 8),

          // Target kalori (editable)
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_fire_department_outlined),
              title: const Text('Target Kalori Harian'),
              subtitle:
                  Text('${prefs.calorieGoal.toStringAsFixed(0)} kkal / hari'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editCalorieGoal(context, prefs),
            ),
          ),
          const SizedBox(height: 8),

          // Status integrasi backend
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    gemini.isConfigured ? Icons.check_circle : Icons.info_outline,
                    color: gemini.isConfigured ? Colors.green : Colors.orange,
                  ),
                  title: const Text('Gemini AI'),
                  subtitle: Text(
                    gemini.isConfigured
                        ? 'Aktif (${gemini.modelName})'
                        : 'Belum disetel — cek GEMINI_API_KEY di .env',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    supabaseActive ? Icons.cloud_done_outlined : Icons.cloud_off,
                    color: supabaseActive ? Colors.green : Colors.orange,
                  ),
                  title: const Text('Cloud Sync (Supabase)'),
                  subtitle: Text(
                    supabaseActive
                        ? 'Koleksi makanan & gambar tersinkron ke cloud'
                        : 'Belum aktif — data hanya tersimpan lokal',
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.verified_user_outlined,
                      color: Colors.green),
                  title: Text('Firebase Auth'),
                  subtitle: Text('Login & isolasi data per-user aktif'),
                ),
              ],
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

  bool _isSupabaseActive() {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.email,
    required this.onSignOut,
    required this.scheme,
  });

  final String email;
  final VoidCallback onSignOut;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  email,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: onSignOut,
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
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem(
      {required this.icon, required this.label, required this.value});
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.items, required this.scheme});
  final List<_StatItem> items;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(items[i].icon, color: scheme.primary),
                    const SizedBox(height: 6),
                    Text(
                      items[i].value,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      items[i].label,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CalorieProgressCard extends StatelessWidget {
  const _CalorieProgressCard({
    required this.consumed,
    required this.goal,
    required this.scheme,
  });

  final double consumed;
  final double goal;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;
    final remaining = (goal - consumed).clamp(0, double.infinity);
    final color = progress < 0.7
        ? Colors.green
        : (progress < 1.0 ? Colors.orange : Colors.red);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: color),
                const SizedBox(width: 8),
                const Text(
                  'Kalori Hari Ini',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${consumed.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} kkal',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: scheme.surfaceContainerHighest,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              consumed >= goal
                  ? 'Target tercapai · kelebihan ${(consumed - goal).toStringAsFixed(0)} kkal'
                  : 'Sisa ${remaining.toStringAsFixed(0)} kkal hari ini',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
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
