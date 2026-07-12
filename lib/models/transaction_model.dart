import 'dart:convert';

/// Represents a financial Transaction (income or expense) logged by the user.
class TransactionModel {
  /// The unique identifier of the transaction (UUID).
  final String id;

  /// The monetary amount of the transaction.
  final double amount;

  /// The type of the transaction: either 'income' or 'expense'.
  final String type;

  /// The category ID associated with this transaction.
  final String categoryId;

  /// An optional tag, description, or comment note from the user.
  final String? note;

  /// The payment method used for this transaction (e.g., 'cash', 'card', 'online').
  final String paymentMethod;

  /// The date and time the transaction occurred.
  final DateTime date;

  /// An optional path string referencing a local receipt image file on device storage.
  final String? receiptPath;

  /// True if the transaction has been backed up/synchronized to cloud Firestore, false otherwise.
  final bool isSynced;

  /// The date and time the transaction record was created on the local database.
  final DateTime createdAt;

  /// Default constructor for TransactionModel.
  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.note,
    required this.paymentMethod,
    required this.date,
    this.receiptPath,
    this.isSynced = false,
    required this.createdAt,
  });

  /// Creates a copy of this TransactionModel but with the given fields replaced with new values.
  TransactionModel copyWith({
    String? id,
    double? amount,
    String? type,
    String? categoryId,
    String? note,
    String? paymentMethod,
    DateTime? date,
    String? receiptPath,
    bool? isSynced,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      receiptPath: receiptPath ?? this.receiptPath,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts this TransactionModel to a Map of dynamic values, suitable for Database/Firestore serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'note': note,
      'payment_method': paymentMethod,
      'date': date.toIso8601String(),
      'receipt_path': receiptPath,
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Reconstructs a TransactionModel from a Map of values.
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      categoryId: map['category_id'] as String,
      note: map['note'] as String?,
      paymentMethod: map['payment_method'] as String,
      date: DateTime.parse(map['date'] as String),
      receiptPath: map['receipt_path'] as String?,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Serializes the model into a JSON string.
  String toJson() => json.encode(toMap());

  /// Deserializes a JSON string into a TransactionModel instance.
  factory TransactionModel.fromJson(String source) => 
      TransactionModel.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Custom structural equality override.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is TransactionModel &&
      other.id == id &&
      other.amount == amount &&
      other.type == type &&
      other.categoryId == categoryId &&
      other.note == note &&
      other.paymentMethod == paymentMethod &&
      other.date == date &&
      other.receiptPath == receiptPath &&
      other.isSynced == isSynced &&
      other.createdAt == createdAt;
  }

  /// Custom hashCode override.
  @override
  int get hashCode {
    return id.hashCode ^
      amount.hashCode ^
      type.hashCode ^
      categoryId.hashCode ^
      note.hashCode ^
      paymentMethod.hashCode ^
      date.hashCode ^
      receiptPath.hashCode ^
      isSynced.hashCode ^
      createdAt.hashCode;
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, amount: $amount, type: $type, categoryId: $categoryId, note: $note, paymentMethod: $paymentMethod, date: $date, receiptPath: $receiptPath, isSynced: $isSynced, createdAt: $createdAt)';
  }
}
