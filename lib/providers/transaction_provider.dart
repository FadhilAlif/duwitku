import 'package:duwitku/models/transaction.dart';
import 'package:duwitku/repositories/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Transaction Repository Provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

// 2. Filter State Provider (holds the selected month)
class TransactionFilterNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    return DateTime.now();
  }

  void setMonth(DateTime month) {
    state = month;
  }
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, DateTime>(() {
      return TransactionFilterNotifier();
    });

// 3. The main stream provider that watches the filter
final filteredTransactionsStreamProvider =
    StreamProvider.autoDispose<List<Transaction>>((ref) {
      final transactionRepository = ref.watch(transactionRepositoryProvider);
      final selectedMonth = ref.watch(transactionFilterProvider);

      // Calculate start and end dates for the selected month
      final startDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
      final endDate = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
        0,
        23,
        59,
        59,
      );

      return transactionRepository.getTransactionsStream(
        startDate: startDate,
        endDate: endDate,
      );
    });
