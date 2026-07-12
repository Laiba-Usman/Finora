import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../database/notification_dao.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    // Fallback in case timezone name mapping fails
    try {
      // Default local to UTC if not set, avoiding potential exceptions
      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (_) {}

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Local Notification Tapped! Payload: ${response.payload}');
        // Handle deep linking or screen routing based on payload when needed
      },
    );

    // Explicitly request notification permissions on Android 13+ (API 33+)
    final androidImplementation = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      try {
        await androidImplementation.requestNotificationsPermission();
      } catch (e) {
        print('Failed to request notifications permission: $e');
      }
    }
  }

  // Display immediate notification (e.g. Budget Alerts)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Save to local database history
    try {
      final notif = NotificationModel(
        id: const Uuid().v4(),
        title: title,
        body: body,
        timestamp: DateTime.now(),
        isRead: false,
      );
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'test_user';
      await NotificationDao().insert(notif, userId);
    } catch (e) {
      print('Failed to save triggered notification to history: $e');
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'budget_alerts_channel',
      'Budget Alerts',
      channelDescription: 'Alerts when budget exceeds thresholds',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  // Schedule daily local notification reminders
  Future<void> scheduleDailyReminder({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminders_channel',
      'Daily Reminders',
      channelDescription: 'Daily reminder to log expenses',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // AndroidScheduleMode.inexactAllowWhileIdle does not throw SecurityException on Android 12+ (API 31+)
    // when SCHEDULE_EXACT_ALARM permission is not granted, making it highly reliable in production.
    await _localNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final location = _localLocation;
    final tz.TZDateTime now = tz.TZDateTime.now(location);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.Location get _localLocation {
    try {
      return tz.local;
    } catch (_) {
      return tz.UTC;
    }
  }

  Future<void> cancelAll() async {
    await _localNotificationsPlugin.cancelAll();
  }
}
