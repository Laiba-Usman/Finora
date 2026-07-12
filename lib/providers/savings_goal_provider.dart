import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../database/savings_goal_dao.dart';
import '../database/savings_contribution_dao.dart';
import '../models/savings_goal_model.dart';
import '../models/savings_contribution_model.dart';

class SavingsGoalProvider with ChangeNotifier {
  final SavingsGoalDao _savingsGoalDao = SavingsGoalDao();
  final SavingsContributionDao _contributionDao = SavingsContributionDao();
  List<SavingsGoalModel> _goals = [];
  bool _isLoading = false;

  List<SavingsGoalModel> get goals => _goals;
  bool get isLoading => _isLoading;

  void clearData() {
    _goals = [];
    notifyListeners();
  }

  // Helper to get active user ID
  String _getUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? 'test_user';
  }

  Future<void> loadGoals() async {
    final userId = _getUserId();
    _isLoading = true;
    notifyListeners();
    try {
      _goals = await _savingsGoalDao.getAll(userId);
    } catch (e) {
      debugPrint('Error loading savings goals: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGoal(String name, double targetAmount, DateTime? targetDate) async {
    final userId = _getUserId();
    final newGoal = SavingsGoalModel(
      id: const Uuid().v4(),
      name: name,
      targetAmount: targetAmount,
      currentAmount: 0.0,
      targetDate: targetDate,
      createdAt: DateTime.now(),
    );

    try {
      await _savingsGoalDao.insert(newGoal, userId);
      await loadGoals();
    } catch (e) {
      debugPrint('Error adding savings goal: $e');
    }
  }

  Future<void> updateGoal(String id, String name, double targetAmount, DateTime? targetDate) async {
    final userId = _getUserId();
    try {
      final goal = _goals.firstWhere((g) => g.id == id);
      final updatedGoal = goal.copyWith(
        name: name,
        targetAmount: targetAmount,
        targetDate: targetDate,
      );
      await _savingsGoalDao.update(updatedGoal, userId);
      await loadGoals();
    } catch (e) {
      debugPrint('Error updating savings goal: $e');
    }
  }

  Future<void> addMoneyToGoal(String id, double amount) async {
    final userId = _getUserId();
    try {
      final goal = _goals.firstWhere((g) => g.id == id);
      final updatedGoal = goal.copyWith(
        currentAmount: goal.currentAmount + amount,
      );
      await _savingsGoalDao.update(updatedGoal, userId);

      // Log the savings contribution history
      final contrib = SavingsContributionModel(
        id: const Uuid().v4(),
        goalId: id,
        amount: amount,
        timestamp: DateTime.now(),
      );
      await _contributionDao.insert(contrib, userId);

      await loadGoals();
    } catch (e) {
      debugPrint('Error adding money to goal: $e');
    }
  }

  Future<List<SavingsContributionModel>> getContributionsForGoal(String goalId) async {
    final userId = _getUserId();
    try {
      return await _contributionDao.getByGoal(goalId, userId);
    } catch (e) {
      debugPrint('Error loading contributions: $e');
      return [];
    }
  }

  Future<void> deleteGoal(String id) async {
    final userId = _getUserId();
    try {
      await _savingsGoalDao.delete(id, userId);
      await _contributionDao.deleteByGoal(id, userId);
      await loadGoals();
    } catch (e) {
      debugPrint('Error deleting savings goal: $e');
    }
  }
}
