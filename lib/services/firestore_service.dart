import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/budget_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  FirestoreService() {
    // Explicitly configure Firestore offline persistence and settings
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (_) {
      // settings can only be set once before any usage
    }
  }

  // Collection reference helpers
  CollectionReference _userTxRef(String userId) => 
      _firestore.collection('users').doc(userId).collection('transactions');

  CollectionReference _userCatRef(String userId) => 
      _firestore.collection('users').doc(userId).collection('categories');

  CollectionReference _userBudgetRef(String userId) => 
      _firestore.collection('users').doc(userId).collection('budgets');

  // Sync single transaction to firestore
  Future<void> syncTransaction(String userId, TransactionModel tx) async {
    try {
      await _userTxRef(userId).doc(tx.id).set(tx.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Bulk sync list of transactions
  Future<void> syncTransactions(String userId, List<TransactionModel> transactions) async {
    try {
      final batch = _firestore.batch();
      for (var tx in transactions) {
        final docRef = _userTxRef(userId).doc(tx.id);
        batch.set(docRef, tx.toMap());
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  // Fetch transactions from firestore
  Future<List<TransactionModel>> fetchTransactions(String userId) async {
    try {
      final snapshot = await _userTxRef(userId).get();
      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Delete transaction from firestore
  Future<void> deleteTransaction(String userId, String transactionId) async {
    try {
      await _userTxRef(userId).doc(transactionId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Sync single category
  Future<void> syncCategory(String userId, CategoryModel category) async {
    try {
      await _userCatRef(userId).doc(category.id).set(category.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Delete category from firestore
  Future<void> deleteCategory(String userId, String categoryId) async {
    try {
      await _userCatRef(userId).doc(categoryId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Fetch categories
  Future<List<CategoryModel>> fetchCategories(String userId) async {
    try {
      final snapshot = await _userCatRef(userId).get();
      return snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Sync single budget
  Future<void> syncBudget(String userId, BudgetModel budget) async {
    try {
      await _userBudgetRef(userId).doc(budget.id).set(budget.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Fetch budgets
  Future<List<BudgetModel>> fetchBudgets(String userId) async {
    try {
      final snapshot = await _userBudgetRef(userId).get();
      return snapshot.docs
          .map((doc) => BudgetModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Sync profile details
  Future<void> syncProfile(String userId, UserModel userModel) async {
    try {
      await _firestore.collection('users').doc(userId).set(userModel.toMap(), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // Fetch profile details
  Future<UserModel?> fetchProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
