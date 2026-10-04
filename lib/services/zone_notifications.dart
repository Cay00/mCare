import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:m_opiekun/services/safe_zone.dart';

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

bool _ready = false;

/// Inicjuje kanał powiadomień. Błąd wtyczki nie blokuje reszty aplikacji.
Future<void> prepareZoneNotifications({bool requestPermission = false}) async {
  try {
    if (!_ready) {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          web: WebInitializationSettings(),
        ),
      );
      _ready = true;
    }
    if (!requestPermission) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, sound: true);
  } catch (error) {
    debugPrint('Powiadomienia strefy są niedostępne: $error');
  }
}

Future<void> showZoneLeftNotification(SafeZoneAlert alert) async {
  try {
    await prepareZoneNotifications(requestPermission: true);
    await _plugin.show(
      id: alert.at.microsecondsSinceEpoch.remainder(100000),
      title: alert.title,
      body: alert.message,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'safe_zone_alerts',
          'Alerty strefy',
          channelDescription:
              'Powiadomienie, gdy pacjent opuści bezpieczną strefę.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
        ),
      ),
    );
  } catch (error) {
    debugPrint('Nie udało się pokazać powiadomienia strefy: $error');
  }
}
