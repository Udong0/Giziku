import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      body: Column(
        children: [
          _DateBar(provider: provider),
          if (provider.loading) const LinearProgressIndicator(),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                provider.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              children: [
                _CalorieSummaryCard(provider: provider, prefs: prefs),
                const SizedBox(height: 12),
                _WeeklyChartCard(provider: provider, goal: prefs.calorieGoal),
                const SizedBox(height: 16),
                for (final meal in MealType.values) ...[
                  _MealSection(
                    mealType: meal,
                    entries: provider.entriesForMeal(meal),
                    selectedDate: provider.selectedDate,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, DiaryProvider provider) async {
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
    final scheme = Theme.of(context).colorScheme;
    final isToday = DateUtils.isSameDay(provider.selectedDate, DateTime.now());

    return Container(
      color: scheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: scheme.onPrimaryContainer),
            onPressed: provider.previousDay,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  isToday ? 'Hari Ini' : _format(provider.selectedDate),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (isToday)
                  Text(
                    _format(provider.selectedDate),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: isToday
                  ? scheme.onPrimaryContainer.withValues(alpha: 0.3)
                  : scheme.onPrimaryContainer,
            ),
            onPressed: isToday ? null : provider.nextDay,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Calorie summary card
// ─────────────────────────────────────────────────────────────────────────────

class _CalorieSummaryCard extends StatelessWidget {
  const _CalorieSummaryCard({required this.provider, required this.prefs});
  final DiaryProvider provider;
  final UserPrefsProvider prefs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final goal = prefs.calorieGoal;
    final progress = (provider.totalCalories / goal).clamp(0.0, 1.0);
    final over = provider.totalCalories > goal;

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
              Icon(Icons.local_fire_department,
                  color: scheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                'Ringkasan Kalori',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                provider.totalCalories.toStringAsFixed(0),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '/ ${goal.toStringAsFixed(0)} kkal',
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: scheme.surface.withValues(alpha: 0.3),
              color: over ? Colors.orange : scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            over
                ? 'Melebihi target ${(provider.totalCalories - goal).toStringAsFixed(0)} kkal'
                : '${(goal - provider.totalCalories).toStringAsFixed(0)} kkal tersisa',
            style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MacroChip(
                label: 'Protein',
                value: provider.totalProtein,
                goal: prefs.proteinGoal > 0 ? prefs.proteinGoal : null,
              ),
              const SizedBox(width: 8),
              _MacroChip(
                label: 'Karbo',
                value: provider.totalCarbs,
                goal: prefs.carbsGoal > 0 ? prefs.carbsGoal : null,
              ),
              const SizedBox(width: 8),
              _MacroChip(
                label: 'Lemak',
                value: provider.totalFat,
                goal: prefs.fatGoal > 0 ? prefs.fatGoal : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.label, required this.value, this.goal});
  final String label;
  final double value;
  final double? goal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasGoal = goal != null && goal! > 0;
    final progress = hasGoal ? (value / goal!).clamp(0.0, 1.0) : null;
    final over = hasGoal && value > goal!;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '${value.toStringAsFixed(1)} g',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.onPrimaryContainer,
                fontSize: 13,
              ),
            ),
            if (hasGoal)
              Text(
                '/ ${goal!.toStringAsFixed(0)} g',
                style: TextStyle(
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                  fontSize: 9,
                ),
              ),
            Text(
              label,
              style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 11),
            ),
            if (progress != null) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: scheme.surface.withValues(alpha: 0.4),
                  color: over ? Colors.orange : scheme.onPrimaryContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Weekly bar chart
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyChartCard extends StatelessWidget {
  const _WeeklyChartCard({required this.provider, required this.goal});
  final DiaryProvider provider;
  final double goal;

  static const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final weeklyData = provider.weeklyCalories;

    if (provider.weeklyLoading && weeklyData.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (weeklyData.isEmpty) return const SizedBox.shrink();

    final today = DateTime.now();
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final values = days.map((d) => weeklyData[DiaryEntry.dateKeyOf(d)] ?? 0.0).toList();
    final maxVal = [...values, goal].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                'Riwayat 7 Hari',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final date = days[i];
                final calories = values[i];
                final isToday = DateUtils.isSameDay(date, today);
                final reachedGoal = goal > 0 && calories >= goal;
                final barRatio = maxVal > 0 ? (calories / maxVal).clamp(0.0, 1.0) : 0.0;

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
                            color: isToday ? scheme.primary : scheme.onSurfaceVariant,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          child: Container(
                            height: barRatio > 0 ? (60 * barRatio).clamp(3.0, 60.0) : 2,
                            color: isToday
                                ? scheme.primary
                                : reachedGoal
                                    ? Colors.green.shade400
                                    : scheme.primaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dayLabels[date.weekday - 1],
                          style: TextStyle(
                            fontSize: 10,
                            color: isToday ? scheme.primary : scheme.onSurfaceVariant,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _LegendDot(color: scheme.primary, label: 'Hari ini'),
              const SizedBox(width: 12),
              _LegendDot(color: Colors.green.shade400, label: 'Capai target'),
              const SizedBox(width: 12),
              _LegendDot(color: scheme.primaryContainer, label: 'Lainnya'),
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
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meal section card
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

  IconData get _icon => switch (mealType) {
        MealType.breakfast => Icons.wb_sunny_outlined,
        MealType.lunch     => Icons.wb_sunny,
        MealType.dinner    => Icons.nights_stay_outlined,
        MealType.snack     => Icons.local_cafe_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mealTotal    = entries.fold(0.0, (s, e) => s + e.totalCalories);
    final mealProtein  = entries.fold(0.0, (s, e) => s + e.totalProtein);
    final mealCarbs    = entries.fold(0.0, (s, e) => s + e.totalCarbs);
    final mealFat      = entries.fold(0.0, (s, e) => s + e.totalFat);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(_icon, color: scheme.primary),
            title: Text(
              mealType.label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: entries.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${mealTotal.toStringAsFixed(0)} kkal'),
                      Text(
                        'P ${mealProtein.toStringAsFixed(0)}g · '
                        'K ${mealCarbs.toStringAsFixed(0)}g · '
                        'L ${mealFat.toStringAsFixed(0)}g',
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  )
                : null,
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Tambah makanan',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEntryScreen(
                    initialMealType: mealType,
                    initialDate: selectedDate,
                  ),
                ),
              ),
            ),
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Belum ada — ketuk + untuk menambah makanan',
                style: TextStyle(color: scheme.outline, fontSize: 13),
              ),
            )
          else ...[
            const Divider(height: 1),
            ...entries.map((e) => _EntryTile(entry: e)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry tile — expandable detail + swipe-to-delete
// ─────────────────────────────────────────────────────────────────────────────

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});
  final DiaryEntry entry;

  String _servingsLabel(double s) =>
      s == s.truncateToDouble() ? '${s.toInt()}x' : '${s}x';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: scheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
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
      onDismissed: (_) => context.read<DiaryProvider>().deleteEntry(entry.id),
      child: ExpansionTile(
        controlAffinity: ListTileControlAffinity.leading,
        tilePadding: const EdgeInsets.only(left: 8, right: 16),
        title: Text(entry.foodName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${_servingsLabel(entry.servings)} · '
          '${(entry.servingSizeG * entry.servings).toStringAsFixed(0)} g',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${entry.totalCalories.toStringAsFixed(0)} kkal',
          style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    _MacroDetail('Protein', entry.totalProtein, Colors.blue.shade300),
                    _MacroDetail('Karbo', entry.totalCarbs, Colors.amber.shade500),
                    _MacroDetail('Lemak', entry.totalFat, Colors.orange.shade400),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddEntryScreen(
                            initialMealType: entry.mealType,
                            initialDate: entry.date,
                            existingEntry: entry,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      icon: Icon(Icons.delete_outline, size: 16, color: scheme.error),
                      label: Text('Hapus', style: TextStyle(color: scheme.error)),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
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
                        );
                        if (ok == true && context.mounted) {
                          context.read<DiaryProvider>().deleteEntry(entry.id);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroDetail extends StatelessWidget {
  const _MacroDetail(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text('gram', style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}