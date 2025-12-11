import 'package:duwitku/models/budget.dart';
import 'package:duwitku/models/transaction.dart';
import 'package:duwitku/repositories/budget_repository.dart';
import 'package:duwitku/repositories/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the BudgetRepository
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

// State Notifier for the selected month
class BudgetMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    return DateTime.now();
  }

  void setMonth(DateTime month) {
    state = month;
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1, 1);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1, 1);
  }
}

final budgetMonthProvider = NotifierProvider<BudgetMonthNotifier, DateTime>(() {
  return BudgetMonthNotifier();
});

// StreamProvider for budgets based on the selected month
final budgetsStreamProvider = StreamProvider.autoDispose<List<Budget>>((ref) {
  final budgetRepository = ref.watch(budgetRepositoryProvider);
  final selectedMonth = ref.watch(budgetMonthProvider);
  return budgetRepository.streamBudgets(selectedMonth);
});

// StreamProvider for transactions based on the selected budget month
final budgetTransactionsStreamProvider =
    StreamProvider.autoDispose<List<Transaction>>((ref) {
      final transactionRepository = TransactionRepository();
      final selectedMonth = ref.watch(budgetMonthProvider);

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
