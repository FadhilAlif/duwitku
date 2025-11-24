import 'package:duwitku/models/transaction.dart';
import 'package:duwitku/models/transaction_filter_state.dart';
import 'package:duwitku/repositories/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Transaction Repository Provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

// 2. Filter State Provider
class TransactionFilterNotifier extends Notifier<TransactionFilterState> {
  @override
  TransactionFilterState build() {
    final now = DateTime.now();
    // Default to current month
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return TransactionFilterState(
      dateRange: DateTimeRange(start: startDate, end: endDate),
    );
  }

  void setDateRange(DateTimeRange range) {
    // Ensure the end date includes the full day
    final adjustedEnd = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
    );
    state = state.copyWith(
      dateRange: DateTimeRange(start: range.start, end: adjustedEnd),
    );
  }

  void setCategoryIds(List<int> ids) {
    state = state.copyWith(selectedCategoryIds: ids);
  }

  void setAmountRange(RangeValues? range) {
    state = state.copyWith(amountRange: range);
  }

  void setTypes(List<TransactionType> types) {
    state = state.copyWith(selectedTypes: types);
  }

  void setMonth(DateTime month) {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    state = state.copyWith(
      dateRange: DateTimeRange(start: startDate, end: endDate),
    );
  }

  void reset() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    state = TransactionFilterState(
      dateRange: DateTimeRange(start: startDate, end: endDate),
    );
  }
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilterState>(() {
      return TransactionFilterNotifier();
    });

// 3. The main stream provider that watches the filter
final filteredTransactionsStreamProvider =
    StreamProvider.autoDispose<List<Transaction>>((ref) {
      final transactionRepository = ref.watch(transactionRepositoryProvider);
      final filterState = ref.watch(transactionFilterProvider);

      // Get stream based on date range
      final stream = transactionRepository.getTransactionsStream(
        startDate: filterState.dateRange.start,
        endDate: filterState.dateRange.end,
      );

      return stream.map((transactions) {
        return transactions.where((trx) {
          // Filter by Category
          if (filterState.selectedCategoryIds.isNotEmpty) {
            if (!filterState.selectedCategoryIds.contains(trx.categoryId)) {
              return false;
            }
          }

          // Filter by Amount
          if (filterState.amountRange != null) {
            if (trx.amount < filterState.amountRange!.start ||
                trx.amount > filterState.amountRange!.end) {
              return false;
            }
          }

          // Filter by Type
          if (filterState.selectedTypes.isNotEmpty) {
            if (!filterState.selectedTypes.contains(trx.type)) {
              return false;
            }
          }

          return true;
        }).toList();
      });
    });

final maxTransactionAmountProvider = FutureProvider.autoDispose<double>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getMaxTransactionAmount();
});
