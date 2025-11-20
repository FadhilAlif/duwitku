enum TransactionType {
  income,
  expense,
}

enum SourceType {
  app,
  receiptScan,
  chatPrompt,
  initial,
}

extension StringExtension on String {
  TransactionType get toTransactionType {
    switch (this) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      default:
        throw Exception('Unknown TransactionType: $this');
    }
  }

  SourceType get toSourceType {
    switch (this) {
      case 'app':
        return SourceType.app;
      case 'receipt_scan':
        return SourceType.receiptScan;
      case 'chat_prompt':
        return SourceType.chatPrompt;
      case 'initial':
        return SourceType.initial;
      default:
        throw Exception('Unknown SourceType: $this');
    }
  }
}

class Transaction {
  final String id;
  final String userId;
  final int categoryId;
  final double amount;
  final DateTime transactionDate;
  final TransactionType type;
  final String? description;
  final SourceType sourceType;
  final String? receiptImageUrl;

  Transaction({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.transactionDate,
    required this.type,
    this.description,
    required this.sourceType,
    this.receiptImageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'transaction_date': transactionDate.toIso8601String(),
      'type': type.name,
      'description': description,
      'source_type': sourceType.name,
      'receipt_image_url': receiptImageUrl,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as int,
      amount: (json['amount'] as num).toDouble(),
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      type: (json['type'] as String).toTransactionType,
      description: json['description'] as String?,
      sourceType: (json['source_type'] as String).toSourceType,
      receiptImageUrl: json['receipt_image_url'] as String?,
    );
  }
}
