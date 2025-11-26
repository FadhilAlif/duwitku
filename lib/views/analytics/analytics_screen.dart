import 'package:duwitku/models/category.dart';
import 'package:duwitku/models/transaction.dart';
import 'package:duwitku/providers/category_provider.dart';
import 'package:duwitku/providers/transaction_provider.dart';
import 'package:duwitku/utils/icon_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:collection/collection.dart';

enum AnalyticsFilter { daily, weekly }

class AnalyticsFilterNotifier extends Notifier<AnalyticsFilter> {
  @override
  AnalyticsFilter build() {
    return AnalyticsFilter.daily;
  }

  void setFilter(AnalyticsFilter filter) {
    state = filter;
  }
}

final analyticsFilterProvider =
    NotifierProvider<AnalyticsFilterNotifier, AnalyticsFilter>(() {
      return AnalyticsFilterNotifier();
    });

class AnalyticsDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    // Default to current month
    return DateTime(now.year, now.month);
  }

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1);
  }
}

final analyticsDateProvider = NotifierProvider<AnalyticsDateNotifier, DateTime>(
  () {
    return AnalyticsDateNotifier();
  },
);

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(analyticsFilterProvider);
    final selectedMonth = ref.watch(analyticsDateProvider);

    // Fetch all transactions for the selected month
    final startDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final endDate = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
      23,
      59,
      59,
    );

    final transactionsAsync = ref.watch(
      analyticsTransactionsProvider(
        DateTimeRange(start: startDate, end: endDate),
      ),
    );
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analisis Keuangan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MonthSelector(),
              const SizedBox(height: 16),
              _FilterSegmentedControl(currentFilter: filter),
              const SizedBox(height: 24),
              if (transactionsAsync.isLoading || categoriesAsync.isLoading)
                const Skeletonizer(enabled: true, child: _LoadingPlaceholder())
              else if (transactionsAsync.hasError)
                Center(child: Text('Error: ${transactionsAsync.error}'))
              else
                _AnalyticsContent(
                  transactions: transactionsAsync.value ?? [],
                  categories: categoriesAsync.value ?? [],
                  filter: filter,
                  selectedMonth: selectedMonth,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthSelector extends ConsumerWidget {
  const _MonthSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(analyticsDateProvider);
    final notifier = ref.read(analyticsDateProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: notifier.previousMonth,
        ),
        Text(
          DateFormat.yMMMM('id_ID').format(selectedMonth),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: notifier.nextMonth,
        ),
      ],
    );
  }
}

final analyticsTransactionsProvider = StreamProvider.family
    .autoDispose<List<Transaction>, DateTimeRange>((ref, range) {
      final repository = ref.watch(transactionRepositoryProvider);
      return repository.getTransactionsStream(
        startDate: range.start,
        endDate: range.end,
      );
    });

class _FilterSegmentedControl extends ConsumerWidget {
  final AnalyticsFilter currentFilter;

  const _FilterSegmentedControl({required this.currentFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<AnalyticsFilter>(
        segments: const [
          ButtonSegment(value: AnalyticsFilter.daily, label: Text('Harian')),
          ButtonSegment(value: AnalyticsFilter.weekly, label: Text('Mingguan')),
        ],
        selected: {currentFilter},
        onSelectionChanged: (Set<AnalyticsFilter> newSelection) {
          ref
              .read(analyticsFilterProvider.notifier)
              .setFilter(newSelection.first);
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF14894e);
            }
            return null;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return Colors.grey[400];
          }),
        ),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 200, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Container(height: 100, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Container(height: 200, color: Colors.grey[300]),
      ],
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  final List<Transaction> transactions;
  final List<Category> categories;
  final AnalyticsFilter filter;
  final DateTime selectedMonth;

  const _AnalyticsContent({
    required this.transactions,
    required this.categories,
    required this.filter,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tren Pemasukan & Pengeluaran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // Legend
        Row(
          children: [
            _LegendItem(color: Colors.green, label: 'Pemasukan'),
            const SizedBox(width: 16),
            _LegendItem(color: Colors.red, label: 'Pengeluaran'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: _IncomeExpenseLineChart(
            transactions: transactions,
            filter: filter,
            selectedMonth: selectedMonth,
          ),
        ),
        const SizedBox(height: 24),
        _TotalSpendingCard(
          totalIncome: totalIncome,
          totalExpense: totalExpense,
        ),
        const SizedBox(height: 24),
        const Text(
          'Smart Overview',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: _SmartOverviewPieChart(
            transactions: transactions,
            categories: categories,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Top Transaksi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _TopTransactionsSection(
          transactions: transactions,
          categories: categories,
        ),
        const SizedBox(height: 50),
      ],
    );
  }
}

class _TotalSpendingCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;

  const _TotalSpendingCard({
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Total Ringkasan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pemasukan',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      currencyFormatter.format(totalIncome),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Pengeluaran',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      currencyFormatter.format(totalExpense),
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Selisih',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  currencyFormatter.format(totalIncome - totalExpense),
                  style: TextStyle(
                    color: (totalIncome - totalExpense) >= 0
                        ? Colors.blue
                        : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeExpenseLineChart extends StatelessWidget {
  final List<Transaction> transactions;
  final AnalyticsFilter filter;
  final DateTime selectedMonth;

  const _IncomeExpenseLineChart({
    required this.transactions,
    required this.filter,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    final dataPoints = _processData();

    if (dataPoints.isEmpty) {
      return const Center(child: Text('Belum ada data untuk ditampilkan'));
    }

    final maxY =
        dataPoints
            .map((e) => e.income > e.expense ? e.income : e.expense)
            .reduce((a, b) => a > b ? a : b) *
        1.2;

    // Determine min and max X based on filter
    double minX = 0;
    double maxX = 0;

    if (filter == AnalyticsFilter.daily) {
      // For daily, we want 1 to EndOfMonthDay
      minX = 1;
      maxX = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
        0,
      ).day.toDouble();
    } else {
      // For weekly, we want W1 to W5 (approx)
      minX = 1;
      maxX = 5;
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                // Only show integers
                if (value % 1 != 0) return const SizedBox.shrink();
                final val = value.toInt();

                if (filter == AnalyticsFilter.daily) {
                  // Show labels every 5 days to avoid crowding
                  if (val % 5 == 0 || val == 1) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('$val', style: const TextStyle(fontSize: 10)),
                    );
                  }
                  return const SizedBox.shrink();
                } else {
                  // Weekly
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('W$val', style: const TextStyle(fontSize: 10)),
                  );
                }
              },
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
        minX: minX,
        maxX: maxX,
        minY: 0,
        maxY: maxY == 0 ? 100000 : maxY,
        lineBarsData: [
          LineChartBarData(
            spots: dataPoints
                .map(
                  (e) => FlSpot(
                    filter == AnalyticsFilter.daily
                        ? e.date.day.toDouble()
                        : _getWeekOfMonth(e.date).toDouble(),
                    e.income,
                  ),
                )
                .toList(),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withAlpha(25),
            ),
          ),
          LineChartBarData(
            spots: dataPoints
                .map(
                  (e) => FlSpot(
                    filter == AnalyticsFilter.daily
                        ? e.date.day.toDouble()
                        : _getWeekOfMonth(e.date).toDouble(),
                    e.expense,
                  ),
                )
                .toList(),
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withAlpha(25),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.blueGrey.withAlpha(204),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final textStyle = TextStyle(
                  color: touchedSpot.bar.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                );
                final currencyFormatter = NumberFormat.compactSimpleCurrency(
                  locale: 'id_ID',
                );
                return LineTooltipItem(
                  '${touchedSpot.barIndex == 0 ? "Pemasukan" : "Pengeluaran"}\n${currencyFormatter.format(touchedSpot.y)}',
                  textStyle,
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  int _getWeekOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final diff = date.difference(firstDayOfMonth).inDays;
    return (diff / 7).ceil() + 1;
  }

  List<_ChartDataPoint> _processData() {
    if (transactions.isEmpty) return [];

    // Sort transactions by date
    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

    if (filter == AnalyticsFilter.daily) {
      final grouped = groupBy(
        sorted,
        (t) => DateFormat('yyyy-MM-dd').format(t.transactionDate),
      );
      return grouped.entries.map((e) {
        final date = DateTime.parse(e.key);
        final income = e.value
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (s, t) => s + t.amount);
        final expense = e.value
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (s, t) => s + t.amount);
        return _ChartDataPoint(date, income, expense);
      }).toList();
    } else {
      // Weekly within month
      final grouped = groupBy(
        sorted,
        (t) => _getWeekOfMonth(t.transactionDate),
      );
      return grouped.entries.map((e) {
        final weekNum = e.key;
        // Just use a representative date for sorting/charting logic if needed
        final date = DateTime(
          selectedMonth.year,
          selectedMonth.month,
          (weekNum - 1) * 7 + 1,
        );

        final income = e.value
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (s, t) => s + t.amount);
        final expense = e.value
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (s, t) => s + t.amount);
        return _ChartDataPoint(date, income, expense);
      }).toList();
    }
  }
}

class _ChartDataPoint {
  final DateTime date;
  final double income;
  final double expense;

  _ChartDataPoint(this.date, this.income, this.expense);
}

class _SmartOverviewPieChart extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Category> categories;

  const _SmartOverviewPieChart({
    required this.transactions,
    required this.categories,
  });

  @override
  State<_SmartOverviewPieChart> createState() => _SmartOverviewPieChartState();
}

class _SmartOverviewPieChartState extends State<_SmartOverviewPieChart> {
  bool _showByIncome = false;
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('Kategori: ', style: TextStyle(fontSize: 12)),
            DropdownButton<bool>(
              value: _showByIncome,
              items: const [
                DropdownMenuItem(
                  value: false,
                  child: Text('Pengeluaran', style: TextStyle(fontSize: 12)),
                ),
                DropdownMenuItem(
                  value: true,
                  child: Text('Pemasukan', style: TextStyle(fontSize: 12)),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _showByIncome = val);
              },
              isDense: true,
              underline: Container(),
            ),
          ],
        ),
        Expanded(
          child: _CategoryPieChart(
            transactions: widget.transactions,
            categories: widget.categories,
            isIncome: _showByIncome,
            touchedIndex: _touchedIndex,
            onTouch: (index) => setState(() => _touchedIndex = index),
          ),
        ),
      ],
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final List<Transaction> transactions;
  final List<Category> categories;
  final bool isIncome;
  final int touchedIndex;
  final Function(int) onTouch;

  const _CategoryPieChart({
    required this.transactions,
    required this.categories,
    required this.isIncome,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final type = isIncome ? TransactionType.income : TransactionType.expense;
    final filteredTrx = transactions.where((t) => t.type == type).toList();

    if (filteredTrx.isEmpty) {
      return const Center(child: Text('Belum ada data kategori.'));
    }

    // Group by Category
    final categoryMap = {for (var c in categories) c.id: c};
    final grouped = groupBy(filteredTrx, (t) => t.categoryId);

    final totalAmount = filteredTrx.fold(0.0, (sum, t) => sum + t.amount);

    final data = grouped.entries.map((e) {
      final catId = e.key;
      final amount = e.value.fold(0.0, (sum, t) => sum + t.amount);
      final category = categoryMap[catId];
      return _CategoryData(
        name: category?.name ?? 'Lainnya',
        amount: amount,
        color:
            Colors.primaries[catId %
                Colors.primaries.length], // Simple color assignment
        icon: category?.iconName ?? 'help_outline',
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    onTouch(-1);
                    return;
                  }
                  onTouch(pieTouchResponse.touchedSection!.touchedSectionIndex);
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              sections: List.generate(data.length, (i) {
                final isTouched = i == touchedIndex;
                final fontSize = isTouched ? 16.0 : 12.0;
                final radius = isTouched ? 60.0 : 50.0;
                final item = data[i];
                final percentage = (item.amount / totalAmount * 100)
                    .toStringAsFixed(0);

                return PieChartSectionData(
                  color: item.color,
                  value: item.amount,
                  title: '$percentage%',
                  radius: radius,
                  titleStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Legend/Details Column
        if (touchedIndex != -1 && touchedIndex < data.length)
          Expanded(
            child: _PieDetails(
              data: data[touchedIndex],
              totalAmount: totalAmount,
            ),
          )
        else
          const Expanded(
            child: Center(
              child: Text(
                'Sentuh chart untuk detail',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}

class _PieDetails extends StatelessWidget {
  final _CategoryData data;
  final double totalAmount;

  const _PieDetails({required this.data, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final percentage = (data.amount / totalAmount * 100).toStringAsFixed(1);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(IconHelper.getIcon(data.icon), color: data.color, size: 32),
        const SizedBox(height: 8),
        Text(
          data.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          '$percentage% dari total',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormatter.format(data.amount),
          style: TextStyle(
            color: data.color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _CategoryData {
  final String name;
  final double amount;
  final Color color;
  final String icon;

  _CategoryData({
    required this.name,
    required this.amount,
    required this.color,
    required this.icon,
  });
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _TopTransactionsSection extends StatelessWidget {
  final List<Transaction> transactions;
  final List<Category> categories;

  const _TopTransactionsSection({
    required this.transactions,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final categoryMap = {for (var c in categories) c.id: c};

    // Top Expenses
    final topExpenses =
        transactions.where((t) => t.type == TransactionType.expense).toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));
    final top3Expenses = topExpenses.take(3).toList();

    // Top Income
    final topIncomes =
        transactions.where((t) => t.type == TransactionType.income).toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));
    final top3Incomes = topIncomes.take(3).toList();

    return Column(
      children: [
        _TopList(
          title: 'Pengeluaran Terbesar',
          transactions: top3Expenses,
          categoryMap: categoryMap,
          isIncome: false,
        ),
        const SizedBox(height: 16),
        _TopList(
          title: 'Pemasukan Terbesar',
          transactions: top3Incomes,
          categoryMap: categoryMap,
          isIncome: true,
        ),
      ],
    );
  }
}

class _TopList extends StatelessWidget {
  final String title;
  final List<Transaction> transactions;
  final Map<int, Category> categoryMap;
  final bool isIncome;

  const _TopList({
    required this.title,
    required this.transactions,
    required this.categoryMap,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (transactions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...transactions.map((t) {
          final category = categoryMap[t.categoryId];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0.5,
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: isIncome
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                child: Icon(
                  IconHelper.getIcon(category?.iconName),
                  color: isIncome ? Colors.green : Colors.red,
                  size: 16,
                ),
              ),
              title: Text(
                t.description ?? category?.name ?? 'T/A',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                DateFormat('d MMM').format(t.transactionDate),
                style: const TextStyle(fontSize: 11),
              ),
              trailing: Text(
                currencyFormatter.format(t.amount),
                style: TextStyle(
                  color: isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
