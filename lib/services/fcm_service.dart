import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';

class FcmService {
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  /// Android notification channel for FCM foreground messages
  static const AndroidNotificationChannel _fcmChannel = AndroidNotificationChannel(
    'fcm_high_importance_channel',
    'FCM Notifications',
    description: 'Channel for Firebase Cloud Messaging notifications',
    importance: Importance.max,
  );

  /// Local notifications plugin instance for showing foreground notifications
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request notification permissions (Android 13+ / iOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Create the Android notification channel for foreground messages
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_fcmChannel);

    // Set foreground notification presentation options (iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground messages — display as local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null) {
        await NotificationService().showNotification(
          id: notification.hashCode,
          title: notification.title ?? 'FCM Notification',
          body: notification.body ?? '',
          payload: message.data.toString(),
        );
      }
    });

    // Handle notification click when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // Navigate to a screen based on message details
    });

    // Get and print the FCM token
    final token = await getToken();
    print('FCM Token: $token');

    // Listen for token refresh events
    _messaging.onTokenRefresh.listen((String newToken) {
      print('FCM Token refreshed: $newToken');
      // TODO: Send new token to your server when backend is ready
    });
  }

  /// Get the current FCM registration token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }
}
