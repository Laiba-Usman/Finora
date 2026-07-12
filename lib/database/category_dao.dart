import 'package:sqflite/sqflite.dart';
import '../config/constants.dart';
import '../models/category_model.dart';
import 'db_helper.dart';

class CategoryDao {
  final DbHelper _dbHelper = DbHelper();

  Future<int> insert(CategoryModel category, String userId) async {
    final db = await _dbHelper.database;
    final map = category.toMap();
    map['user_id'] = userId;
    return await db.insert(
      AppConstants.tableCategories,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(CategoryModel category, String userId) async {
    final db = await _dbHelper.database;
    final map = category.toMap();
    map['user_id'] = userId;
    return await db.update(
      AppConstants.tableCategories,
      map,
      where: 'id = ? AND user_id = ?',
      whereArgs: [category.id, userId],
    );
  }

  Future<int> delete(String id, String userId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      AppConstants.tableCategories,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<List<CategoryModel>> getAll(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableCategories,
      where: 'user_id = ? OR is_custom = 0',
      whereArgs: [userId],
    );
    return maps.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<CategoryModel?> getById(String id, String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableCategories,
      where: 'id = ? AND (user_id = ? OR is_custom = 0)',
      whereArgs: [id, userId],
    );
    if (maps.isEmpty) return null;
    return CategoryModel.fromMap(maps.first);
  }
}
