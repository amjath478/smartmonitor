import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// A small wrapper around `flutter_local_notifications` so that the rest of
/// the application doesn't know or care which library is used.  The public
/// method `triggerPeakAlert` may later be replaced with an FCM call without
/// touching any consumer code.
///
/// This service is a singleton; call `LocalNotificationService().init()` once
/// during application startup (for example in `main()` or in the first
/// screen's `initState`).
class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static final LocalNotificationService _instance =
      LocalNotificationService._internal();

  factory LocalNotificationService() => _instance;

  LocalNotificationService._internal();

  /// Initialise the underlying plugin.  Should be called from a top‑level
  /// location before any notifications are requested.
  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Use Darwin settings for iOS and macOS platforms
    final darwinSettings = DarwinInitializationSettings();
    final settings = InitializationSettings(android: androidSettings, iOS: darwinSettings, macOS: darwinSettings);

    final result = await _plugin.initialize(settings);
    debugPrint('LocalNotificationService initialized: $result');

    // Request Android notification permission (Android 13+)
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestPermission();
        debugPrint('Notification permission granted: $granted');
      }
    } catch (e) {
      debugPrint('Permission request failed: $e');
    }
  }

  /// Display a peak alert notification.  This is the isolated hook that can
  /// later be replaced with an FCM send operation without changing the
  /// monitoring logic.
  Future<void> triggerPeakAlert(String applianceName) async {
    debugPrint('triggerPeakAlert called for $applianceName');
    const androidDetails = AndroidNotificationDetails(
      'peak_alerts',
      'Peak Alerts',
      channelDescription: 'Notifies when an appliance enters a peak state',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    final darwinDetails = DarwinNotificationDetails();
    final platformDetails = NotificationDetails(android: androidDetails, iOS: darwinDetails, macOS: darwinDetails);

    await _plugin.show(
      applianceName.hashCode,
      '⚠️ Peak Current Warning',
      applianceName,
      platformDetails,
    );
  }
}
