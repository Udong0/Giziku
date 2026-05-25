import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Layanan notifikasi yang menggabungkan:
///   • flutter_local_notifications → reminder lokal terjadwal (demo-able)
///   • firebase_messaging           → inisialisasi FCM (syarat wajib FP)
///
/// SETUP WAJIB (sudah ada di INTEGRATION.md §4.3):
///   1. Panggil [initialize] di main() sebelum runApp.
///   2. Untuk Android 13+: tambahkan permission di AndroidManifest.xml.
///   3. Untuk iOS: permission diminta otomatis di [initialize].
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Inisialisasi ────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;

    // Timezone — wajib agar alarm tidak meleset
    tz.initializeTimeZones();
    // Set ke WIB. Ganti 'Asia/Jakarta' jika perlu zona lain.
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    // Android channel
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS / macOS — minta permission saat init
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createAndroidChannel();
    await _initFirebase();

    _initialized = true;
  }

  // ── Android notification channel ────────────────────────────
  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      'meal_reminder_channel',
      'Pengingat Makan',
      description: 'Notifikasi pengingat jadwal makan dari GiziKu.',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ── Firebase Messaging (FCM) ─────────────────────────────────
  Future<void> _initFirebase() async {
    try {
      // Firebase.initializeApp dipanggil SEKALI dari main.dart (jika sudah setup).
      // Jika belum ada google-services.json / GoogleService-Info.plist, blok ini
      // akan throw — tangkap agar app tidak crash saat development.
      if (Firebase.apps.isEmpty) {
        // Uncomment baris ini setelah menambahkan file konfigurasi Firebase:
        // await Firebase.initializeApp(
        //   options: DefaultFirebaseOptions.currentPlatform,
        // );
        debugPrint('[NotificationService] Firebase belum dikonfigurasi — skip FCM init.');
        return;
      }

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      final token = await messaging.getToken();
      debugPrint('[NotificationService] FCM token: $token');

      // Handler untuk notif yang datang saat app foreground
      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        if (notification == null) return;
        _showSimple(
          id: message.hashCode,
          title: notification.title ?? 'GiziKu',
          body: notification.body ?? '',
        );
      });
    } catch (e) {
      debugPrint('[NotificationService] Firebase init error: $e');
    }
  }

  // ── Public API ───────────────────────────────────────────────

  /// Jadwalkan notifikasi pada [scheduledDate] (harus di masa depan).
  /// Kembalikan [notificationId] yang perlu disimpan di [MealPlan].
  Future<int> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_reminder_channel',
          'Pengingat Makan',
          channelDescription: 'Notifikasi pengingat jadwal makan dari GiziKu.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
    return id;
  }

  /// Batalkan notifikasi berdasarkan [id].
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  /// Batalkan semua notifikasi aktif.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Internal ─────────────────────────────────────────────────
  Future<void> _showSimple({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_reminder_channel',
          'Pengingat Makan',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // TODO: navigasi ke PlannerScreen saat notif di-tap
    debugPrint('[NotificationService] Notif tapped: ${response.payload}');
  }
}
