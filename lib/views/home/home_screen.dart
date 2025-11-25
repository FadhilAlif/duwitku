import 'package:duwitku/models/category.dart';
import 'package:duwitku/providers/category_provider.dart';
import 'package:duwitku/providers/transaction_provider.dart';
import 'package:duwitku/providers/ui_provider.dart';
import 'package:duwitku/models/transaction.dart' as t;
import 'package:duwitku/utils/icon_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(filteredTransactionsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final isBalanceVisible = ref.watch(isBalanceVisibleProvider);

    final isLoading = transactionsAsync.isLoading || categoriesAsync.isLoading;

    // Generate dummy data for loading state
    final transactions = isLoading
        ? List.generate(
            5,
            (index) => t.Transaction(
              id: 'dummy_$index',
              userId: 'dummy',
              categoryId: 0,
              amount: 100000,
              transactionDate: DateTime.now(),
              type: index % 2 == 0
                  ? t.TransactionType.income
                  : t.TransactionType.expense,
              sourceType: t.SourceType.app,
              description: 'Loading Transaction...',
            ),
          )
        : transactionsAsync.asData?.value ?? [];

    final categories = isLoading
        ? [
            Category(
              id: 0,
              name: 'Loading...',
              type: CategoryType.expense,
              iconName: 'help_outline',
            ),
          ]
        : categoriesAsync.asData?.value ?? [];

    final categoryMap = {for (var c in categories) c.id: c};

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Beranda',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: Skeletonizer(
        enabled: isLoading,
        child: _buildHomeScreenContent(
          context,
          ref,
          transactions,
          categoryMap,
          isBalanceVisible,
        ),
      ),
    );
  }

  Widget _buildHomeScreenContent(
    BuildContext context,
    WidgetRef ref,
    List<t.Transaction> transactions,
    Map<int, Category> categoryMap,
    bool isBalanceVisible,
  ) {
    final totalIncome = transactions
        .where((trx) => trx.type == t.TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
    final totalExpense = transactions
        .where((trx) => trx.type == t.TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
    final balance = totalIncome - totalExpense;

    final now = DateTime.now();
    final todayTransactions = transactions.where((trx) {
      return trx.transactionDate.year == now.year &&
          trx.transactionDate.month == now.month &&
          trx.transactionDate.day == now.day;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(filteredTransactionsStreamProvider);
        ref.invalidate(categoriesStreamProvider);
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const _MonthSelector(),
            _SummaryCard(
              balance: balance,
              totalIncome: totalIncome,
              totalExpense: totalExpense,
              isVisible: isBalanceVisible,
              onToggleVisibility: () =>
                  ref.read(isBalanceVisibleProvider.notifier).toggle(),
            ),
            _TransactionsChart(transactions: transactions),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transaksi Terkini',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(bottomNavIndexProvider.notifier).setIndex(1);
                    },
                    child: const Text('Lihat semua'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: _TransactionList(
                transactions: todayTransactions,
                categoryMap: categoryMap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ... _MonthSelector remains unchanged ...

class _MonthSelector extends ConsumerWidget {
  const _MonthSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(transactionFilterProvider);
    final selectedMonth = filterState.dateRange.start;
    final notifier = ref.read(transactionFilterProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => notifier.setMonth(
              DateTime(selectedMonth.year, selectedMonth.month - 1),
            ),
          ),
          Text(
            DateFormat.yMMMM('id_ID').format(selectedMonth),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => notifier.setMonth(
              DateTime(selectedMonth.year, selectedMonth.month + 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double balance;
  final double totalIncome;
  final double totalExpense;
  final bool isVisible;
  final VoidCallback onToggleVisibility;

  const _SummaryCard({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.isVisible,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(77),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Saldo',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                ),
                onPressed: onToggleVisibility,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isVisible ? currencyFormatter.format(balance) : 'Rp ********',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryItem(
                icon: Icons.arrow_downward,
                title: 'Pemasukan',
                amount: totalIncome,
                color: Colors.white,
                formatter: currencyFormatter,
                isVisible: isVisible,
              ),
              _SummaryItem(
                icon: Icons.arrow_upward,
                title: 'Pengeluaran',
                amount: totalExpense,
                color: Colors.white,
                formatter: currencyFormatter,
                isVisible: isVisible,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.title,
    required this.amount,
    required this.color,
    required this.formatter,
    required this.isVisible,
  });

  final IconData icon;
  final String title;
  final double amount;
  final Color color;
  final NumberFormat formatter;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color.withAlpha((255 * 0.8).round()),
                fontSize: 14,
              ),
            ),
            Text(
              isVisible ? formatter.format(amount) : '********',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TransactionsChart extends StatelessWidget {
  final List<t.Transaction> transactions;

  const _TransactionsChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final dailySummary = _calculateDailySummary(transactions);

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _calculateMaxY(dailySummary),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.blueGrey,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final currencyFormatter = NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                );
                return BarTooltipItem(
                  currencyFormatter.format(rod.toY),
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() < 0 ||
                      value.toInt() >= dailySummary.length) {
                    return const SizedBox.shrink();
                  }
                  final day = dailySummary[value.toInt()].day;
                  return Text(
                    DateFormat('E', 'id_ID').format(day).substring(0, 1),
                    style: const TextStyle(fontSize: 12),
                  );
                },
                reservedSize: 24,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: dailySummary.asMap().entries.map((entry) {
            final index = entry.key;
            final summary = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: summary.expense,
                  color: Colors.redAccent,
                  width: 8,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: summary.income,
                  color: Colors.lightGreenAccent,
                  width: 8,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  List<_DailySummary> _calculateDailySummary(List<t.Transaction> transactions) {
    final now = DateTime.now();
    final last7Days = List.generate(
      7,
      (index) => now.subtract(Duration(days: index)),
    );

    final summaries = last7Days.map((day) {
      final dayTransactions = transactions.where(
        (trx) =>
            trx.transactionDate.year == day.year &&
            trx.transactionDate.month == day.month &&
            trx.transactionDate.day == day.day,
      );

      final income = dayTransactions
          .where((trx) => trx.type == t.TransactionType.income)
          .fold(0.0, (sum, item) => sum + item.amount);

      final expense = dayTransactions
          .where((trx) => trx.type == t.TransactionType.expense)
          .fold(0.0, (sum, item) => sum + item.amount);

      return _DailySummary(day: day, income: income, expense: expense);
    }).toList();

    return summaries.reversed.toList();
  }

  double _calculateMaxY(List<_DailySummary> summaries) {
    if (summaries.isEmpty) return 10;

    final maxIncome = summaries
        .map((s) => s.income)
        .reduce((a, b) => a > b ? a : b);
    final maxExpense = summaries
        .map((s) => s.expense)
        .reduce((a, b) => a > b ? a : b);

    final maxVal = maxIncome > maxExpense ? maxIncome : maxExpense;

    return maxVal * 1.2;
  }
}

class _DailySummary {
  final DateTime day;
  final double income;
  final double expense;

  _DailySummary({
    required this.day,
    required this.income,
    required this.expense,
  });
}

class _TransactionList extends StatelessWidget {
  final List<t.Transaction> transactions;
  final Map<int, Category> categoryMap;

  const _TransactionList({
    required this.transactions,
    required this.categoryMap,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(child: Text('Tidak ada transaksi hari ini.'));
    }

    final groupedTransactions = groupBy(
      transactions,
      (t.Transaction trx) =>
          DateFormat('yyyy-MM-dd').format(trx.transactionDate),
    );

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemCount: groupedTransactions.keys.length,
      itemBuilder: (context, index) {
        final dateString = groupedTransactions.keys.elementAt(index);
        final dayTransactions = groupedTransactions[dateString]!;
        final date = DateTime.parse(dateString);

        return _TransactionGroup(
          date: date,
          transactions: dayTransactions,
          categoryMap: categoryMap,
        );
      },
    );
  }
}

class _TransactionGroup extends StatelessWidget {
  final DateTime date;
  final List<t.Transaction> transactions;
  final Map<int, Category> categoryMap;

  const _TransactionGroup({
    required this.date,
    required this.transactions,
    required this.categoryMap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _calculateDayTotal(transactions, currencyFormatter),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...transactions.map((transaction) {
            final category = categoryMap[transaction.categoryId];
            final isIncome = transaction.type == t.TransactionType.income;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isIncome
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                child: Icon(
                  IconHelper.getIcon(category?.iconName),
                  color: isIncome ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
              title: Text(
                transaction.description ?? category?.name ?? 'T/A',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(category?.name ?? 'Tanpa Kategori'),
              trailing: Text(
                '${isIncome ? '+' : '-'} ${currencyFormatter.format(transaction.amount)}',
                style: TextStyle(
                  color: isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Hari Ini';
    } else if (date == yesterday) {
      return 'Kemarin';
    } else {
      return DateFormat.yMMMMd('id_ID').format(date);
    }
  }

  String _calculateDayTotal(
    List<t.Transaction> transactions,
    NumberFormat formatter,
  ) {
    final income = transactions
        .where((trx) => trx.type == t.TransactionType.income)
        .fold(0.0, (sum, trx) => sum + trx.amount);
    final expense = transactions
        .where((trx) => trx.type == t.TransactionType.expense)
        .fold(0.0, (sum, trx) => sum + trx.amount);

    final total = income - expense;

    if (total > 0) {
      return '+${formatter.format(total)}';
    } else {
      return formatter.format(total);
    }
  }
}
