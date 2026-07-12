import 'package:sqflite/sqflite.dart';
import '../config/constants.dart';
import '../models/savings_goal_model.dart';
import 'db_helper.dart';

class SavingsGoalDao {
  final DbHelper _dbHelper = DbHelper();

  Future<int> insert(SavingsGoalModel goal, String userId) async {
    final db = await _dbHelper.database;
    final map = goal.toMap();
    map['user_id'] = userId;
    return await db.insert(
      AppConstants.tableSavingsGoals,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(SavingsGoalModel goal, String userId) async {
    final db = await _dbHelper.database;
    final map = goal.toMap();
    map['user_id'] = userId;
    return await db.update(
      AppConstants.tableSavingsGoals,
      map,
      where: 'id = ? AND user_id = ?',
      whereArgs: [goal.id, userId],
    );
  }

  Future<int> delete(String id, String userId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      AppConstants.tableSavingsGoals,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<List<SavingsGoalModel>> getAll(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableSavingsGoals,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => SavingsGoalModel.fromMap(map)).toList();
  }

  Future<SavingsGoalModel?> getById(String id, String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableSavingsGoals,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    if (maps.isEmpty) return null;
    return SavingsGoalModel.fromMap(maps.first);
  }
}
