import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/meal_plan_repository.dart';
import '../models/meal_plan.dart';
import '../services/notification_service.dart';

class MealPlanProvider extends ChangeNotifier {
  MealPlanProvider(this._repo);

  final MealPlanRepository _repo;

  List<MealPlan> _items = const [];
  bool _loading = false;
  String? _error;

  List<MealPlan> get items => _items;
  bool get loading => _loading;
  String? get error => _error;
  bool get isEmpty => !_loading && _items.isEmpty;

  // ── Load ─────────────────────────────────────────────────────
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _repo.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Grouped helpers ──────────────────────────────────────────

  /// Semua rencana pada [day] (date saja, jam diabaikan untuk grouping).
  List<MealPlan> plansForDate(DateTime day) {
    final d = DateOnly(day);
    return _items.where((p) => DateOnly(p.scheduledAt) == d).toList();
  }

  /// Daftar tanggal unik yang punya rencana, diurutkan ascending.
  List<DateTime> get distinctDates {
    final dates = _items.map((p) => DateOnly(p.scheduledAt).toDateTime()).toSet().toList()
      ..sort();
    return dates;
  }

  // ── CRUD ─────────────────────────────────────────────────────

  Future<void> add({
    required DateTime scheduledAt,
    required MealType mealType,
    String? foodItemId,
    String? customName,
    bool reminderEnabled = true,
  }) async {
    int? notifId;

    final plan = MealPlan(
      id: const Uuid().v4(),
      foodItemId: foodItemId,
      customName: customName,
      scheduledAt: scheduledAt,
      mealType: mealType,
      reminderEnabled: reminderEnabled,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (reminderEnabled && scheduledAt.isAfter(DateTime.now())) {
      notifId = scheduledAt.millisecondsSinceEpoch ~/ 1000 & 0x7FFFFFFF;
      try {
        await NotificationService.instance.schedule(
          id: notifId,
          title: '${mealType.emoji} Saatnya ${mealType.label}!',
          body: plan.displayName,
          scheduledDate: scheduledAt,
        );
      } catch (e) {
        debugPrint('[MealPlanProvider] Gagal schedule notif: $e');
        notifId = null;
      }
    }

    final planWithNotif = plan.copyWith(notificationId: notifId);
    await _repo.add(planWithNotif);
    await load();
  }

  Future<void> update(MealPlan updated) async {
    // Batalkan notif lama sebelum re-schedule
    final old = await _repo.getById(updated.id);
    if (old?.notificationId != null) {
      await NotificationService.instance.cancel(old!.notificationId!);
    }

    int? notifId;
    if (updated.reminderEnabled && updated.scheduledAt.isAfter(DateTime.now())) {
      notifId = updated.scheduledAt.millisecondsSinceEpoch ~/ 1000 & 0x7FFFFFFF;
      try {
        await NotificationService.instance.schedule(
          id: notifId,
          title: '${updated.mealType.emoji} Saatnya ${updated.mealType.label}!',
          body: updated.displayName,
          scheduledDate: updated.scheduledAt,
        );
      } catch (e) {
        debugPrint('[MealPlanProvider] Gagal re-schedule notif: $e');
        notifId = null;
      }
    }

    await _repo.update(
      updated.copyWith(
        notificationId: notifId,
        updatedAt: DateTime.now(),
        clearNotificationId: notifId == null,
      ),
    );
    await load();
  }

  Future<void> delete(String id) async {
    // Wajib cancel notif sebelum hapus
    final plan = await _repo.getById(id);
    if (plan?.notificationId != null) {
      await NotificationService.instance.cancel(plan!.notificationId!);
    }
    await _repo.delete(id);
    await load();
  }

  MealPlan? findById(String id) {
    for (final p in _items) {
      if (p.id == id) return p;
    }
    return null;
  }
}

// ── Helper kelas untuk perbandingan tanggal tanpa jam ────────
class DateOnly implements Comparable<DateOnly> {
  final int year, month, day;

  DateOnly(DateTime dt)
      : year = dt.year,
        month = dt.month,
        day = dt.day;

  DateTime toDateTime() => DateTime(year, month, day);

  @override
  bool operator ==(Object other) =>
      other is DateOnly && year == other.year && month == other.month && day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  int compareTo(DateOnly other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }
}
