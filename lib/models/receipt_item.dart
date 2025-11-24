import 'package:duwitku/models/transaction.dart';

class ReceiptItem {
  String description;
  double amount;
  TransactionType type;
  int? categoryId; // Nullable, to be filled by user or smart matching

  ReceiptItem({
    required this.description,
    required this.amount,
    required this.type,
    this.categoryId,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: (json['type'] as String) == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      categoryId: json['category_id'] as int?,
    );
  }
}
