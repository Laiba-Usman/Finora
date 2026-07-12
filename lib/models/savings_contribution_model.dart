class SavingsContributionModel {
  final String id;
  final String goalId;
  final double amount;
  final DateTime timestamp;

  SavingsContributionModel({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SavingsContributionModel.fromMap(Map<String, dynamic> map) {
    return SavingsContributionModel(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      amount: map['amount'] as double,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
