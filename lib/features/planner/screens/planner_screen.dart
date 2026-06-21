import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/semantic_colors.dart';

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
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom,
        ),
        child: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text('Tambah Rencana'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PlanFormScreen()),
          ),
        ),
      ),
      body: Container(
        decoration: AppTheme.meshBackgroundDecoration,
        child: const _PlannerBody(),
      ),
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
            Icon(Icons.error_outline, size: 48, color: SemanticColors.of(context).error),
            const SizedBox(height: AppSpacing.xs),
            Text(provider.error!),
            const SizedBox(height: AppSpacing.xs),
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
      padding: const EdgeInsets.only(bottom: 120),
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_outlined, size: 72, color: cs.outlineVariant),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Belum ada rencana makan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tekan tombol + untuk menambahkan\njadwal makan dan pengingat.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.outline),
            ),
            const SizedBox(height: AppSpacing.m),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlanFormScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('+ Buat Rencana Makan'),
            ),
          ],
        ),
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
          padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.m, AppSpacing.m, AppSpacing.xs),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isToday ? cs.primary : AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  isToday
                      ? 'Hari ini'
                      : DateFormat('EEE, d MMM yyyy', 'id_ID').format(date),
                  style: AppTheme.jakartaSemiBold(size: 13).copyWith(
                    color: isToday ? cs.onPrimary : AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${plans.length} rencana',
                style: AppTheme.inter(size: 12, color: AppTheme.textMuted),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
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
      child: Opacity(
        opacity: isPast ? 0.55 : 1.0,
        child: Card(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xxs),
        child: ListTile(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: plan)),
          ),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFD1FAE5),
            child: Text(
              plan.mealType.emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          title: Text(
            plan.displayName,
            style: AppTheme.jakartaSemiBold(size: 13).copyWith(
              color: isPast ? AppTheme.textMuted : AppTheme.charcoal,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(Icons.access_time, size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                DateFormat('HH:mm').format(plan.scheduledAt),
                style: AppTheme.digitStyle(size: 12, color: AppTheme.primary).copyWith(
                  decoration: isPast ? TextDecoration.lineThrough : null,
                ),
              ),
              if (isPast) ...[
                const SizedBox(width: 6),
                Text(
                  'Lewat',
                  style: AppTheme.inter(size: 11, color: AppTheme.textMuted),
                ),
              ],
              const SizedBox(width: 12),
              Icon(Icons.restaurant_outlined, size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                plan.mealType.label,
                style: AppTheme.inter(size: 12, color: AppTheme.textSecondary),
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
      ),
    );
  }
}
