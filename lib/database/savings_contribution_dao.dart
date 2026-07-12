import 'package:sqflite/sqflite.dart';
import '../config/constants.dart';
import '../models/savings_contribution_model.dart';
import 'db_helper.dart';

class SavingsContributionDao {
  final DbHelper _dbHelper = DbHelper();

  Future<int> insert(SavingsContributionModel contribution, String userId) async {
    final db = await _dbHelper.database;
    final map = contribution.toMap();
    map['user_id'] = userId;
    return await db.insert(
      AppConstants.tableSavingsContributions,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SavingsContributionModel>> getByGoal(String goalId, String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableSavingsContributions,
      where: 'goal_id = ? AND user_id = ?',
      whereArgs: [goalId, userId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => SavingsContributionModel.fromMap(map)).toList();
  }

  Future<int> deleteByGoal(String goalId, String userId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      AppConstants.tableSavingsContributions,
      where: 'goal_id = ? AND user_id = ?',
      whereArgs: [goalId, userId],
    );
  }
}
