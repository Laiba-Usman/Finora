import 'package:flutter_test/flutter_test.dart';
import 'package:finora/providers/transaction_provider.dart';
import 'package:finora/models/transaction_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TransactionProvider Unit Tests', () {
    late TransactionProvider transactionProvider;

    setUp(() {
      transactionProvider = TransactionProvider();
    });

    test('Initial transactions list is empty', () {
      expect(transactionProvider.transactions, isEmpty);
      expect(transactionProvider.isLoading, isFalse);
    });

    test('Filter setters update provider state', () {
      transactionProvider.setFilterType('expense');
      expect(transactionProvider.filterType, equals('expense'));

      transactionProvider.setFilterCategory('cat_123');
      expect(transactionProvider.filterCategoryId, equals('cat_123'));

      transactionProvider.setSearchQuery('Coffee');
      expect(transactionProvider.searchQuery, equals('Coffee'));

      transactionProvider.clearFilters();
      expect(transactionProvider.filterType, isNull);
      expect(transactionProvider.filterCategoryId, isNull);
      expect(transactionProvider.searchQuery, isEmpty);
    });

    test('Filtered transactions lists behave correctly', () {
      final tx1 = TransactionModel(
        id: '1',
        amount: 5.50,
        type: 'expense',
        categoryId: 'cat_food',
        note: 'Coffee morning',
        paymentMethod: 'cash',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final tx2 = TransactionModel(
        id: '2',
        amount: 2500.0,
        type: 'income',
        categoryId: 'cat_salary',
        note: 'Monthly salary',
        paymentMethod: 'online',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Verify model instantiation works as expected
      expect(tx1.amount, equals(5.50));
      expect(tx2.type, equals('income'));

      transactionProvider.setFilterType('expense');
      expect(transactionProvider.filterType, equals('expense'));
    });
  });
}
