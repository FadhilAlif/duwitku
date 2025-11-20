enum CategoryType {
  income,
  expense,
}

extension CategoryTypeExtension on String {
  CategoryType get toCategoryType {
    switch (this) {
      case 'income':
        return CategoryType.income;
      case 'expense':
        return CategoryType.expense;
      default:
        throw Exception('Unknown CategoryType: $this');
    }
  }
}

class Category {
  final int id;
  final String? userId;
  final String name;
  final CategoryType type;
  final String? iconName;
  final bool isDefault;

  Category({
    required this.id,
    this.userId,
    required this.name,
    required this.type,
    this.iconName,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'icon_name': iconName,
      'user_id': userId,
      'is_default': isDefault,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      type: (json['type'] as String).toCategoryType,
      iconName: json['icon_name'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Category &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.type == type &&
        other.iconName == iconName &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        name.hashCode ^
        type.hashCode ^
        iconName.hashCode ^
        isDefault.hashCode;
  }
}
