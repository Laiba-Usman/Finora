import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/transaction_dao.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionDao _transactionDao = TransactionDao();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter states
  String? _filterType; // 'income', 'expense', or null
  String? _filterCategoryId;
  String _searchQuery = '';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  String? get filterType => _filterType;
  String? get filterCategoryId => _filterCategoryId;
  String get searchQuery => _searchQuery;

  // Filtered transactions computed on the fly
  List<TransactionModel> get filteredTransactions {
    return _transactions.where((tx) {
      final matchesType = _filterType == null || tx.type == _filterType;
      final matchesCategory = _filterCategoryId == null || tx.categoryId == _filterCategoryId;
      final matchesSearch = _searchQuery.isEmpty || 
          (tx.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      bool matchesDate = true;
      if (_filterStartDate != null && tx.date.isBefore(_filterStartDate!)) {
        matchesDate = false;
      }
      if (_filterEndDate != null && tx.date.isAfter(_filterEndDate!)) {
        matchesDate = false;
      }

      return matchesType && matchesCategory && matchesSearch && matchesDate;
    }).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearData() {
    _transactions = [];
    clearFilters();
    notifyListeners();
  }

  // Helper to get active user ID
  String _getUserId({String? passedId}) {
    return passedId ?? FirebaseAuth.instance.currentUser?.uid ?? 'test_user';
  }

  // Load transactions from SQLite database
  Future<void> loadTransactions() async {
    final userId = _getUserId();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _transactions = await _transactionDao.getAll(userId);
    } catch (e) {
      _errorMessage = 'Failed to load transactions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new transaction
  Future<void> addTransaction(TransactionModel transaction, {String? userId}) async {
    final activeUserId = _getUserId(passedId: userId);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      var txToSave = transaction;

      // If we have a local receipt image and are logged in, upload it to storage
      if (txToSave.receiptPath != null && !txToSave.receiptPath!.startsWith('http')) {
        try {
          final downloadUrl = await _storageService.uploadReceipt(
            txToSave.receiptPath!,
            activeUserId,
            txToSave.id,
          );
          txToSave = txToSave.copyWith(receiptPath: downloadUrl);
        } catch (storageErr) {
          print('Failed to upload receipt: $storageErr. Proceeding with local path.');
        }
      }

      await _transactionDao.insert(txToSave, activeUserId);
      _transactions = await _transactionDao.getAll(activeUserId);

      if (FirebaseAuth.instance.currentUser != null && !FirebaseAuth.instance.currentUser!.isAnonymous) {
        try {
          await _firestoreService.syncTransaction(activeUserId, txToSave);
          await _transactionDao.markAsSynced(txToSave.id, activeUserId);
          _transactions = await _transactionDao.getAll(activeUserId);
        } catch (cloudErr) {
          print('Transaction cloud sync failed: $cloudErr. Will sync later.');
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to save transaction: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update a transaction
  Future<void> updateTransaction(TransactionModel transaction, {String? userId}) async {
    final activeUserId = _getUserId(passedId: userId);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      var txToSave = transaction.copyWith(isSynced: false);

      // If we have a local receipt image and are logged in, upload it to storage
      if (txToSave.receiptPath != null && !txToSave.receiptPath!.startsWith('http')) {
        try {
          final downloadUrl = await _storageService.uploadReceipt(
            txToSave.receiptPath!,
            activeUserId,
            txToSave.id,
          );
          txToSave = txToSave.copyWith(receiptPath: downloadUrl);
        } catch (storageErr) {
          print('Failed to upload receipt: $storageErr. Proceeding with local path.');
        }
      }

      await _transactionDao.update(txToSave, activeUserId);
      _transactions = await _transactionDao.getAll(activeUserId);

      if (FirebaseAuth.instance.currentUser != null && !FirebaseAuth.instance.currentUser!.isAnonymous) {
        try {
          await _firestoreService.syncTransaction(activeUserId, txToSave);
          await _transactionDao.markAsSynced(txToSave.id, activeUserId);
          _transactions = await _transactionDao.getAll(activeUserId);
        } catch (cloudErr) {
          print('Transaction cloud sync failed: $cloudErr. Will sync later.');
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to update transaction: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a transaction
  Future<void> deleteTransaction(String id, {String? userId}) async {
    final activeUserId = _getUserId(passedId: userId);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _transactionDao.delete(id, activeUserId);
      _transactions = await _transactionDao.getAll(activeUserId);
      if (FirebaseAuth.instance.currentUser != null && !FirebaseAuth.instance.currentUser!.isAnonymous) {
        try {
          await _firestoreService.deleteTransaction(activeUserId, id);
        } catch (cloudErr) {
          print('Transaction cloud delete failed: $cloudErr.');
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to delete transaction: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter setters
  void setFilterType(String? type) {
    _filterType = type;
    notifyListeners();
  }

  void setFilterCategory(String? categoryId) {
    _filterCategoryId = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _filterStartDate = start;
    _filterEndDate = end;
    notifyListeners();
  }

  void clearFilters() {
    _filterType = null;
    _filterCategoryId = null;
    _searchQuery = '';
    _filterStartDate = null;
    _filterEndDate = null;
    notifyListeners();
  }

  // Cloud Sync trigger
  Future<void> syncUnsyncedTransactions(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final unsynced = await _transactionDao.getUnsynced(userId);
      if (unsynced.isEmpty) return;

      await _firestoreService.syncTransactions(userId, unsynced);
      for (var tx in unsynced) {
        await _transactionDao.markAsSynced(tx.id, userId);
      }
      _transactions = await _transactionDao.getAll(userId);
    } catch (e) {
      _errorMessage = 'Cloud synchronization failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
