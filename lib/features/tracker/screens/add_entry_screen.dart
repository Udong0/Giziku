import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

import '../../../features/scanner/models/food_item.dart';
import '../../../features/scanner/providers/food_library_provider.dart';
import '../../../features/scanner/screens/food_form.dart';
import '../models/diary_entry.dart';
import '../providers/diary_provider.dart';


/// CREATE (tambah makanan baru ke jurnal) dan UPDATE (edit porsi / detail).
///
/// Jika [existingEntry] null → mode CREATE dengan TabBar dua tab:
///   - "Dari Koleksi": cari & pilih dari FoodLibraryProvider.
///   - "Manual": isi form gizi sendiri (reuse FoodFormController).
/// Jika [existingEntry] terisi → mode UPDATE: tampilkan form pre-filled.
class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({
    super.key,
    required this.initialMealType,
    required this.initialDate,
    this.existingEntry,
  });

  final MealType initialMealType;
  final DateTime initialDate;
  final DiaryEntry? existingEntry;

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen>
    with SingleTickerProviderStateMixin {
  late MealType _mealType;
  double _servings = 1.0;
  String? _linkedFoodItemId;

  late TabController _tabController;
  late FoodFormController _form;

  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    _mealType = widget.initialMealType;
    _tabController = TabController(length: 2, vsync: this);

    final e = widget.existingEntry;
    if (e != null) {
      _servings = e.servings;
      _mealType = e.mealType;
      _linkedFoodItemId = e.foodItemId;
      _form = FoodFormController(
        name: TextEditingController(text: e.foodName),
        description: TextEditingController(),
        calories: TextEditingController(
            text: e.caloriesPerServing.toStringAsFixed(0)),
        protein: TextEditingController(
            text: e.proteinPerServing.toStringAsFixed(1)),
        carbs: TextEditingController(
            text: e.carbsPerServing.toStringAsFixed(1)),
        fat:
            TextEditingController(text: e.fatPerServing.toStringAsFixed(1)),
        servingSize:
            TextEditingController(text: e.servingSizeG.toStringAsFixed(0)),
      );
    } else {
      _form = FoodFormController.blank();
    }

    _form.calories.addListener(_onCaloriesChanged);
  }

  void _onCaloriesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _form.calories.removeListener(_onCaloriesChanged);
    _tabController.dispose();
    _form.dispose();
    super.dispose();
  }

  /// Dipanggil dari tab "Dari Koleksi" → isi form & pindah ke tab Manual.
  void _fillFromLibrary(FoodItem item) {
    setState(() {
      _linkedFoodItemId = item.id;
      _form.name.text = item.name;
      _form.calories.text = item.calories.toStringAsFixed(0);
      _form.protein.text = item.protein.toStringAsFixed(1);
      _form.carbs.text = item.carbs.toStringAsFixed(1);
      _form.fat.text = item.fat.toStringAsFixed(1);
      _form.servingSize.text = item.servingSize.toStringAsFixed(0);
    });
    _tabController.animateTo(1);
  }

  double get _previewCalories {
    final cal =
        double.tryParse(_form.calories.text.replaceAll(',', '.')) ?? 0;
    return cal * _servings;
  }

  Future<void> _save() async {
    final draft = _form.toDraft();
    if (draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama makanan tidak boleh kosong')),
      );
      return;
    }

    final now = DateTime.now();
    final provider = context.read<DiaryProvider>();

    try {
      if (_isEditing) {
        final updated = widget.existingEntry!.copyWith(
          foodName: draft.name,
          mealType: _mealType,
          servings: _servings,
          caloriesPerServing: draft.calories,
          proteinPerServing: draft.protein,
          carbsPerServing: draft.carbs,
          fatPerServing: draft.fat,
          servingSizeG: draft.servingSize,
          updatedAt: now,
        );
        await provider.updateEntry(updated);
      } else {
        final entry = DiaryEntry(
          id: const Uuid().v4(),
          foodItemId: _linkedFoodItemId,
          foodName: draft.name,
          date: widget.initialDate,
          mealType: _mealType,
          servings: _servings,
          caloriesPerServing: draft.calories,
          proteinPerServing: draft.protein,
          carbsPerServing: draft.carbs,
          fatPerServing: draft.fat,
          servingSizeG: draft.servingSize,
          createdAt: now,
          updatedAt: now,
        );
        await provider.addEntry(entry);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? 'Catatan diperbarui'
              : 'Makanan ditambahkan ke jurnal',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final libraryItems = context.watch<FoodLibraryProvider>().items;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Catatan' : 'Tambah Makanan'),
        bottom: _isEditing
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.collections_bookmark_outlined), text: 'Dari Koleksi'),
                  Tab(icon: Icon(Icons.edit_note), text: 'Manual'),
                ],
              ),
      ),
      body: _isEditing
          ? _EditBody(
              form: _form,
              mealType: _mealType,
              servings: _servings,
              previewCalories: _previewCalories,
              onMealTypeChanged: (t) => setState(() => _mealType = t),
              onServingsChanged: (s) => setState(() => _servings = s),
              onSave: _save,
              showMealChips: false,
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 0: Dari Koleksi
                _LibraryTab(
                  items: libraryItems,
                  onSelect: _fillFromLibrary,
                ),
                // Tab 1: Input Manual
                _ManualBody(
                  form: _form,
                  mealType: _mealType,
                  servings: _servings,
                  previewCalories: _previewCalories,
                  onMealTypeChanged: (t) => setState(() => _mealType = t),
                  onServingsChanged: (s) => setState(() => _servings = s),
                  onSave: _save,
                  showMealChips: false,
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab "Dari Koleksi" — pilih makanan dari FoodLibraryProvider
// ─────────────────────────────────────────────────────────────────────────────

class _LibraryTab extends StatefulWidget {
  const _LibraryTab({required this.items, required this.onSelect});
  final List<FoodItem> items;
  final ValueChanged<FoodItem> onSelect;

  @override
  State<_LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<_LibraryTab> {
  String _query = '';

  List<FoodItem> get _filtered {
    if (_query.isEmpty) return widget.items;
    final lower = _query.toLowerCase();
    return widget.items
        .where((f) => f.name.toLowerCase().contains(lower))
        .toList();
  }

  List<FoodItem> _recentItems(BuildContext context) {
    final recentIds = context
        .read<DiaryProvider>()
        .entries
        .where((e) => e.foodItemId != null)
        .map((e) => e.foodItemId!)
        .toSet();
    return widget.items.where((f) => recentIds.contains(f.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final recentItems = _query.isEmpty ? _recentItems(context) : <FoodItem>[];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Cari makanan di koleksimu…',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: _query.isNotEmpty
              ? (_filtered.isEmpty
                  ? _EmptyHint(message: 'Tidak ada makanan yang cocok dengan "$_query".', scheme: scheme)
                  : _FoodList(items: _filtered, onSelect: widget.onSelect))
              : widget.items.isEmpty
                  ? _EmptyHint(
                      message: 'Koleksi makanan masih kosong.\nTambahkan makanan lewat tab Scanner terlebih dahulu.',
                      scheme: scheme,
                    )
                  : ListView(
                      children: [
                        if (recentItems.isNotEmpty) ...[
                          _SectionHeader(
                            icon: Icons.history_rounded,
                            label: 'Terakhir Digunakan Hari Ini',
                            scheme: scheme,
                          ),
                          ...recentItems.map(
                            (item) => _FoodListTile(item: item, onSelect: widget.onSelect),
                          ),
                          const Divider(height: 1),
                        ],
                        _SectionHeader(
                          icon: Icons.collections_bookmark_outlined,
                          label: 'Semua Koleksi',
                          scheme: scheme,
                        ),
                        ...widget.items.map(
                          (item) => _FoodListTile(item: item, onSelect: widget.onSelect),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.message, required this.scheme});
  final String message;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.outline),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label, required this.scheme});
  final IconData icon;
  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.s, AppSpacing.m, AppSpacing.xxs),
      child: Row(
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodList extends StatelessWidget {
  const _FoodList({required this.items, required this.onSelect});
  final List<FoodItem> items;
  final ValueChanged<FoodItem> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) => _FoodListTile(item: items[i], onSelect: onSelect),
    );
  }
}

class _FoodListTile extends StatelessWidget {
  const _FoodListTile({required this.item, required this.onSelect});
  final FoodItem item;
  final ValueChanged<FoodItem> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.name),
      subtitle: Text(
        '${item.calories.toStringAsFixed(0)} kkal · '
        '${item.servingSize.toStringAsFixed(0)} g per porsi',
      ),
      trailing: const Icon(Icons.add_circle_outline),
      onTap: () => onSelect(item),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body untuk mode Manual (CREATE) dan mode Edit (UPDATE)
// ─────────────────────────────────────────────────────────────────────────────

class _ManualBody extends StatelessWidget {
  const _ManualBody({
    required this.form,
    required this.mealType,
    required this.servings,
    required this.previewCalories,
    required this.onMealTypeChanged,
    required this.onServingsChanged,
    required this.onSave,
    this.showMealChips = true,
  });

  final FoodFormController form;
  final MealType mealType;
  final double servings;
  final double previewCalories;
  final ValueChanged<MealType> onMealTypeChanged;
  final ValueChanged<double> onServingsChanged;
  final VoidCallback onSave;
  final bool showMealChips;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.m),
      children: [
        if (showMealChips) ...[
          _MealTypeChips(selected: mealType, onSelected: onMealTypeChanged),
          const SizedBox(height: AppSpacing.m),
        ],
        FoodFormFields(controller: form),
        const SizedBox(height: AppSpacing.m),
        _ServingsStepper(value: servings, onChanged: onServingsChanged),
        const SizedBox(height: AppSpacing.s),
        _CaloriesPreviewBanner(calories: previewCalories),
        const SizedBox(height: AppSpacing.l),
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.add),
          label: const Text('Tambah ke Jurnal'),
        ),
        const SizedBox(height: AppSpacing.m),
      ],
    );
  }
}

class _EditBody extends StatelessWidget {
  const _EditBody({
    required this.form,
    required this.mealType,
    required this.servings,
    required this.previewCalories,
    required this.onMealTypeChanged,
    required this.onServingsChanged,
    required this.onSave,
    this.showMealChips = true,
  });

  final FoodFormController form;
  final MealType mealType;
  final double servings;
  final double previewCalories;
  final ValueChanged<MealType> onMealTypeChanged;
  final ValueChanged<double> onServingsChanged;
  final VoidCallback onSave;
  final bool showMealChips;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.m),
      children: [
        if (showMealChips) ...[
          _MealTypeChips(selected: mealType, onSelected: onMealTypeChanged),
          const SizedBox(height: AppSpacing.m),
        ],
        FoodFormFields(controller: form),
        const SizedBox(height: AppSpacing.m),
        _ServingsStepper(value: servings, onChanged: onServingsChanged),
        const SizedBox(height: AppSpacing.s),
        _CaloriesPreviewBanner(calories: previewCalories),
        const SizedBox(height: AppSpacing.l),
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.check),
          label: const Text('Simpan Perubahan'),
        ),
        const SizedBox(height: AppSpacing.m),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared inner widgets
// ─────────────────────────────────────────────────────────────────────────────

class _MealTypeChips extends StatelessWidget {
  const _MealTypeChips({required this.selected, required this.onSelected});
  final MealType selected;
  final ValueChanged<MealType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Waktu Makan', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final type in MealType.values)
              ChoiceChip(
                label: Text(
                  type.label,
                  style: type == selected
                      ? AppTheme.jakartaSemiBold(size: 12)
                          .copyWith(color: Colors.white)
                      : AppTheme.inter(
                          size: 12, color: AppTheme.charcoal),
                ),
                selected: type == selected,
                onSelected: (_) => onSelected(type),
                backgroundColor: Colors.white,
                selectedColor: AppTheme.primary,
                side: BorderSide(
                  color: type == selected
                      ? AppTheme.primary
                      : AppTheme.creamyBorder,
                ),
                showCheckmark: false,
              ),
          ],
        ),
      ],
    );
  }
}

class _ServingsStepper extends StatelessWidget {
  const _ServingsStepper({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  String get _label =>
      value == value.truncateToDouble() ? '${value.toInt()}x' : '${value}x';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Jumlah Porsi', style: Theme.of(context).textTheme.labelLarge),
        const Spacer(),
        IconButton.outlined(
          icon: const Icon(Icons.remove),
          onPressed: value > 0.5 ? () => onChanged(value - 0.5) : null,
        ),
        SizedBox(
          width: 64,
          child: Text(
            _label,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton.outlined(
          icon: const Icon(Icons.add),
          onPressed: value < 10.0 ? () => onChanged(value + 0.5) : null,
        ),
      ],
    );
  }
}

class _CaloriesPreviewBanner extends StatelessWidget {
  const _CaloriesPreviewBanner({required this.calories});
  final double calories;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 14),
      decoration: AppTheme.glassPanelHeavyDecoration(radius: AppRadius.large),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          const Icon(Icons.local_fire_department, color: AppTheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${calories.toStringAsFixed(0)} kkal',
            style: AppTheme.digitStyle(size: 28, color: AppTheme.primary),
          ),
          const SizedBox(width: 6),
          Text(
            'estimasi total',
            style: AppTheme.inter(size: 13).copyWith(
              color: AppTheme.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}