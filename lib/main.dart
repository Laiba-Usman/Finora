import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app/app.dart';
import 'config/firebase_options.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';

/// Top-level background message handler for Firebase Cloud Messaging.
/// Must be a top-level function (not a class method) for background isolation.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background message handling
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    sqflite.databaseFactory = databaseFactoryFfi;
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  // Register background message handler before any other FCM calls
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Local Notifications Service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize Firebase Cloud Messaging Service
  final fcmService = FcmService();
  await fcmService.initialize();

  // Check for message that launched app from terminated state
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print('App opened from terminated state via notification: ${initialMessage.messageId}');
    // Handle navigation based on initialMessage.data when needed
  }

  // Schedule Default daily notification reminder at 8 PM (20:00)
  try {
    await notificationService.scheduleDailyReminder(
      id: 9999,
      hour: 20,
      minute: 0,
      title: 'Log your expenses 📝',
      body: "Don't forget to log today's transactions to stay on top of your budgets!",
    );
  } catch (e) {
    print('Failed to schedule daily reminders: $e');
  }

  runApp(const MyApp());
}
