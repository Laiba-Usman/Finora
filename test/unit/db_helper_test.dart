import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:finora/database/db_helper.dart';
import 'package:finora/database/category_dao.dart';
import 'package:finora/database/transaction_dao.dart';
import 'package:finora/database/budget_dao.dart';
import 'package:finora/models/category_model.dart';
import 'package:finora/models/transaction_model.dart';
import 'package:finora/models/budget_model.dart';

void main() {
  // Initialize SQLite FFI database factory for host OS test execution
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Database Layer CRUD Verification', () {
    late DbHelper dbHelper;
    late CategoryDao categoryDao;
    late TransactionDao transactionDao;
    late BudgetDao budgetDao;
    const String testUserId = 'test_user';

    setUp(() {
      dbHelper = DbHelper();
      categoryDao = CategoryDao();
      transactionDao = TransactionDao();
      budgetDao = BudgetDao();
    });

    test('1. Database Opens & Default Categories Exist', () async {
      final db = await dbHelper.database;
      expect(db.isOpen, isTrue);

      final categories = await categoryDao.getAll(testUserId);
      expect(categories, isNotEmpty);
      
      // Default categories should include Food & Dining and Salary
      final hasFood = categories.any((c) => c.name == 'Food & Dining' && c.isCustom == false);
      final hasSalary = categories.any((c) => c.name == 'Salary' && c.isCustom == false);
      expect(hasFood, isTrue);
      expect(hasSalary, isTrue);
    });

    test('2. Category DAO CRUD Operations', () async {
      final customCat = CategoryModel(
        id: 'test_cat_id',
        name: 'Subscriptions',
        icon: 'star',
        color: '#E0E0E0',
        type: 'expense',
        isCustom: true,
      );

      // Create
      int result = await categoryDao.insert(customCat, testUserId);
      expect(result, greaterThan(0));

      // Read By ID
      final fetched = await categoryDao.getById('test_cat_id', testUserId);
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Subscriptions'));
      expect(fetched.isCustom, isTrue);

      // Update
      final updatedCat = customCat.copyWith(name: 'Netflix & Spotify');
      int updateRes = await categoryDao.update(updatedCat, testUserId);
      expect(updateRes, greaterThan(0));

      final fetchedUpdated = await categoryDao.getById('test_cat_id', testUserId);
      expect(fetchedUpdated!.name, equals('Netflix & Spotify'));

      // Delete
      int deleteRes = await categoryDao.delete('test_cat_id', testUserId);
      expect(deleteRes, greaterThan(0));

      final deleted = await categoryDao.getById('test_cat_id', testUserId);
      expect(deleted, isNull);
    });

    test('3. Transaction DAO CRUD Operations', () async {
      // Setup a temporary category to reference
      final tempCat = CategoryModel(
        id: 'temp_cat_tx',
        name: 'Gifts',
        icon: 'card_giftcard',
        color: '#FFD700',
        type: 'expense',
        isCustom: true,
      );
      await categoryDao.insert(tempCat, testUserId);

      final tx = TransactionModel(
        id: 'test_tx_id',
        amount: 45.99,
        type: 'expense',
        categoryId: 'temp_cat_tx',
        note: 'Birthday Gift',
        paymentMethod: 'card',
        date: DateTime(2026, 7, 9),
        receiptPath: '/local/path/receipt.jpg',
        isSynced: false,
        createdAt: DateTime.now(),
      );

      // Create
      int result = await transactionDao.insert(tx, testUserId);
      expect(result, greaterThan(0));

      // Read All & Read for Month
      final allTxs = await transactionDao.getAll(testUserId);
      expect(allTxs.any((t) => t.id == 'test_tx_id'), isTrue);

      final monthTxs = await transactionDao.getForMonth('2026-07', testUserId);
      expect(monthTxs.any((t) => t.id == 'test_tx_id'), isTrue);

      // Update Sync Status
      int syncRes = await transactionDao.markAsSynced('test_tx_id', testUserId);
      expect(syncRes, greaterThan(0));

      final unsynced = await transactionDao.getUnsynced(testUserId);
      expect(unsynced.any((t) => t.id == 'test_tx_id'), isFalse);

      // Update Transaction
      final updatedTx = tx.copyWith(amount: 50.00);
      int updateRes = await transactionDao.update(updatedTx, testUserId);
      expect(updateRes, greaterThan(0));

      // Delete
      int deleteRes = await transactionDao.delete('test_tx_id', testUserId);
      expect(deleteRes, greaterThan(0));

      // Clean up category
      await categoryDao.delete('temp_cat_tx', testUserId);
    });

    test('4. Budget DAO CRUD Operations', () async {
      final budget = BudgetModel(
        id: 'test_budget_id',
        categoryId: null, // Overall budget
        amount: 1500.00,
        month: '2026-07',
        alertSent80: false,
        alertSent100: false,
      );

      // Create
      int result = await budgetDao.insert(budget, testUserId);
      expect(result, greaterThan(0));

      // Read For Month
      final budgets = await budgetDao.getForMonth('2026-07', testUserId);
      expect(budgets.any((b) => b.id == 'test_budget_id'), isTrue);

      // Read For Category (Overall)
      final overallBudget = await budgetDao.getForCategory('2026-07', null, testUserId);
      expect(overallBudget, isNotNull);
      expect(overallBudget!.amount, equals(1500.00));

      // Update Alert Flags
      int alertRes = await budgetDao.updateAlertFlags('test_budget_id', true, false, testUserId);
      expect(alertRes, greaterThan(0));

      final updatedBudget = await budgetDao.getForCategory('2026-07', null, testUserId);
      expect(updatedBudget!.alertSent80, isTrue);
      expect(updatedBudget.alertSent100, isFalse);

      // Delete
      int deleteRes = await budgetDao.delete('test_budget_id', testUserId);
      expect(deleteRes, greaterThan(0));

      final deletedBudget = await budgetDao.getForCategory('2026-07', null, testUserId);
      expect(deletedBudget, isNull);
    });
  });
}
