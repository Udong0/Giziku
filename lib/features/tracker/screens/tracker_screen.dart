import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/nutrition_colors.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../features/profile/providers/user_prefs_provider.dart';
import '../models/diary_entry.dart';
import '../providers/diary_provider.dart';
import 'add_entry_screen.dart';

class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();
    final prefs = context.watch<UserPrefsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracker Harian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Pilih tanggal',
            onPressed: () => _pickDate(context, provider),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.meshBackgroundDecoration,
        child: Column(
        children: [
          _DateBar(provider: provider),
          if (provider.loading) const LinearProgressIndicator(),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m, vertical: AppSpacing.xs),
              child: Text(
                provider.error!,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m, AppSpacing.s, AppSpacing.m, 120,
              ),
              children: [
                _CalorieRingCard(provider: provider, prefs: prefs),
                const SizedBox(height: AppSpacing.s),
                _WeeklyChartCard(
                    provider: provider, goal: prefs.calorieGoal),
                const SizedBox(height: AppSpacing.m),
                for (final meal in MealType.values) ...[
                  _MealSection(
                    mealType: meal,
                    entries: provider.entriesForMeal(meal),
                    selectedDate: provider.selectedDate,
                  ),
                  const SizedBox(height: AppSpacing.s),
                ],
              ],
            ),
          ),
        ],
        ), // Column
      ), // Container mesh
    );
  }

  Future<void> _pickDate(
      BuildContext context, DiaryProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      helpText: 'Pilih Tanggal Jurnal',
    );
    if (picked != null && context.mounted) {
      provider.loadDate(picked);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date navigation bar
// ─────────────────────────────────────────────────────────────────────────────

class _DateBar extends StatelessWidget {
  const _DateBar({required this.provider});
  final DiaryProvider provider;

  String _format(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isToday =
        DateUtils.isSameDay(provider.selectedDate, DateTime.now());

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m, vertical: AppSpacing.xs),
      child: Row(
        children: [
          _NavButton(
              icon: Icons.chevron_left_rounded,
              onPressed: provider.previousDay),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              decoration: AppTheme.glassAccentDecoration(radius: AppRadius.full),
              child: Column(
                children: [
                  Text(
                    isToday ? 'Hari Ini' : _format(provider.selectedDate),
                    textAlign: TextAlign.center,
                    style: AppTheme.jakartaSemiBold(size: 14),
                  ),
                  if (isToday)
                    Text(
                      _format(provider.selectedDate),
                      textAlign: TextAlign.center,
                      style: AppTheme.inter(
                          size: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ),
          _NavButton(
            icon: Icons.chevron_right_rounded,
            onPressed: isToday ? null : provider.nextDay,
            disabled: isToday,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Calorie ring hero card
// ─────────────────────────────────────────────────────────────────────────────

class _CalorieRingCard extends StatelessWidget {
  const _CalorieRingCard({required this.provider, required this.prefs});
  final DiaryProvider provider;
  final UserPrefsProvider prefs;

  @override
  Widget build(BuildContext context) {
    final goal = prefs.calorieGoal;
    final progress = goal > 0
        ? (provider.totalCalories / goal).clamp(0.0, 1.0)
        : 0.0;
    final over = provider.totalCalories > goal;
    final nc = NutritionColors.of(context);

    // Date badge label
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final dateBadge =
        '${provider.selectedDate.day} ${months[provider.selectedDate.month - 1]}';

    final ringColor = over ? SemanticColors.of(context).error : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: AppTheme.glassPanelHeavyDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text('Kalori Hari Ini', style: AppTheme.jakartaSemiBold(size: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: const Color(0xEBFFFFFF),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(dateBadge, style: AppTheme.inter(size: 12, color: AppTheme.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // Row: ring left + macro column right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 148,
                height: 148,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(148, 148),
                      painter: _RingPainter(
                        progress: progress,
                        ringColor: ringColor,
                        bgColor: const Color(0xFFE2E8F0),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          provider.totalCalories.toStringAsFixed(0),
                          style: AppTheme.digitStyle(size: 36, color: ringColor),
                        ),
                        Text('kkal', style: AppTheme.inter(size: 11, color: AppTheme.textMuted)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ringColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            over
                                ? '+${(provider.totalCalories - goal).toStringAsFixed(0)}'
                                : '${(goal - provider.totalCalories).toStringAsFixed(0)} sisa',
                            style: AppTheme.inter(size: 9, color: ringColor, weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MacroBentoTile(
                      label: 'Protein',
                      value: provider.totalProtein,
                      goal: prefs.proteinGoal > 0 ? prefs.proteinGoal : null,
                      color: nc.proteinColor,
                      icon: Icons.egg_alt_rounded,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _MacroBentoTile(
                      label: 'Karbo',
                      value: provider.totalCarbs,
                      goal: prefs.carbsGoal > 0 ? prefs.carbsGoal : null,
                      color: nc.carbsColor,
                      icon: Icons.rice_bowl_rounded,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _MacroBentoTile(
                      label: 'Lemak',
                      value: provider.totalFat,
                      goal: prefs.fatGoal > 0 ? prefs.fatGoal : null,
                      color: nc.fatColor,
                      icon: Icons.water_drop_rounded,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target ${goal.toStringAsFixed(0)} kkal',
                      style: AppTheme.inter(size: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroBentoTile extends StatelessWidget {
  const _MacroBentoTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.goal,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final double? goal;

  @override
  Widget build(BuildContext context) {
    final hasGoal = goal != null && goal! > 0;
    final progress = hasGoal ? (value / goal!).clamp(0.0, 1.0) : 0.0;

    return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const Spacer(),
                Text(
                  '${value.toStringAsFixed(0)}g',
                  style: AppTheme.digitStyle(size: 13, color: color),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: hasGoal ? progress : 0.0,
                minHeight: 4,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTheme.inter(size: 10, color: color.withValues(alpha: 0.8), weight: FontWeight.w500)),
          ],
        ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color bgColor;

  const _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 22.0;
    final radius = (size.width / 2) - strokeWidth / 2 - 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background ring
    paint.color = bgColor;
    canvas.drawCircle(center, radius, paint);

    // Progress arc
    paint.color = ringColor;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Weekly bar chart
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyChartCard extends StatelessWidget {
  const _WeeklyChartCard({required this.provider, required this.goal});
  final DiaryProvider provider;
  final double goal;

  static const _dayLabels = [
    'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final weeklyData = provider.weeklyCalories;

    if (provider.weeklyLoading && weeklyData.isEmpty) {
      return Container(
        height: 120,
        decoration: AppTheme.glassPanelDecoration(radius: AppRadius.large),
        child: const Center(
            child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (weeklyData.isEmpty) return const SizedBox.shrink();

    final today = DateTime.now();
    final days =
        List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final values = days
        .map((d) => weeklyData[DiaryEntry.dateKeyOf(d)] ?? 0.0)
        .toList();
    final maxVal = [...values, goal].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: AppTheme.glassPanelDecoration(radius: AppRadius.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                'Riwayat 7 Hari',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          SizedBox(
            height: 96,
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final date = days[i];
                    final calories = values[i];
                    final isToday = DateUtils.isSameDay(date, today);
                    final reachedGoal = goal > 0 && calories >= goal;
                    final barRatio =
                        maxVal > 0 ? (calories / maxVal).clamp(0.0, 1.0) : 0.0;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              calories > 0
                                  ? (calories >= 1000
                                      ? '${(calories / 1000).toStringAsFixed(1)}k'
                                      : calories.toStringAsFixed(0))
                                  : '',
                              style: TextStyle(
                                fontSize: 8,
                                color: isToday
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                              child: Container(
                                height: barRatio > 0
                                    ? (60 * barRatio).clamp(3.0, 60.0)
                                    : 2,
                                color: isToday
                                    ? scheme.primary
                                    : reachedGoal
                                        ? scheme.tertiary
                                        : scheme.primaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dayLabels[date.weekday - 1],
                              style: TextStyle(
                                fontSize: 10,
                                color: isToday
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                // Horizontal dashed target line
                if (goal > 0 && maxVal > 0)
                  Positioned(
                    bottom: 14 + (60 * (goal / maxVal).clamp(0.0, 1.0)),
                    left: 0,
                    right: 0,
                    child: Row(
                      children: List.generate(
                        14,
                        (i) => Expanded(
                          child: Container(
                            height: 1,
                            color: i.isEven
                                ? AppTheme.primary.withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              _LegendDot(color: scheme.primary, label: 'Hari ini'),
              const SizedBox(width: 12),
              _LegendDot(color: scheme.tertiary, label: 'Capai target'),
              const SizedBox(width: 12),
              _LegendDot(
                  color: scheme.primaryContainer, label: 'Lainnya'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meal section card — flat card, no ExpansionTile
// ─────────────────────────────────────────────────────────────────────────────

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.mealType,
    required this.entries,
    required this.selectedDate,
  });

  final MealType mealType;
  final List<DiaryEntry> entries;
  final DateTime selectedDate;

  Color get _accentColor => switch (mealType) {
        MealType.breakfast => const Color(0xFFF97316), // orange-500
        MealType.lunch     => const Color(0xFFEAB308), // yellow-500
        MealType.dinner    => const Color(0xFF6366F1), // indigo-500
        MealType.snack     => const Color(0xFF10B981), // emerald-500
      };

  @override
  Widget build(BuildContext context) {
    final mealTotal = entries.fold(0.0, (s, e) => s + e.totalCalories);
    final accent = _accentColor;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE8F5E9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Left accent strip
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(width: 4, color: accent),
          ),
          // Content (shift right past accent strip)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.m, AppSpacing.s, AppSpacing.xs, AppSpacing.s),
                  child: Row(
                    children: [
                      Text(mealType.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        mealType.label,
                        style: AppTheme.jakartaSemiBold(size: 14, color: accent),
                      ),
                      const Spacer(),
                      if (entries.isNotEmpty) ...[
                        Text(
                          '${mealTotal.toStringAsFixed(0)} kkal',
                          style: AppTheme.digitStyle(size: 13, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 4),
                      ],
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 20),
                        tooltip: 'Tambah makanan',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddEntryScreen(
                              initialMealType: mealType,
                              initialDate: selectedDate,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Entries ───────────────────────────────────────────────────
                if (entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                        left: AppSpacing.m,
                        right: AppSpacing.m,
                        bottom: AppSpacing.s),
                    child: Text(
                      'Belum ada makanan',
                      style: AppTheme.inter(size: 13, color: AppTheme.textMuted),
                    ),
                  )
                else ...[
                  Divider(height: 1, color: accent.withValues(alpha: 0.15)),
                  ...entries.map((e) => _EntryRow(entry: e)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry row — swipe-to-delete + edit link, no ExpansionTile
// ─────────────────────────────────────────────────────────────────────────────

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});
  final DiaryEntry entry;

  String _servingsLabel(double s) =>
      s == s.truncateToDouble() ? '${s.toInt()}x' : '${s}x';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final servings = _servingsLabel(entry.servings);
    final grams = (entry.servingSizeG * entry.servings).toStringAsFixed(0);
    final calories = entry.totalCalories.toStringAsFixed(0);

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: scheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.m),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Hapus catatan?'),
          content: Text('"${entry.foodName}" akan dihapus dari jurnal.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        context.read<DiaryProvider>().deleteEntry(entry.id).catchError((e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal menghapus: $e')),
            );
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.foodName,
                    style: AppTheme.inter(size: 14, color: AppTheme.charcoal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$servings · ${grams}g',
                    style: AppTheme.inter(size: 12, color: AppTheme.textSecondary),
                  ),
                  Text(
                    'P ${entry.totalProtein.toStringAsFixed(0)}g · '
                    'K ${entry.totalCarbs.toStringAsFixed(0)}g · '
                    'L ${entry.totalFat.toStringAsFixed(0)}g',
                    style: AppTheme.inter(size: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$calories kkal',
                  style: AppTheme.digitStyle(
                      size: 13, color: AppTheme.primary),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEntryScreen(
                        initialMealType: entry.mealType,
                        initialDate: entry.date,
                        existingEntry: entry,
                      ),
                    ),
                  ),
                  child: Text(
                    'Edit',
                    style: AppTheme.inter(size: 11).copyWith(
                        color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav button helper for DateBar
// ─────────────────────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  const _NavButton(
      {required this.icon, this.onPressed, this.disabled = false});
  final IconData icon;
  final VoidCallback? onPressed;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        size: 20,
        color: disabled ? AppTheme.creamyBorder : AppTheme.charcoal,
      ),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xD1FFFFFF),
        shape: const CircleBorder(),
        side: const BorderSide(color: Color(0xB3FFFFFF)),
        padding: const EdgeInsets.all(AppSpacing.xs),
        minimumSize: const Size(36, 36),
      ),
    );
  }
}
