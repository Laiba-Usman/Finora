import 'dart:convert';

/// Represents a Category for financial transactions.
class CategoryModel {
  /// The unique identifier of the category (UUID).
  final String id;

  /// The human-readable name of the category (e.g., 'Food & Dining', 'Salary').
  final String name;

  /// The icon name or code point string used to represent the category visually.
  final String icon;

  /// The Hex code representing the primary accent color of the category (e.g., '#FF5733').
  final String color;

  /// The type of the category: either 'income' or 'expense'.
  final String type;

  /// True if this is a user-created custom category, false for system default categories.
  final bool isCustom;

  /// Default constructor for CategoryModel.
  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isCustom = false,
  });

  /// Creates a copy of this CategoryModel but with the given fields replaced with new values.
  CategoryModel copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    String? type,
    bool? isCustom,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  /// Converts this CategoryModel to a Map of dynamic values, suitable for Database/Firestore serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'is_custom': isCustom ? 1 : 0,
    };
  }

  /// Reconstructs a CategoryModel from a Map of values.
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: map['color'] as String,
      type: map['type'] as String,
      isCustom: (map['is_custom'] as int? ?? 0) == 1,
    );
  }

  /// Serializes the model into a JSON string.
  String toJson() => json.encode(toMap());

  /// Deserializes a JSON string into a CategoryModel instance.
  factory CategoryModel.fromJson(String source) => 
      CategoryModel.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Custom structural equality override.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is CategoryModel &&
      other.id == id &&
      other.name == name &&
      other.icon == icon &&
      other.color == color &&
      other.type == type &&
      other.isCustom == isCustom;
  }

  /// Custom hashCode override.
  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      icon.hashCode ^
      color.hashCode ^
      type.hashCode ^
      isCustom.hashCode;
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, icon: $icon, color: $color, type: $type, isCustom: $isCustom)';
  }
}
