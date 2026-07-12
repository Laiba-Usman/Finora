import 'dart:convert';

/// Represents a User profile in the Smart Expense Tracker application.
class UserModel {
  /// The unique identifier of the user (e.g., Firebase uid).
  final String uid;

  /// The full display name of the user.
  final String name;

  /// The email address of the user.
  final String email;

  /// The primary currency code selected by the user (e.g., 'USD', 'EUR').
  final String currency;

  /// The date and time the user account was created.
  final DateTime createdAt;

  /// Optional URL pointing to the user's profile picture.
  final String? photoUrl;

  /// Default constructor for UserModel.
  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.currency,
    required this.createdAt,
    this.photoUrl,
  });

  /// Creates a copy of this UserModel but with the given fields replaced with new values.
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? currency,
    DateTime? createdAt,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  /// Converts this UserModel to a Map of dynamic values, suitable for Database/Firestore serialization.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'photo_url': photoUrl,
    };
  }

  /// Reconstructs a UserModel from a Map of values.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      currency: map['currency'] as String? ?? 'USD',
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String) 
          : DateTime.now(),
      photoUrl: map['photo_url'] as String?,
    );
  }

  /// Serializes the model into a JSON string.
  String toJson() => json.encode(toMap());

  /// Deserializes a JSON string into a UserModel instance.
  factory UserModel.fromJson(String source) => 
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Custom structural equality override.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is UserModel &&
      other.uid == uid &&
      other.name == name &&
      other.email == email &&
      other.currency == currency &&
      other.createdAt == createdAt &&
      other.photoUrl == photoUrl;
  }

  /// Custom hashCode override.
  @override
  int get hashCode {
    return uid.hashCode ^
      name.hashCode ^
      email.hashCode ^
      currency.hashCode ^
      createdAt.hashCode ^
      photoUrl.hashCode;
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, currency: $currency, createdAt: $createdAt, photoUrl: $photoUrl)';
  }
}
