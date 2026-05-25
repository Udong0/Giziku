# Panduan Integrasi — Anggota 2 & 3

Dokumen ini buat Anggota 2 (Tracker Harian) & Anggota 3 (Meal Planner + Reminder) supaya fitur kalian nyambung mulus ke base project yang sudah disiapkan Anggota 1.

> Base project sudah lulus `flutter analyze` (0 issue). Tolong jaga supaya tetap 0 setelah kalian commit — jalankan `flutter analyze` sebelum push.

---

## 1. Apa yang sudah ada

| Komponen | Lokasi | Catatan |
|---|---|---|
| App shell + BottomNav 4 tab | [lib/core/widgets/main_shell.dart](lib/core/widgets/main_shell.dart) | Tab kalian sudah didaftarkan, tinggal isi |
| Theme Material 3 (hijau) | [lib/core/theme/app_theme.dart](lib/core/theme/app_theme.dart) | Pakai `Theme.of(context)` — jangan hardcode warna |
| Placeholder card | [lib/core/widgets/placeholder_tab.dart](lib/core/widgets/placeholder_tab.dart) | Hapus pemakaiannya saat fitur kalian jadi |
| FoodLibraryProvider | [lib/features/scanner/providers/food_library_provider.dart](lib/features/scanner/providers/food_library_provider.dart) | **Dipakai kalian berdua** untuk pilih makanan |
| Bootstrap Provider | [lib/main.dart](lib/main.dart) | Daftarin provider baru kalian di sini |
| Test contoh | [test/widget_test.dart](test/widget_test.dart) | Tambah test kalian, jangan biarkan kosong |

---

## 2. Aturan main bersama

### 2.1 Struktur folder

Ikuti pola feature-first yang sama dengan `scanner/`:

```
lib/features/<fitur_kalian>/
├── models/
├── data/          # abstract repository + implementasi
├── providers/     # ChangeNotifier
├── services/      # optional (notifikasi, API, dll)
└── screens/
```

### 2.2 Pattern repository (WAJIB ikuti)

Bikin abstract class dulu, baru implementasi. Tujuannya: pas migrasi ke Firestore nanti, screen tidak perlu diubah.

Contoh patokan: [lib/features/scanner/data/food_repository.dart](lib/features/scanner/data/food_repository.dart) + [local_food_repository.dart](lib/features/scanner/data/local_food_repository.dart).

### 2.3 State management

Pakai `Provider` + `ChangeNotifier`. Contoh patokan: [food_library_provider.dart](lib/features/scanner/providers/food_library_provider.dart) — punya `load()`, `add()`, `update()`, `delete()`, plus state `loading` & `error`.

### 2.4 Daftarin provider kalian di main.dart

Tambah di [lib/main.dart](lib/main.dart) di dalam `MultiProvider`:

```dart
ChangeNotifierProvider(
  create: (_) => MealPlanProvider(mealPlanRepo)..load(),
),
```

### 2.5 Ganti placeholder di MainShell

Di [lib/core/widgets/main_shell.dart](lib/core/widgets/main_shell.dart), ganti import & entry di list `_tabs`. Tab kalian sudah ada di posisinya — tinggal ganti screen-nya saja.

### 2.6 Akses Koleksi Makanan (PENTING — kalian berdua butuh)

Fitur Anggota 1 menyimpan master data makanan. Tracker (Anggota 2) & Planner (Anggota 3) **tidak boleh duplikasi data nutrisi**, cukup simpan `foodItemId` lalu lookup:

```dart
final library = context.watch<FoodLibraryProvider>();
final foods = library.items;                 // untuk picker / dropdown
final food = library.findById(entry.foodItemId);  // null kalau sudah dihapus user
```

Selalu handle case `food == null` di UI (mis. tampilkan "Makanan dihapus" dengan opsi un-link).

### 2.7 Gunakan komponen reusable

- `FoodFormFields` di [lib/features/scanner/screens/food_form.dart](lib/features/scanner/screens/food_form.dart) → kalau kalian perlu input gizi manual.
- `intl` (`DateFormat`) sudah ada di [pubspec.yaml](pubspec.yaml).
- `uuid` (`const Uuid().v4()`) untuk ID — jangan pakai `DateTime.now().millisecondsSinceEpoch`.

---

## 3. Anggota 2 — Daily Nutrition Tracker

### 3.1 Model yang disarankan

```dart
// lib/features/tracker/models/diary_entry.dart
class DiaryEntry {
  final String id;
  final String foodItemId;     // referensi ke FoodLibrary
  final DateTime date;         // tanggal makan (jam diabaikan untuk grouping)
  final MealType mealType;     // breakfast/lunch/dinner/snack
  final double servings;       // multiplier porsi (0.5, 1, 2, ...)
  final DateTime createdAt;
}

enum MealType { breakfast, lunch, dinner, snack }
```

> Catatan: simpan `servings` sebagai multiplier, JANGAN simpan kalori ter-hitung. Hitung on-the-fly: `food.calories * entry.servings`. Kalau user edit data makanan di scanner, jurnal otomatis ikut benar.

### 3.2 File yang perlu kalian buat

```
lib/features/tracker/
├── models/diary_entry.dart
├── data/
│   ├── diary_repository.dart           # abstract
│   └── local_diary_repository.dart     # SharedPreferences sementara
├── providers/diary_provider.dart       # query by date
└── screens/
    ├── tracker_screen.dart             # ganti placeholder yang ada
    ├── add_entry_screen.dart           # CREATE — pilih dari FoodLibrary
    └── day_detail_screen.dart          # optional
```

### 3.3 Query pattern

Provider harus expose:
- `entriesForDate(DateTime day)` → `List<DiaryEntry>` grouped per `mealType`
- `dailyTotals(DateTime day)` → `{calories, protein, carbs, fat}` (hitung dari `library.findById` + `servings`)

### 3.4 Checklist CRUD (untuk demo dosen)

| Op | Letak |
|---|---|
| Create | `add_entry_screen.dart` — picker dari `FoodLibraryProvider.items` |
| Read | `tracker_screen.dart` — list + total kalori hari ini |
| Update | Dialog/sheet ubah `servings` (mis. 1 → 2 porsi) |
| Delete | Swipe-to-dismiss atau tombol di item |

### 3.5 Integrasi UI yang nice-to-have

Date picker di app bar (`DatePicker`) untuk pilih tanggal. Default `DateTime.now()`. Tambahkan ringkasan kalori di header pakai card hijau ala [scanner_home_screen.dart:153](lib/features/scanner/screens/scanner_home_screen.dart#L153).

---

## 4. Anggota 3 — Meal Planner & Reminder

### 4.1 Model yang disarankan

```dart
// lib/features/planner/models/meal_plan.dart
class MealPlan {
  final String id;
  final String foodItemId;        // referensi ke FoodLibrary (opsional)
  final String? customName;       // kalau tidak refer ke library
  final DateTime scheduledAt;     // tanggal + jam reminder
  final MealType mealType;
  final bool reminderEnabled;
  final int? notificationId;      // ID dari flutter_local_notifications, untuk cancel
}
```

### 4.2 File yang perlu kalian buat

```
lib/features/planner/
├── models/meal_plan.dart
├── data/
│   ├── meal_plan_repository.dart
│   └── local_meal_plan_repository.dart
├── providers/meal_plan_provider.dart
├── services/notification_service.dart   # WAJIB untuk syarat FP
└── screens/
    ├── planner_screen.dart              # ganti placeholder
    ├── plan_form_screen.dart            # CREATE / UPDATE
    └── plan_detail_screen.dart          # READ + DELETE
```

### 4.3 Push Notification — syarat WAJIB FP

Tambah di [pubspec.yaml](pubspec.yaml):

```yaml
firebase_core: ^3.6.0
firebase_messaging: ^15.1.3
flutter_local_notifications: ^17.2.3
timezone: ^0.9.4
```

**Pola yang masuk akal:**
- `flutter_local_notifications` → schedule reminder lokal ("jam 12:00 makan siang") — yang **demo-able tanpa backend**, ini yang akan diuji dosen.
- `firebase_messaging` → tetap dipasang & inisialisasi untuk centang syarat wajib FCM, meskipun belum dipakai aktif.

**Setup:**
1. Inisialisasi `NotificationService` di [lib/main.dart](lib/main.dart) sebelum `runApp`, lalu daftarin lewat `Provider` (contek pola `GeminiService` di [main.dart:18](lib/main.dart#L18)).
2. Panggil `tz.initializeTimeZones()` + set local timezone sekali saat startup, kalau tidak alarm meleset.
3. Android 13+: tambah di [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml):
   ```xml
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
   ```
   Lalu request runtime permission via `Permission.notification.request()` (pakai package `permission_handler` atau bawaan flutter_local_notifications).

### 4.4 Checklist CRUD

| Op | Letak |
|---|---|
| Create | `plan_form_screen.dart` — pilih food dari library, set jam reminder |
| Read | `planner_screen.dart` — list grouped per tanggal |
| Update | Edit jam / menu (jangan lupa **cancel + re-schedule** notif) |
| Delete | Confirm dialog (contek [food_detail_screen.dart:111](lib/features/scanner/screens/food_detail_screen.dart#L111)) — **wajib panggil `cancel(notificationId)` dulu** sebelum hapus dari repo |

### 4.5 Gotcha umum

- Notif tidak muncul di emulator yang battery-optimized — test di HP fisik.
- Saat user edit jam, **selalu cancel notif lama** sebelum schedule baru. Kalau lupa, akan ada notif ganda.
- iOS butuh permission request eksplisit lewat `requestPermissions()`.

---

## 5. Migrasi ke Firestore (nanti, sebelum sidang)

Karena semua repository pakai abstract class, migrasi cuma butuh 3 langkah:

1. Bikin `FirestoreFoodRepository implements FoodRepository`, `FirestoreDiaryRepository implements DiaryRepository`, dst.
2. Swap inisialisasi di [main.dart](lib/main.dart) (ganti `Local...Repository` → `Firestore...Repository`).
3. Screen tidak perlu diubah sama sekali.

Untuk foto makanan, di [analysis_result_screen.dart:43](lib/features/scanner/screens/analysis_result_screen.dart#L43) (`_persistImage`) ganti dari "copy ke local docs dir" jadi "upload ke Firebase Cloud Storage, simpan download URL".

---

## 6. Final Project — checklist syarat wajib

Pastikan semua ini centang sebelum demo:

- [x] BottomNavigationBar 4 tab (sudah)
- [x] Satu repo, semua anggota ada riwayat commit
- [x] Firebase Auth (siapa yang ambil? Diskusikan)
- [ ] Cloud Firestore (saat migrasi)
- [ ] Push Notification (Anggota 3)
- [ ] **Bonus**: Cloud Storage (foto makanan — Anggota 1 sudah siapkan hook)
- [ ] **Bonus**: Crashlytics (gampang, tinggal init di `main.dart`)
- [ ] Tiap anggota: 1 fitur CRUD penuh + 1 integrasi API

---

## 7. Workflow commit

- Bikin branch per anggota (`feat/tracker`, `feat/planner`), merge via PR.
- Jangan commit ke `main` langsung kecuali hotfix.
- Sebelum push: `flutter analyze` harus 0 issue, `flutter test` harus pass.
- Commit message singkat: `tracker: add diary entry CRUD`, `planner: schedule local notification`.

Kalau ada yang stuck/tidak jelas, tanya ke Anggota 1 — pattern-nya sudah ada di folder `scanner/` tinggal contek.
