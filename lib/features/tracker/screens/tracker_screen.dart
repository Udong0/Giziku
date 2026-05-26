import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diary_entry.dart';
import '../providers/diary_provider.dart';
import 'add_entry_screen.dart';

/// READ — tampilan utama jurnal harian (tab Tracker).
class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();

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
                _CalorieSummaryCard(provider: provider),
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
// Calorie summary card (gaya card hijau ala scanner_home_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

class _CalorieSummaryCard extends StatelessWidget {
  const _CalorieSummaryCard({required this.provider});
  final DiaryProvider provider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress =
        (provider.totalCalories / DiaryProvider.calorieGoal).clamp(0.0, 1.0);
    final over = provider.totalCalories > DiaryProvider.calorieGoal;

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
                  '/ ${DiaryProvider.calorieGoal.toStringAsFixed(0)} kkal',
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
                ? 'Melebihi target ${(provider.totalCalories - DiaryProvider.calorieGoal).toStringAsFixed(0)} kkal'
                : '${(DiaryProvider.calorieGoal - provider.totalCalories).toStringAsFixed(0)} kkal tersisa',
            style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MacroChip(label: 'Protein', value: provider.totalProtein),
              const SizedBox(width: 8),
              _MacroChip(label: 'Karbo', value: provider.totalCarbs),
              const SizedBox(width: 8),
              _MacroChip(label: 'Lemak', value: provider.totalFat),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style:
                  TextStyle(color: scheme.onPrimaryContainer, fontSize: 11),
            ),
          ],
        ),
      ),
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
        MealType.lunch => Icons.wb_sunny,
        MealType.dinner => Icons.nights_stay_outlined,
        MealType.snack => Icons.local_cafe_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mealTotal = entries.fold(0.0, (s, e) => s + e.totalCalories);

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
                ? Text('${mealTotal.toStringAsFixed(0)} kkal')
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
// Entry tile (READ + entry point UPDATE / DELETE)
// ─────────────────────────────────────────────────────────────────────────────

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});
  final DiaryEntry entry;

  String _servingsLabel(double s) =>
      s == s.truncateToDouble() ? '${s.toInt()}x' : '${s}x';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(entry.foodName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${_servingsLabel(entry.servings)} · '
        '${(entry.servingSizeG * entry.servings).toStringAsFixed(0)} g',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${entry.totalCalories.toStringAsFixed(0)} kkal',
            style: TextStyle(
                color: scheme.primary, fontWeight: FontWeight.w600),
          ),
          PopupMenuButton<_Action>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (action) => _onAction(context, action),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Action.edit, child: Text('Edit Porsi')),
              PopupMenuItem(value: _Action.delete, child: Text('Hapus')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onAction(BuildContext context, _Action action) async {
    if (action == _Action.edit) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddEntryScreen(
            initialMealType: entry.mealType,
            initialDate: entry.date,
            existingEntry: entry,
          ),
        ),
      );
      return;
    }

    // DELETE
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
    if (ok != true || !context.mounted) return;
    await context.read<DiaryProvider>().deleteEntry(entry.id);
  }
}

enum _Action { edit, delete }