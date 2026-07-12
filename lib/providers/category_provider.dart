import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/category_dao.dart';
import '../models/category_model.dart';
import '../services/firestore_service.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryDao _categoryDao = CategoryDao();
  final FirestoreService _firestoreService = FirestoreService();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<CategoryModel> get expenseCategories =>
      _categories.where((cat) => cat.type == 'expense').toList();

  List<CategoryModel> get incomeCategories =>
      _categories.where((cat) => cat.type == 'income').toList();

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearData() {
    _categories = [];
    notifyListeners();
  }

  // Helper to get active user ID
  String _getUserId({String? passedId}) {
    return passedId ?? FirebaseAuth.instance.currentUser?.uid ?? 'test_user';
  }

  // Load categories from SQLite database
  Future<void> loadCategories() async {
    final userId = _getUserId();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _categories = await _categoryDao.getAll(userId);
    } catch (e) {
      _errorMessage = 'Failed to load categories: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add custom category and sync to Firestore
  Future<void> addCategory(CategoryModel category, {String? userId}) async {
    final activeUserId = _getUserId(passedId: userId);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _categoryDao.insert(category, activeUserId);
      
      if (category.isCustom && FirebaseAuth.instance.currentUser != null && !FirebaseAuth.instance.currentUser!.isAnonymous) {
        try {
          await _firestoreService.syncCategory(activeUserId, category);
        } catch (cloudErr) {
          print('Category cloud sync failed: $cloudErr. Will sync later.');
        }
      }
      
      await _categoriesAndResetState(activeUserId);
    } catch (e) {
      _errorMessage = 'Failed to add category: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update custom category and sync to Firestore
  Future<void> updateCategory(CategoryModel category, {String? userId}) async {
    final activeUserId = _getUserId(passedId: userId);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _categoryDao.update(category, activeUserId);
      
      if (category.isCustom && FirebaseAuth.instance.currentUser != null && !FirebaseAuth.instance.currentUser!.isAnonymous) {
        try {
          await _firestoreService.syncCategory(activeUserId, category);
        } catch (cloudErr) {
          print('Category cloud sync failed: $cloudErr.');
        }
      }
      
      await _categoriesAndResetState(activeUserId);
    } catch (e) {
      _errorMessage = 'Failed to update category: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Delete custom category and remove from Firestore
  Future<void> deleteCategory(String id, {String? userId}) async {
    final activeUserId = _getUserId(passedId: userId);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _categoryDao.delete(id, activeUserId);
      
      if (FirebaseAuth.instance.currentUser != null && !FirebaseAuth.instance.currentUser!.isAnonymous) {
        try {
          await _firestoreService.deleteCategory(activeUserId, id);
        } catch (cloudErr) {
          print('Category cloud delete failed: $cloudErr.');
        }
      }
      
      await _categoriesAndResetState(activeUserId);
    } catch (e) {
      _errorMessage = 'Failed to delete category: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _categoriesAndResetState(String userId) async {
    _categories = await _categoryDao.getAll(userId);
    _isLoading = false;
    notifyListeners();
  }

  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  // Sync all custom categories to Firestore
  Future<void> syncAllCategories(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final customCats = _categories.where((c) => c.isCustom).toList();
      for (var cat in customCats) {
        await _firestoreService.syncCategory(userId, cat);
      }
    } catch (e) {
      _errorMessage = 'Cloud synchronization failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Restore custom categories from Firestore during data restore
  Future<void> restoreCategories(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final cloudCats = await _firestoreService.fetchCategories(userId);
      for (var cat in cloudCats) {
        await _categoryDao.insert(cat, userId);
      }
      _categories = await _categoryDao.getAll(userId);
    } catch (e) {
      _errorMessage = 'Cloud restoration failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
