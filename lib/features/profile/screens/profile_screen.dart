import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/nutrition_colors.dart';
import '../../../core/theme/semantic_colors.dart';
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

  Future<void> _editMacroGoals(
      BuildContext context, UserPrefsProvider prefs) async {
    final result =
        await showDialog<({double protein, double carbs, double fat})>(
      context: context,
      builder: (_) => _MacroGoalsDialog(
        initialProtein: prefs.proteinGoal,
        initialCarbs: prefs.carbsGoal,
        initialFat: prefs.fatGoal,
      ),
    );
    if (result != null && context.mounted) {
      await prefs.setMacroGoals(
        protein: result.protein,
        carbs: result.carbs,
        fat: result.fat,
      );
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

    final supabaseActive = _isSupabaseActive();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: Container(
        decoration: AppTheme.meshBackgroundDecoration,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.m, AppSpacing.m, 120),
        children: [
              // ── Hero dashboard card ─────────────────────────────────────
              _HeroDashboard(
                email: auth.email ?? 'Pengguna GiziKu',
                onSignOut: auth.signOut,
                consumed: diary.totalCalories,
                goal: prefs.calorieGoal,
                koleksi: library.items.length,
                rencana: planner.items.length,
                diaryCount: diary.entries.length,
              ),
              const SizedBox(height: AppSpacing.m),

              // Section header — Tujuan
              Padding(
                padding: const EdgeInsets.only(
                    left: AppSpacing.xxs, bottom: AppSpacing.xs),
                child: Text('TUJUAN', style: AppTheme.sectionLabel()),
              ),

              // Target kalori (editable)
              _SectionCard(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_outlined,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text('Target Kalori Harian',
                        style: AppTheme.jakartaSemiBold(size: 14)),
                    subtitle: Text(
                      '${prefs.calorieGoal.toStringAsFixed(0)} kkal / hari',
                      style: AppTheme.digitStyle(size: 13),
                    ),
                    trailing: const Icon(Icons.edit_outlined, size: 18),
                    onTap: () => _editCalorieGoal(context, prefs),
                  ),
                ),
                const SizedBox(height: AppSpacing.s),

                // Target makronutrien (editable)
                _SectionCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiary
                                .withValues(alpha: 0.10),
                            borderRadius:
                                BorderRadius.circular(AppRadius.medium),
                          ),
                          child: Icon(
                            Icons.donut_small_outlined,
                            color: Theme.of(context).colorScheme.tertiary,
                            size: 20,
                          ),
                        ),
                        title: Text('Target Makronutrien',
                            style: AppTheme.jakartaSemiBold(size: 14)),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit target makro',
                          onPressed: () => _editMacroGoals(context, prefs),
                        ),
                      ),
                      if (prefs.proteinGoal > 0 ||
                          prefs.carbsGoal > 0 ||
                          prefs.fatGoal > 0) ...[
                        const Divider(height: 1),
                        Builder(builder: (context) {
                          final nc = NutritionColors.of(context);
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.m,
                                AppSpacing.s,
                                AppSpacing.m,
                                AppSpacing.s),
                            child: Row(
                              children: [
                                _MacroGoalChip(
                                  label: 'Protein',
                                  current: diary.totalProtein,
                                  goal: prefs.proteinGoal,
                                  color: nc.proteinColor,
                                ),
                                const SizedBox(width: 8),
                                _MacroGoalChip(
                                  label: 'Karbo',
                                  current: diary.totalCarbs,
                                  goal: prefs.carbsGoal,
                                  color: nc.carbsColor,
                                ),
                                const SizedBox(width: 8),
                                _MacroGoalChip(
                                  label: 'Lemak',
                                  current: diary.totalFat,
                                  goal: prefs.fatGoal,
                                  color: nc.fatColor,
                                ),
                              ],
                            ),
                          );
                        }),
                      ] else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.m,
                              0, AppSpacing.m, AppSpacing.s),
                          child: Text(
                            'Ketuk ikon edit untuk mengatur target protein, karbo, dan lemak harian.',
                            style: AppTheme.inter(size: 13).copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                // Section header — Integrasi
                Padding(
                  padding: const EdgeInsets.only(
                      left: AppSpacing.xxs, bottom: AppSpacing.xs),
                  child: Text('INTEGRASI', style: AppTheme.sectionLabel()),
                ),

                // Status integrasi backend
                Builder(builder: (context) {
                  final sc = SemanticColors.of(context);
                  return _SectionCard(
                    child: Column(
                      children: [
                        _IntegrationTile(
                          icon: gemini.isConfigured
                              ? Icons.check_circle
                              : Icons.info_outline,
                          iconColor: gemini.isConfigured
                              ? sc.success
                              : sc.warning,
                          title: 'Gemini AI',
                          subtitle: gemini.isConfigured
                              ? 'Aktif (${gemini.modelName})'
                              : 'Belum disetel — cek GEMINI_API_KEY di .env',
                        ),
                        const Divider(height: 1),
                        _IntegrationTile(
                          icon: supabaseActive
                              ? Icons.cloud_done_outlined
                              : Icons.cloud_off,
                          iconColor:
                              supabaseActive ? sc.success : sc.warning,
                          title: 'Cloud Sync (Supabase)',
                          subtitle: supabaseActive
                              ? 'Koleksi makanan & gambar tersinkron ke cloud'
                              : 'Belum aktif — data hanya tersimpan lokal',
                        ),
                        const Divider(height: 1),
                        _IntegrationTile(
                          icon: Icons.verified_user_outlined,
                          iconColor: sc.success,
                          title: 'Firebase Auth',
                          subtitle:
                              'Login & isolasi data per-user aktif',
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.l),
                Center(
                  child: Text(
                    'GiziKu · Final Project PPB',
                    style: AppTheme.inter(size: 13).copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
        ],
        ), // ListView
      ), // Container mesh
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

// ─────────────────────────────────────────────────────────────────────────────
// Reusable section card wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassPanelDecoration(radius: 16),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Integration status tile
// ─────────────────────────────────────────────────────────────────────────────

class _IntegrationTile extends StatelessWidget {
  const _IntegrationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(title, style: AppTheme.jakartaSemiBold(size: 14)),
      subtitle: Text(subtitle,
          style: AppTheme.inter(size: 12)
              .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Macro goal chip
// ─────────────────────────────────────────────────────────────────────────────

class _MacroGoalChip extends StatelessWidget {
  const _MacroGoalChip({
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
  });
  final String label;
  final double current;
  final double goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final over = goal > 0 && current > goal;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xs, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Column(
          children: [
            Text(
              '${current.toStringAsFixed(0)} g',
              style: AppTheme.digitStyle(
                  size: 14, color: color.withValues(alpha: 0.9)),
            ),
            Text(
              '/ ${goal.toStringAsFixed(0)} g',
              style: AppTheme.digitStyle(size: 10)
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
            Text(
              label,
              style: AppTheme.inter(size: 11)
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  over ? SemanticColors.of(context).warning : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialogs (preserved exactly from original)
// ─────────────────────────────────────────────────────────────────────────────

class _MacroGoalsDialog extends StatefulWidget {
  const _MacroGoalsDialog({
    required this.initialProtein,
    required this.initialCarbs,
    required this.initialFat,
  });
  final double initialProtein;
  final double initialCarbs;
  final double initialFat;

  @override
  State<_MacroGoalsDialog> createState() => _MacroGoalsDialogState();
}

class _MacroGoalsDialogState extends State<_MacroGoalsDialog> {
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;

  @override
  void initState() {
    super.initState();
    _protein = TextEditingController(
      text: widget.initialProtein > 0
          ? widget.initialProtein.toStringAsFixed(0)
          : '',
    );
    _carbs = TextEditingController(
      text: widget.initialCarbs > 0
          ? widget.initialCarbs.toStringAsFixed(0)
          : '',
    );
    _fat = TextEditingController(
      text:
          widget.initialFat > 0 ? widget.initialFat.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Target Makronutrien Harian'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _protein,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Protein',
              suffixText: 'gram',
              hintText: 'cth: 50',
            ),
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.s),
          TextField(
            controller: _carbs,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Karbohidrat',
              suffixText: 'gram',
              hintText: 'cth: 250',
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          TextField(
            controller: _fat,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Lemak',
              suffixText: 'gram',
              hintText: 'cth: 70',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final protein = double.tryParse(_protein.text) ?? 0;
            final carbs = double.tryParse(_carbs.text) ?? 0;
            final fat = double.tryParse(_fat.text) ?? 0;
            Navigator.pop(
                context, (protein: protein, carbs: carbs, fat: fat));
          },
          child: const Text('Simpan'),
        ),
      ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Hero dashboard card — combines avatar, calorie progress, and mini stats
// ─────────────────────────────────────────────────────────────────────────────

class _HeroDashboard extends StatelessWidget {
  const _HeroDashboard({
    required this.email,
    required this.onSignOut,
    required this.consumed,
    required this.goal,
    required this.koleksi,
    required this.rencana,
    required this.diaryCount,
  });
  final String email;
  final VoidCallback onSignOut;
  final double consumed, goal;
  final int koleksi, rencana, diaryCount;

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;
    final remaining = (goal - consumed).clamp(0, double.infinity);
    final sc = SemanticColors.of(context);
    final progressColor = progress < 0.7
        ? sc.success
        : (progress < 1.0 ? sc.warning : sc.error);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: AppTheme.glassPanelHeavyDecoration(radius: AppRadius.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + info + calorie number
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradientVertical,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Color(0x3310B981), blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Center(
                  child: Text(
                    email.isNotEmpty ? email[0].toUpperCase() : 'G',
                    style: AppTheme.jakartaBold(size: 22, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email,
                      style: AppTheme.jakartaSemiBold(size: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    TextButton.icon(
                      onPressed: onSignOut,
                      icon: const Icon(Icons.logout_rounded, size: 12),
                      label: const Text('Keluar'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: AppTheme.inter(size: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    consumed.toStringAsFixed(0),
                    style:
                        AppTheme.digitStyle(size: 28, color: AppTheme.primary),
                  ),
                  Text(
                    '/ ${goal.toStringAsFixed(0)} kkal',
                    style: AppTheme.inter(
                        size: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          // Calorie progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppTheme.borderLight,
              color: progressColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            consumed >= goal
                ? 'Target tercapai · kelebihan ${(consumed - goal).toStringAsFixed(0)} kkal'
                : 'Sisa ${remaining.toStringAsFixed(0)} kkal hari ini',
            style: AppTheme.inter(
                size: 11,
                color:
                    Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.m),
          // Stats row
          Row(
            children: [
              _MiniStat(
                  icon: Icons.collections_bookmark_outlined,
                  label: 'Koleksi',
                  value: '$koleksi'),
              const SizedBox(width: AppSpacing.m),
              Container(width: 1, height: 24, color: AppTheme.border),
              const SizedBox(width: AppSpacing.m),
              _MiniStat(
                  icon: Icons.calendar_month_outlined,
                  label: 'Rencana',
                  value: '$rencana'),
              const SizedBox(width: AppSpacing.m),
              Container(width: 1, height: 24, color: AppTheme.border),
              const SizedBox(width: AppSpacing.m),
              _MiniStat(
                  icon: Icons.menu_book_outlined,
                  label: 'Diary',
                  value: '$diaryCount'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.primary),
        const SizedBox(width: 4),
        Text(value,
            style: AppTheme.digitStyle(size: 13, color: AppTheme.primary)),
        const SizedBox(width: 3),
        Text(label,
            style: AppTheme.inter(
                size: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
