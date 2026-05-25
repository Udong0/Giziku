import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/meal_plan.dart';
import '../providers/meal_plan_provider.dart';
import 'plan_detail_screen.dart';
import 'plan_form_screen.dart';

/// Owned by Member 3 (Meal Planner & Reminder).
/// Menggantikan PlaceholderTab yang sebelumnya ada.
class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Tambah Rencana'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PlanFormScreen()),
        ),
      ),
      body: const _PlannerBody(),
    );
  }
}

class _PlannerBody extends StatelessWidget {
  const _PlannerBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealPlanProvider>();

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(provider.error!),
            const SizedBox(height: 8),
            TextButton(
              onPressed: provider.load,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    if (provider.isEmpty) {
      return _EmptyState();
    }

    final dates = provider.distinctDates;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100), // ruang FAB
      itemCount: dates.length,
      itemBuilder: (_, i) => _DaySection(date: dates[i], provider: provider),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_month_outlined, size: 72, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Belum ada rencana makan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol + untuk menambahkan\njadwal makan dan pengingat.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.outline),
          ),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.date, required this.provider});

  final DateTime date;
  final MealPlanProvider provider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final plans = provider.plansForDate(date);
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tanggal header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isToday ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isToday
                      ? 'Hari ini'
                      : DateFormat('EEE, d MMM yyyy', 'id_ID').format(date),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isToday ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${plans.length} rencana',
                style: TextStyle(fontSize: 12, color: cs.outline),
              ),
            ],
          ),
        ),

        // Kartu per rencana
        ...plans.map((plan) => _PlanCard(plan: plan)),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final MealPlan plan;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPast = plan.scheduledAt.isBefore(DateTime.now());

    return Dismissible(
      key: ValueKey(plan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: cs.errorContainer,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete_outline, color: cs.error),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Rencana?'),
            content: Text('Hapus "${plan.displayName}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Batal')),
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: TextButton.styleFrom(foregroundColor: cs.error),
                  child: const Text('Hapus')),
            ],
          ),
        );
      },
      onDismissed: (_) => context.read<MealPlanProvider>().delete(plan.id),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: plan)),
          ),
          leading: CircleAvatar(
            backgroundColor: isPast
                ? cs.surfaceContainerHighest
                : cs.primaryContainer,
            child: Text(
              plan.mealType.emoji,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          title: Text(
            plan.displayName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isPast ? cs.outline : null,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(Icons.access_time, size: 12, color: cs.outline),
              const SizedBox(width: 4),
              Text(
                DateFormat('HH:mm').format(plan.scheduledAt),
                style: TextStyle(fontSize: 12, color: cs.outline),
              ),
              const SizedBox(width: 12),
              Icon(Icons.restaurant_outlined, size: 12, color: cs.outline),
              const SizedBox(width: 4),
              Text(
                plan.mealType.label,
                style: TextStyle(fontSize: 12, color: cs.outline),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (plan.reminderEnabled)
                Icon(Icons.notifications_active_outlined,
                    size: 16, color: cs.primary),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
