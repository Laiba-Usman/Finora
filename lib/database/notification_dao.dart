import 'package:sqflite/sqflite.dart';
import '../config/constants.dart';
import '../models/notification_model.dart';
import 'db_helper.dart';

class NotificationDao {
  final DbHelper _dbHelper = DbHelper();

  Future<int> insert(NotificationModel notification, String userId) async {
    final db = await _dbHelper.database;
    final map = notification.toMap();
    map['user_id'] = userId;
    return await db.insert(
      AppConstants.tableNotificationsHistory,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(NotificationModel notification, String userId) async {
    final db = await _dbHelper.database;
    final map = notification.toMap();
    map['user_id'] = userId;
    return await db.update(
      AppConstants.tableNotificationsHistory,
      map,
      where: 'id = ? AND user_id = ?',
      whereArgs: [notification.id, userId],
    );
  }

  Future<List<NotificationModel>> getAll(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableNotificationsHistory,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => NotificationModel.fromMap(map)).toList();
  }

  Future<int> markAsRead(String id, String userId) async {
    final db = await _dbHelper.database;
    return await db.update(
      AppConstants.tableNotificationsHistory,
      {'is_read': 1},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<int> markAllAsRead(String userId) async {
    final db = await _dbHelper.database;
    return await db.update(
      AppConstants.tableNotificationsHistory,
      {'is_read': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
