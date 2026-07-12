import 'package:sqflite/sqflite.dart';
import '../config/constants.dart';
import '../models/transaction_model.dart';
import 'db_helper.dart';

class TransactionDao {
  final DbHelper _dbHelper = DbHelper();

  Future<int> insert(TransactionModel transaction, String userId) async {
    final db = await _dbHelper.database;
    final map = transaction.toMap();
    map['user_id'] = userId;
    return await db.insert(
      AppConstants.tableTransactions,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(TransactionModel transaction, String userId) async {
    final db = await _dbHelper.database;
    final map = transaction.toMap();
    map['user_id'] = userId;
    return await db.update(
      AppConstants.tableTransactions,
      map,
      where: 'id = ? AND user_id = ?',
      whereArgs: [transaction.id, userId],
    );
  }

  Future<int> delete(String id, String userId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      AppConstants.tableTransactions,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<List<TransactionModel>> getAll(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableTransactions,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> getForMonth(String yearMonth, String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableTransactions,
      where: "date LIKE ? AND user_id = ?",
      whereArgs: ['$yearMonth%', userId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> getUnsynced(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableTransactions,
      where: 'is_synced = ? AND user_id = ?',
      whereArgs: [0, userId],
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<int> markAsSynced(String id, String userId) async {
    final db = await _dbHelper.database;
    return await db.update(
      AppConstants.tableTransactions,
      {'is_synced': 1},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }
}
