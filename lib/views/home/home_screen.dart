import 'package:duwitku/providers/category_provider.dart';
import 'package:duwitku/providers/transaction_provider.dart';
import 'package:duwitku/models/transaction.dart' as t;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(transactionFilterProvider);
    final transactionsAsync = ref.watch(filteredTransactionsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              // The router's refreshListenable will handle navigation
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    ref
                        .read(transactionFilterProvider.notifier)
                        .setMonth(
                          DateTime(selectedMonth.year, selectedMonth.month - 1),
                        );
                  },
                ),
                Text(
                  DateFormat.yMMMM().format(selectedMonth),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    ref
                        .read(transactionFilterProvider.notifier)
                        .setMonth(
                          DateTime(selectedMonth.year, selectedMonth.month + 1),
                        );
                  },
                ),
              ],
            ),
          ),
          // Summary Card
          transactionsAsync.when(
            data: (transactions) {
              final totalIncome = transactions
                  .where((trx) => trx.type == t.TransactionType.income)
                  .fold(0.0, (sum, item) => sum + item.amount);
              final totalExpense = transactions
                  .where((trx) => trx.type == t.TransactionType.expense)
                  .fold(0.0, (sum, item) => sum + item.amount);
              final balance = totalIncome - totalExpense;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Balance',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        currencyFormatter.format(balance),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: balance >= 0 ? Colors.green : Colors.red,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SummaryColumn(
                            title: 'Income',
                            amount: totalIncome,
                            color: Colors.green,
                            formatter: currencyFormatter,
                          ),
                          _SummaryColumn(
                            title: 'Expense',
                            amount: totalExpense,
                            color: Colors.red,
                            formatter: currencyFormatter,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => Text('Error: $err'),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Transaction List
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(
                    child: Text('No transactions this month.'),
                  );
                }
                return categoriesAsync.when(
                  data: (categories) {
                    final categoryMap = {for (var c in categories) c.id: c};
                    return ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        final category = categoryMap[transaction.categoryId];
                        final isIncome =
                            transaction.type == t.TransactionType.income;
                        return ListTile(
                          leading: Icon(
                            isIncome
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                          title: Text(
                            transaction.description ?? category?.name ?? 'N/A',
                          ),
                          subtitle: Text(category?.name ?? 'Uncategorized'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isIncome ? '+' : '-'} ${currencyFormatter.format(transaction.amount)}',
                                style: TextStyle(
                                  color: isIncome ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat.yMd().format(
                                  transaction.transactionDate,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('Error loading categories: $err'),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.title,
    required this.amount,
    required this.color,
    required this.formatter,
  });

  final String title;
  final double amount;
  final Color color;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.labelMedium),
        Text(
          formatter.format(amount),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
