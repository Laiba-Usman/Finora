import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../config/constants.dart';
import 'package:uuid/uuid.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  static sqflite.Database? _database;

  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<sqflite.Database> _initDb() async {
    try {
      debugPrint('--- DbHelper: _initDb started ---');
      debugPrint('DbHelper: kIsWeb = $kIsWeb');
      if (!kIsWeb) {
        debugPrint('DbHelper: Platform = ${Platform.operatingSystem}');
      }
      
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        debugPrint('DbHelper: Initializing sqflite FFI...');
        sqfliteFfiInit();
        debugPrint('DbHelper: Setting sqflite.databaseFactory = databaseFactoryFfi...');
        sqflite.databaseFactory = databaseFactoryFfi;
      }
      
      debugPrint('DbHelper: sqflite.databaseFactory is ${sqflite.databaseFactory}');

      final databasesPath = await sqflite.getDatabasesPath();
      debugPrint('DbHelper: databasesPath = $databasesPath');
      
      final pathString = join(databasesPath, AppConstants.dbName);
      debugPrint('DbHelper: pathString = $pathString');

      final db = await sqflite.openDatabase(
        pathString,
        version: AppConstants.dbVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      debugPrint('DbHelper: Database opened successfully!');
      return db;
    } catch (e, stack) {
      debugPrint('DbHelper: Error in _initDb: $e');
      debugPrint('DbHelper: Stack trace: $stack');
      rethrow;
    }
  }

  Future<void> _onConfigure(sqflite.Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(sqflite.Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE ${AppConstants.tableSavingsGoals} (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          target_amount REAL NOT NULL,
          current_amount REAL NOT NULL DEFAULT 0.0,
          target_date TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE ${AppConstants.tableNotificationsHistory} (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          is_read INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE ${AppConstants.tableSavingsContributions} (
          id TEXT PRIMARY KEY,
          goal_id TEXT NOT NULL,
          amount REAL NOT NULL,
          timestamp TEXT NOT NULL,
          FOREIGN KEY (goal_id) REFERENCES ${AppConstants.tableSavingsGoals} (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE ${AppConstants.tableCategories} ADD COLUMN user_id TEXT');
      await db.execute('ALTER TABLE ${AppConstants.tableTransactions} ADD COLUMN user_id TEXT');
      await db.execute('ALTER TABLE ${AppConstants.tableBudgets} ADD COLUMN user_id TEXT');
      await db.execute('ALTER TABLE ${AppConstants.tableSavingsGoals} ADD COLUMN user_id TEXT');
      await db.execute('ALTER TABLE ${AppConstants.tableNotificationsHistory} ADD COLUMN user_id TEXT');
      await db.execute('ALTER TABLE ${AppConstants.tableSavingsContributions} ADD COLUMN user_id TEXT');
    }
  }

  Future<void> _onCreate(sqflite.Database db, int version) async {
    // Create categories table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableCategories} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        type TEXT NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0,
        user_id TEXT
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableTransactions} (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id TEXT NOT NULL,
        note TEXT,
        payment_method TEXT NOT NULL,
        date TEXT NOT NULL,
        receipt_path TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        user_id TEXT,
        FOREIGN KEY (category_id) REFERENCES ${AppConstants.tableCategories} (id) ON DELETE CASCADE
      )
    ''');

    // Create budgets table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableBudgets} (
        id TEXT PRIMARY KEY,
        category_id TEXT,
        amount REAL NOT NULL,
        month TEXT NOT NULL,
        alert_sent_80 INTEGER NOT NULL DEFAULT 0,
        alert_sent_100 INTEGER NOT NULL DEFAULT 0,
        user_id TEXT,
        FOREIGN KEY (category_id) REFERENCES ${AppConstants.tableCategories} (id) ON DELETE CASCADE
      )
    ''');

    // Create savings goals table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableSavingsGoals} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0.0,
        target_date TEXT,
        created_at TEXT NOT NULL,
        user_id TEXT
      )
    ''');

    // Create notifications table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableNotificationsHistory} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        user_id TEXT
      )
    ''');

    // Create savings contributions table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableSavingsContributions} (
        id TEXT PRIMARY KEY,
        goal_id TEXT NOT NULL,
        amount REAL NOT NULL,
        timestamp TEXT NOT NULL,
        user_id TEXT,
        FOREIGN KEY (goal_id) REFERENCES ${AppConstants.tableSavingsGoals} (id) ON DELETE CASCADE
      )
    ''');

    // Insert Default Categories
    await _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultCategories(sqflite.Database db) async {
    final defaultCategories = [
      // Expense Categories
      {'name': 'Food & Dining', 'icon': 'restaurant', 'color': '#EF4444', 'type': 'expense'},
      {'name': 'Transportation', 'icon': 'directions_car', 'color': '#3B82F6', 'type': 'expense'},
      {'name': 'Shopping', 'icon': 'shopping_bag', 'color': '#EC4899', 'type': 'expense'},
      {'name': 'Entertainment', 'icon': 'movie', 'color': '#8B5CF6', 'type': 'expense'},
      {'name': 'Bills & Utilities', 'icon': 'receipt_long', 'color': '#F59E0B', 'type': 'expense'},
      // Income Categories
      {'name': 'Salary', 'icon': 'payments', 'color': '#10B981', 'type': 'income'},
      {'name': 'Freelance', 'icon': 'laptop', 'color': '#14B8A6', 'type': 'income'},
      {'name': 'Investments', 'icon': 'trending_up', 'color': '#06B6D4', 'type': 'income'},
      {'name': 'Other Income', 'icon': 'add_card', 'color': '#64748B', 'type': 'income'},
    ];

    const uuid = Uuid();
    final batch = db.batch();
    for (var cat in defaultCategories) {
      batch.insert(AppConstants.tableCategories, {
        'id': uuid.v4(),
        'name': cat['name'],
        'icon': cat['icon'],
        'color': cat['color'],
        'type': cat['type'],
        'is_custom': 0,
      });
    }
    await batch.commit(noResult: true);
  }
}
