import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _local = FlutterLocalNotificationsPlugin();

String? pendingDeepLink;

// ============================================================
// BAGIAN 1: BACKGROUND HANDLER (WAJIB TOP-LEVEL)
// ============================================================
// - Tidak boleh mengakses BuildContext / Riverpod.
// - Berjalan di isolate terpisah.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

// ============================================================
// BAGIAN 2: REQUEST PERMISSION
// ============================================================
// - Android 13+ : wajib requestPermission (POST_NOTIFICATIONS).
// - iOS         : wajib requestPermission juga.
Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
  );
  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}

// ============================================================
// BAGIAN 3: INIT LOCAL NOTIFICATIONS
// ============================================================
// - Android 13+ : butuh channel ID.
// - iOS         : butuh DarwinInitializationSettings.
Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await _local.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      pendingDeepLink = response.payload;
    },
  );
}

// ============================================================
// BAGIAN 4: TOKEN LIFECYCLE
// ============================================================
// - getToken() ambil token saat ini.
// - onTokenRefresh() pantau token baru (WAJIB kirim ke backend).
Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await onToken(token);

  // WAJIB: pantau perubahan token, kalau tidak backend simpan token basi.
  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);

  // Langganan topik
  await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
}

// ============================================================
// BAGIAN 5: FOREGROUND + BACKGROUND HANDLER
// ============================================================
// - onMessage       : foreground (butuh local notification manual).
// - onMessageOpenedApp : background diklik (sistem sudah tampilkan banner).
// - getInitialMessage  : terminated (dibuka dari notifikasi).
void listenForeground(void Function(String route) go) {
  FirebaseMessaging.onMessage.listen((message) async {
    final route = message.data['route'] ?? '/';
    const androidDetails = AndroidNotificationDetails(
      'pengumuman',
      'Pengumuman Kampus',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _local.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'Pengumuman',
      body: message.notification?.body ?? '',
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: route,
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    go(message.data['route'] ?? '/');
  });
}

Future<void> handleTerminated(void Function(String route) go) async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) go(initial.data['route'] ?? '/');
  if (pendingDeepLink != null) go(pendingDeepLink!);
}