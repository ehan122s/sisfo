import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

// ── Background message handler (harus top-level function) ────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Tidak perlu init Firebase lagi karena sudah di main()
  debugPrint('FCM Background: ${message.notification?.title}');
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // ── Android notification channel ─────────────────────────────────────────
  static const _androidChannel = AndroidNotificationChannel(
    'sip_smea_channel',
    'SIP SMEA Notifications',
    description: 'Notifikasi dari aplikasi SIP SMEA',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    // 1. Minta permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM: Permission ditolak');
      return;
    }

    // 2. Setup local notifications (untuk foreground)
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // 3. Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 4. Foreground handler — tampilkan sebagai local notification
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // 5. Simpan FCM token ke Supabase
    await _saveToken();

    // 6. Update token kalau refresh
    _messaging.onTokenRefresh.listen(_updateToken);
  }

  Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);

      debugPrint('FCM Token saved: $token');
    } catch (e) {
      debugPrint('FCM Token save error: $e');
    }
  }

  Future<void> _updateToken(String token) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      await supabase
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);
    } catch (e) {
      debugPrint('FCM Token update error: $e');
    }
  }

  // Panggil ini saat login berhasil (agar token tersimpan setelah auth)
  Future<void> onLogin() async {
    await _saveToken();
  }

  // Panggil ini saat logout
  Future<void> onLogout() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      await supabase
          .from('profiles')
          .update({'fcm_token': null})
          .eq('id', userId);
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('FCM logout error: $e');
    }
  }
}
