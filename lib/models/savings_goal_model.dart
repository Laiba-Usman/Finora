class SavingsGoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final DateTime createdAt;

  SavingsGoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SavingsGoalModel.fromMap(Map<String, dynamic> map) {
    return SavingsGoalModel(
      id: map['id'] as String,
      name: map['name'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num).toDouble(),
      targetDate: map['target_date'] != null ? DateTime.parse(map['target_date'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  SavingsGoalModel copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    DateTime? createdAt,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
