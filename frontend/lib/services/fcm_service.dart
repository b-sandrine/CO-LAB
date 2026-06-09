import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmService {
  FcmService._();

  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'alu_colab_high_importance',
    'ALU Co-Lab Notifications',
    description: 'This channel is used for ALU Co-Lab notifications.',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(initSettings);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
