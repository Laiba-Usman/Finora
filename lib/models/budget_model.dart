import 'dart:convert';

/// Represents a Monthly Budget configuration for a specific category or overall spending.
class BudgetModel {
  /// The unique identifier of the budget (UUID).
  final String id;

  /// The reference identifier of the category this budget limits (nullable).
  /// A null value represents an overall monthly spending budget.
  final String? categoryId;

  /// The maximum spending limit amount allowed for this budget.
  final double amount;

  /// The year and month of the budget in 'YYYY-MM' format (e.g., '2026-07').
  final String month;

  /// Tracks if a local alert has been fired for reaching 80% of the budget.
  final bool alertSent80;

  /// Tracks if a local alert has been fired for reaching 100% of the budget.
  final bool alertSent100;

  /// Default constructor for BudgetModel.
  BudgetModel({
    required this.id,
    this.categoryId,
    required this.amount,
    required this.month,
    this.alertSent80 = false,
    this.alertSent100 = false,
  });

  /// Creates a copy of this BudgetModel but with the given fields replaced with new values.
  BudgetModel copyWith({
    String? id,
    String? categoryId,
    double? amount,
    String? month,
    bool? alertSent80,
    bool? alertSent100,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      alertSent80: alertSent80 ?? this.alertSent80,
      alertSent100: alertSent100 ?? this.alertSent100,
    );
  }

  /// Converts this BudgetModel to a Map of dynamic values, suitable for Database/Firestore serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount': amount,
      'month': month,
      'alert_sent_80': alertSent80 ? 1 : 0,
      'alert_sent_100': alertSent100 ? 1 : 0,
    };
  }

  /// Reconstructs a BudgetModel from a Map of values.
  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      categoryId: map['category_id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      month: map['month'] as String,
      alertSent80: (map['alert_sent_80'] as int? ?? 0) == 1,
      alertSent100: (map['alert_sent_100'] as int? ?? 0) == 1,
    );
  }

  /// Serializes the model into a JSON string.
  String toJson() => json.encode(toMap());

  /// Deserializes a JSON string into a BudgetModel instance.
  factory BudgetModel.fromJson(String source) => 
      BudgetModel.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Custom structural equality override.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is BudgetModel &&
      other.id == id &&
      other.categoryId == categoryId &&
      other.amount == amount &&
      other.month == month &&
      other.alertSent80 == alertSent80 &&
      other.alertSent100 == alertSent100;
  }

  /// Custom hashCode override.
  @override
  int get hashCode {
    return id.hashCode ^
      categoryId.hashCode ^
      amount.hashCode ^
      month.hashCode ^
      alertSent80.hashCode ^
      alertSent100.hashCode;
  }

  @override
  String toString() {
    return 'BudgetModel(id: $id, categoryId: $categoryId, amount: $amount, month: $month, alertSent80: $alertSent80, alertSent100: $alertSent100)';
  }
}
