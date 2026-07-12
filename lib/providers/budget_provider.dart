import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../database/budget_dao.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../services/notification_service.dart';
import '../services/firestore_service.dart';

class BudgetProvider with ChangeNotifier {
  final BudgetDao _budgetDao = BudgetDao();
  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();

  List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearData() {
    _budgets = [];
    notifyListeners();
  }

  // Helper to get active user ID
  String _getUserId({String? passedId}) {
    return passedId ?? FirebaseAuth.instance.currentUser?.uid ?? 'test_user';
  }

  String _getSymbol(String code) {
    switch (code) {
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'JPY': return '¥';
      case 'INR': return '₹';
      case 'PKR': return '₨';
      default: return '\$';
    }
  }

  // Load budgets from SQLite database
  Future<void> loadBudgets(String month) async {
    final userId = _getUserId();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _budgets = await _budgetDao.getForMonth(month, userId);
    } catch (e) {
      _errorMessage = 'Failed to load budgets: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set or update a budget
  Future<void> setBudget(BudgetModel budget, {String? userId}) async {
    final activeUserId = _getUserId(passedId: userId);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Check if a budget already exists for this category/month
      final existing = await _budgetDao.getForCategory(budget.month, budget.categoryId, activeUserId);
      final budgetToSave = existing != null
          ? existing.copyWith(
              amount: budget.amount,
              // Reset alert flags if amount increased/changed to allow new alerts
              alertSent80: existing.amount == budget.amount ? existing.alertSent80 : false,
              alertSent100: existing.amount == budget.amount ? existing.alertSent100 : false,
            )
          : budget;

      if (existing != null) {
        await _budgetDao.update(budgetToSave, activeUserId);
      } else {
        await _budgetDao.insert(budgetToSave, activeUserId);
      }

      // If user is authenticated, sync to Firestore
      if (FirebaseAuth.instance.currentUser != null && !FirebaseAuth.instance.currentUser!.isAnonymous) {
        try {
          await _firestoreService.syncBudget(activeUserId, budgetToSave);
        } catch (cloudErr) {
          print('Budget cloud sync failed: $cloudErr. Will sync later.');
        }
      }

      _budgets = await _budgetDao.getForMonth(budget.month, activeUserId);
    } catch (e) {
      _errorMessage = 'Failed to save budget: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a budget
  Future<void> deleteBudget(String id, String month) async {
    final userId = _getUserId();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _budgetDao.delete(id, userId);
      _budgets = await _budgetDao.getForMonth(month, userId);
    } catch (e) {
      _errorMessage = 'Failed to delete budget: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculate current spent amount from a list of transactions for a budget
  double getSpentAmount(BudgetModel budget, List<TransactionModel> transactions) {
    double total = 0;
    for (var tx in transactions) {
      if (tx.type != 'expense') continue;

      final txMonth = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
      if (txMonth != budget.month) continue;

      if (budget.categoryId == null || tx.categoryId == budget.categoryId) {
        total += tx.amount;
      }
    }
    return total;
  }

  // Check budget thresholds and fire notifications if crossed
  Future<void> checkBudgetThresholds(
    List<TransactionModel> transactions,
    String month,
    String? categoryName,
    {String? categoryId}
  ) async {
    final userId = _getUserId();
    try {
      final budget = await _budgetDao.getForCategory(month, categoryId, userId);
      if (budget == null) return;

      final spent = getSpentAmount(budget, transactions);
      final limit = budget.amount;

      if (limit <= 0) return;

      final percent = (spent / limit) * 100;
      final categoryDisplayName = categoryName ?? 'Overall';

      final prefs = await SharedPreferences.getInstance();
      final currency = prefs.getString(AppConstants.keyPrimaryCurrency) ?? AppConstants.defaultCurrency;
      final symbol = _getSymbol(currency);

      bool updated = false;

      if (percent >= 100 && !budget.alertSent100) {
        await _notificationService.showNotification(
          id: budget.hashCode + 100,
          title: '🚨 Budget Exceeded!',
          body: 'You have spent $symbol${spent.toStringAsFixed(2)} of your $symbol${limit.toStringAsFixed(2)} budget for $categoryDisplayName.',
        );
        await _budgetDao.updateAlertFlags(budget.id, budget.alertSent80, true, userId);
        updated = true;
      } else if (percent >= 80 && !budget.alertSent80) {
        await _notificationService.showNotification(
          id: budget.hashCode + 80,
          title: '⚠️ Budget Alert (80%)',
          body: 'You have spent 80% ($symbol${spent.toStringAsFixed(2)} of $symbol${limit.toStringAsFixed(2)}) of your budget for $categoryDisplayName.',
        );
        await _budgetDao.updateAlertFlags(budget.id, true, budget.alertSent100, userId);
        updated = true;
      }

      if (updated) {
        _budgets = await _budgetDao.getForMonth(month, userId);
        notifyListeners();
      }
    } catch (e) {
      print('Error checking budget thresholds: $e');
    }
  }

  // Sync all budgets to Firestore for cloud backups
  Future<void> syncAllBudgets(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      for (var budget in _budgets) {
        await _firestoreService.syncBudget(userId, budget);
      }
    } catch (e) {
      _errorMessage = 'Cloud synchronization failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Restore budgets from Firestore during cloud restore
  Future<void> restoreBudgets(String userId, String currentMonth) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final cloudBudgets = await _firestoreService.fetchBudgets(userId);
      for (var budget in cloudBudgets) {
        await _budgetDao.insert(budget, userId);
      }
      _budgets = await _budgetDao.getForMonth(currentMonth, userId);
    } catch (e) {
      _errorMessage = 'Cloud restoration failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
