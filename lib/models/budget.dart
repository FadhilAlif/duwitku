class Budget {
  final int id;
  final String userId;
  final int categoryId;
  final double amountLimit;
  final DateTime startDate;
  final DateTime endDate;

  Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amountLimit,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'amount_limit': amountLimit,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as int,
      amountLimit: (json['amount_limit'] as num).toDouble(),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
    );
  }
}