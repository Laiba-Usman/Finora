import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../database/notification_dao.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationDao _notificationDao = NotificationDao();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void clearData() {
    _notifications = [];
    notifyListeners();
  }

  // Helper to get active user ID
  String _getUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? 'test_user';
  }

  Future<void> loadNotifications() async {
    final userId = _getUserId();
    _isLoading = true;
    notifyListeners();
    try {
      await checkForDailyReminders();
      _notifications = await _notificationDao.getAll(userId);
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNotification(String title, String body, {DateTime? timestamp}) async {
    final userId = _getUserId();
    final newNotif = NotificationModel(
      id: const Uuid().v4(),
      title: title,
      body: body,
      timestamp: timestamp ?? DateTime.now(),
      isRead: false,
    );

    try {
      await _notificationDao.insert(newNotif, userId);
      _notifications = await _notificationDao.getAll(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving notification to DB: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    final userId = _getUserId();
    try {
      await _notificationDao.markAsRead(id, userId);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _getUserId();
    try {
      await _notificationDao.markAllAsRead(userId);
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> checkForDailyReminders() async {
    final userId = _getUserId();
    try {
      final prefs = await SharedPreferences.getInstance();
      final hour = prefs.getInt(AppConstants.keyDailyReminderHour) ?? 21;
      final minute = prefs.getInt(AppConstants.keyDailyReminderMinute) ?? 0;
      
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      // Scope daily reminder fires by user id
      final lastFiredDateKey = '${AppConstants.keyLastDailyReminderFiredDate}_$userId';
      final lastFiredDate = prefs.getString(lastFiredDateKey);
      
      if (lastFiredDate != todayStr) {
        final reminderTimeToday = DateTime(now.year, now.month, now.day, hour, minute);
        if (now.isAfter(reminderTimeToday)) {
          // Daily reminder has fired today! Add to history
          final newNotif = NotificationModel(
            id: const Uuid().v4(),
            title: 'Daily Reminder 📝',
            body: "Time to log your expenses and review your budget for today!",
            timestamp: reminderTimeToday,
            isRead: false,
          );
          await _notificationDao.insert(newNotif, userId);
          await prefs.setString(lastFiredDateKey, todayStr);
        }
      }
    } catch (e) {
      debugPrint('Error checking daily reminder fire: $e');
    }
  }
}
