enum TransactionType { income, expense }

enum SourceType { app, receiptScan, chatPrompt, voiceInput, initial }

extension SourceTypeExtension on SourceType {
  String get toSnakeCase {
    switch (this) {
      case SourceType.app:
        return 'app';
      case SourceType.receiptScan:
        return 'receipt_scan';
      case SourceType.chatPrompt:
        return 'chat_prompt';
      case SourceType.voiceInput:
        return 'voice_input';
      case SourceType.initial:
        return 'initial';
    }
  }
}

extension StringExtension on String {
  TransactionType get toTransactionType {
    switch (this) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      default:
        throw Exception('Tipe Transaksi tidak dikenal: $this');
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
        throw Exception('Tipe Sumber tidak dikenal: $this');
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
      'source_type': sourceType.toSnakeCase,
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
