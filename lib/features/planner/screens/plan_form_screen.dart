import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../features/scanner/providers/food_library_provider.dart';
import '../models/meal_plan.dart';
import '../providers/meal_plan_provider.dart';

/// Dipakai untuk CREATE (plan == null) maupun UPDATE (plan != null).
class PlanFormScreen extends StatefulWidget {
  const PlanFormScreen({super.key, this.plan});

  final MealPlan? plan;

  @override
  State<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends State<PlanFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _scheduledDate;
  late TimeOfDay _scheduledTime;
  late MealType _mealType;
  late bool _reminderEnabled;

  // Pilihan makanan: salah satu dari dua
  String? _selectedFoodId;   // dari library
  late TextEditingController _customNameCtrl;

  bool _saving = false;

  // ── Lifecycle ────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    final now = DateTime.now().add(const Duration(hours: 1));
    _scheduledDate = p?.scheduledAt ?? now;
    _scheduledTime = TimeOfDay.fromDateTime(p?.scheduledAt ?? now);
    _mealType = p?.mealType ?? MealType.lunch;
    _reminderEnabled = p?.reminderEnabled ?? true;
    _selectedFoodId = p?.foodItemId;
    _customNameCtrl = TextEditingController(text: p?.customName ?? '');
  }

  @override
  void dispose() {
    _customNameCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────
  DateTime get _combined => DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
        _scheduledTime.hour,
        _scheduledTime.minute,
      );

  bool get _useCustomName => _selectedFoodId == null;

  // ── Pickers ──────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (picked != null) setState(() => _scheduledTime = picked);
  }

  // ── Save ─────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi: harus ada nama atau food dari library
    if (_useCustomName && _customNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama makanan atau pilih dari library.')),
      );
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<MealPlanProvider>();

    try {
      if (widget.plan == null) {
        // CREATE
        await provider.add(
          scheduledAt: _combined,
          mealType: _mealType,
          foodItemId: _selectedFoodId,
          customName: _useCustomName ? _customNameCtrl.text.trim() : null,
          reminderEnabled: _reminderEnabled,
        );
      } else {
        // UPDATE
        final updated = widget.plan!.copyWith(
          foodItemId: _selectedFoodId,
          customName: _useCustomName ? _customNameCtrl.text.trim() : null,
          scheduledAt: _combined,
          mealType: _mealType,
          reminderEnabled: _reminderEnabled,
          updatedAt: DateTime.now(),
          clearFoodItemId: _useCustomName,
          clearCustomName: !_useCustomName,
        );
        await provider.update(updated);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.plan != null;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Rencana Makan' : 'Tambah Rencana Makan'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Simpan'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Tipe makan ──────────────────────────────────
            _SectionLabel('Tipe Makan'),
            _MealTypeSelector(
              selected: _mealType,
              onChanged: (v) => setState(() => _mealType = v),
            ),

            const SizedBox(height: 20),

            // ── Tanggal & Jam ────────────────────────────────
            _SectionLabel('Jadwal'),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today_outlined,
                    label: DateFormat('EEE, d MMM yyyy', 'id_ID').format(_scheduledDate),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.access_time_outlined,
                    label: _scheduledTime.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Makanan ──────────────────────────────────────
            _SectionLabel('Makanan'),
            _FoodSelector(
              selectedFoodId: _selectedFoodId,
              customNameCtrl: _customNameCtrl,
              onFoodSelected: (id) => setState(() {
                _selectedFoodId = id;
                if (id != null) _customNameCtrl.clear();
              }),
              onClearFood: () => setState(() => _selectedFoodId = null),
            ),

            const SizedBox(height: 20),

            // ── Reminder toggle ──────────────────────────────
            _SectionLabel('Pengingat'),
            Card(
              child: SwitchListTile(
                secondary: Icon(
                  Icons.notifications_outlined,
                  color: cs.primary,
                ),
                title: const Text('Aktifkan Reminder'),
                subtitle: Text(
                  _reminderEnabled
                      ? 'Notifikasi akan muncul pada ${_scheduledTime.format(context)}'
                      : 'Notifikasi dinonaktifkan',
                ),
                value: _reminderEnabled,
                onChanged: (v) => setState(() => _reminderEnabled = v),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Widget helpers ───────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      );
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(label, style: const TextStyle(fontSize: 14)),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      );
}

class _MealTypeSelector extends StatelessWidget {
  const _MealTypeSelector({required this.selected, required this.onChanged});
  final MealType selected;
  final ValueChanged<MealType> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: MealType.values.map((type) {
        final isSelected = type == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primaryContainer : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: cs.primary, width: 2)
                      : null,
                ),
                child: Column(
                  children: [
                    Text(type.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(
                      type.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FoodSelector extends StatelessWidget {
  const _FoodSelector({
    required this.selectedFoodId,
    required this.customNameCtrl,
    required this.onFoodSelected,
    required this.onClearFood,
  });

  final String? selectedFoodId;
  final TextEditingController customNameCtrl;
  final ValueChanged<String?> onFoodSelected;
  final VoidCallback onClearFood;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<FoodLibraryProvider>();
    final selectedFood = selectedFoodId != null
        ? library.findById(selectedFoodId!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pilih dari library
        if (selectedFood != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.fastfood_outlined),
              title: Text(selectedFood.name),
              subtitle: Text(
                '${selectedFood.calories.toStringAsFixed(0)} kcal · ${selectedFood.servingSize.toStringAsFixed(0)}g',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClearFood,
              ),
            ),
          )
        else ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text('Pilih dari Food Library'),
            onPressed: () async {
              final id = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                builder: (_) => _FoodPickerSheet(library: library),
              );
              if (id != null) onFoodSelected(id);
            },
          ),
          const SizedBox(height: 12),
          const Text('— atau masukkan nama manual —',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          TextFormField(
            controller: customNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nama makanan',
              hintText: 'Mis. Nasi Goreng Spesial',
              prefixIcon: Icon(Icons.edit_outlined),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ],
    );
  }
}

class _FoodPickerSheet extends StatefulWidget {
  const _FoodPickerSheet({required this.library});
  final FoodLibraryProvider library;

  @override
  State<_FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends State<_FoodPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.library.items
        .where((f) => f.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Cari makanan',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (widget.library.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('Library makanan kosong.\nTambahkan lewat tab Scanner.', textAlign: TextAlign.center),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final food = filtered[i];
                  return ListTile(
                    title: Text(food.name),
                    subtitle: Text('${food.calories.toStringAsFixed(0)} kcal'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pop(food.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
