import 'package:sqflite/sqflite.dart';
import '../config/constants.dart';
import '../models/budget_model.dart';
import 'db_helper.dart';

class BudgetDao {
  final DbHelper _dbHelper = DbHelper();

  Future<int> insert(BudgetModel budget, String userId) async {
    final db = await _dbHelper.database;
    final map = budget.toMap();
    map['user_id'] = userId;
    return await db.insert(
      AppConstants.tableBudgets,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(BudgetModel budget, String userId) async {
    final db = await _dbHelper.database;
    final map = budget.toMap();
    map['user_id'] = userId;
    return await db.update(
      AppConstants.tableBudgets,
      map,
      where: 'id = ? AND user_id = ?',
      whereArgs: [budget.id, userId],
    );
  }

  Future<int> delete(String id, String userId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      AppConstants.tableBudgets,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<List<BudgetModel>> getForMonth(String month, String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableBudgets,
      where: 'month = ? AND user_id = ?',
      whereArgs: [month, userId],
    );
    return maps.map((map) => BudgetModel.fromMap(map)).toList();
  }

  Future<BudgetModel?> getForCategory(String month, String? categoryId, String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableBudgets,
      where: categoryId == null 
          ? 'month = ? AND category_id IS NULL AND user_id = ?' 
          : 'month = ? AND category_id = ? AND user_id = ?',
      whereArgs: categoryId == null ? [month, userId] : [month, categoryId, userId],
    );
    if (maps.isEmpty) return null;
    return BudgetModel.fromMap(maps.first);
  }

  Future<int> updateAlertFlags(String id, bool alert80, bool alert100, String userId) async {
    final db = await _dbHelper.database;
    return await db.update(
      AppConstants.tableBudgets,
      {
        'alert_sent_80': alert80 ? 1 : 0,
        'alert_sent_100': alert100 ? 1 : 0,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }
}
