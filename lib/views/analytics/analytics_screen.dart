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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            analyticsTransactionsProvider(
              DateTimeRange(start: startDate, end: endDate),
            ),
          );
          ref.invalidate(categoriesStreamProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerBaseColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final shimmerHighlightColor = isDark ? Colors.grey[700]! : Colors.grey[50]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tren section header skeleton
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: shimmerBaseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 200,
              height: 16,
              decoration: BoxDecoration(
                color: shimmerBaseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Legend skeleton
        Row(
          children: [
            Container(
              width: 100,
              height: 12,
              decoration: BoxDecoration(
                color: shimmerBaseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 100,
              height: 12,
              decoration: BoxDecoration(
                color: shimmerBaseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Chart skeleton
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: shimmerBaseColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Total Ringkasan Card skeleton
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: shimmerBaseColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: shimmerBaseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 80,
                            height: 12,
                            decoration: BoxDecoration(
                              color: shimmerBaseColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 100,
                            height: 16,
                            decoration: BoxDecoration(
                              color: shimmerBaseColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 80,
                            height: 12,
                            decoration: BoxDecoration(
                              color: shimmerBaseColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 100,
                            height: 16,
                            decoration: BoxDecoration(
                              color: shimmerBaseColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Smart Overview section header skeleton
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: shimmerBaseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 150,
              height: 16,
              decoration: BoxDecoration(
                color: shimmerBaseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Donut chart skeleton
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            height: 450,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: shimmerBaseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: shimmerBaseColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: shimmerHighlightColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: shimmerBaseColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: shimmerBaseColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: shimmerBaseColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 80,
                                    height: 11,
                                    decoration: BoxDecoration(
                                      color: shimmerBaseColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 80,
                              height: 13,
                              decoration: BoxDecoration(
                                color: shimmerBaseColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
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
        Row(
          children: [
            const Icon(Icons.show_chart, size: 20, color: Color(0xFF14894e)),
            const SizedBox(width: 8),
            const Text(
              'Tren Pemasukan & Pengeluaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
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
        Card(
          elevation: 2,
          clipBehavior: Clip.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 250,
              child: _IncomeExpenseLineChart(
                transactions: transactions,
                filter: filter,
                selectedMonth: selectedMonth,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _TotalSpendingCard(
          totalIncome: totalIncome,
          totalExpense: totalExpense,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(Icons.pie_chart, size: 20, color: Color(0xFF14894e)),
            const SizedBox(width: 8),
            const Text(
              'Smart Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 450,
              child: _SmartOverviewPieChart(
                transactions: transactions,
                categories: categories,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(Icons.trending_up, size: 20, color: Color(0xFF14894e)),
            const SizedBox(width: 8),
            const Text(
              'Top Transaksi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
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

  String _calculatePercentage(double value, double total) {
    if (total == 0) return '0.0';
    final percentage = (value / total) * 100;
    return percentage.toStringAsFixed(1);
  }

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pemasukan',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormatter.format(totalIncome),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_calculatePercentage(totalIncome, totalIncome + totalExpense)}%',
                        style: TextStyle(
                          color: Colors.green.shade300,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Pengeluaran',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormatter.format(totalExpense),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_calculatePercentage(totalExpense, totalIncome + totalExpense)}%',
                        style: TextStyle(
                          color: Colors.red.shade300,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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
            curveSmoothness: 0.4,
            color: const Color(0xFF4CAF50),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CAF50).withAlpha(100),
                  const Color(0xFF4CAF50).withAlpha(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
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
            curveSmoothness: 0.4,
            color: const Color(0xFFEF5350),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEF5350).withAlpha(100),
                  const Color(0xFFEF5350).withAlpha(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            tooltipMargin: -40,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (touchedSpot) => Colors.black87,
            getTooltipItems: (touchedSpots) {
              if (touchedSpots.isEmpty) return [];

              // Get the first spot to determine the index
              final spotIndex = touchedSpots[0].spotIndex;
              if (spotIndex >= dataPoints.length) return [];

              final dataPoint = dataPoints[spotIndex];
              final dateStr = DateFormat(
                'd MMM',
                'id_ID',
              ).format(dataPoint.date);
              final currencyFormatter = NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              );

              // Return tooltip items for both lines
              return touchedSpots.map((spot) {
                final isIncome = spot.barIndex == 0;
                return LineTooltipItem(
                  isIncome
                      ? '$dateStr\n🟢 ${currencyFormatter.format(dataPoint.income)}'
                      : '🔴 ${currencyFormatter.format(dataPoint.expense)}',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isIncome ? 13 : 12,
                  ),
                );
              }).toList();
            },
          ),
          touchSpotThreshold: 30,
          getTouchedSpotIndicator:
              (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((spotIndex) {
                  return TouchedSpotIndicatorData(
                    const FlLine(
                      color: Colors.grey,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: barData.color ?? Colors.grey,
                        );
                      },
                    ),
                  );
                }).toList();
              },
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
                if (val != null) {
                  setState(() {
                    _showByIncome = val;
                    _touchedIndex = -1;
                  });
                }
              },
              isDense: true,
              underline: Container(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _CategoryDonutChart(
            transactions: widget.transactions,
            categories: widget.categories,
            isIncome: _showByIncome,
            touchedIndex: _touchedIndex,
            onTouch: (index) => setState(() => _touchedIndex = index),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _CategoryListView(
            transactions: widget.transactions,
            categories: widget.categories,
            isIncome: _showByIncome,
            touchedIndex: _touchedIndex,
            onItemTap: (index) => setState(() {
              _touchedIndex = _touchedIndex == index ? -1 : index;
            }),
          ),
        ),
      ],
    );
  }
}

class _CategoryDonutChart extends StatelessWidget {
  final List<Transaction> transactions;
  final List<Category> categories;
  final bool isIncome;
  final int touchedIndex;
  final Function(int) onTouch;

  const _CategoryDonutChart({
    required this.transactions,
    required this.categories,
    required this.isIncome,
    required this.touchedIndex,
    required this.onTouch,
  });

  // Modern pastel color palette
  static const List<Color> _pastelColors = [
    Color(0xFFFF6B9D), // Pink
    Color(0xFFFFA07A), // Light Salmon
    Color(0xFFFFD93D), // Yellow
    Color(0xFF6BCF7F), // Green
    Color(0xFF4D96FF), // Blue
    Color(0xFFA78BFA), // Purple
    Color(0xFFFF9B9B), // Light Red
    Color(0xFF72DDF7), // Light Blue
    Color(0xFFFFB7C3), // Light Pink
    Color(0xFFFFC898), // Peach
  ];

  List<_CategoryData> _processData() {
    final type = isIncome ? TransactionType.income : TransactionType.expense;
    final filteredTrx = transactions.where((t) => t.type == type).toList();

    if (filteredTrx.isEmpty) return [];

    final categoryMap = {for (var c in categories) c.id: c};
    final grouped = groupBy(filteredTrx, (t) => t.categoryId);

    var data = grouped.entries.map((e) {
      final catId = e.key;
      final amount = e.value.fold(0.0, (sum, t) => sum + t.amount);
      final category = categoryMap[catId];
      return _CategoryData(
        categoryId: catId,
        name: category?.name ?? 'Lainnya',
        amount: amount,
        color: _pastelColors[catId % _pastelColors.length],
        icon: category?.iconName ?? 'help_outline',
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    // Combine categories beyond top 5 into "Lainnya"
    if (data.length > 5) {
      final top5 = data.take(5).toList();
      final others = data.skip(5).toList();
      final othersTotal = others.fold(0.0, (sum, item) => sum + item.amount);

      if (othersTotal > 0) {
        top5.add(
          _CategoryData(
            categoryId: -1,
            name: 'Lainnya',
            amount: othersTotal,
            color: Colors.grey.shade400,
            icon: 'more_horiz',
          ),
        );
      }
      return top5;
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    final data = _processData();

    if (data.isEmpty) {
      return const Center(child: Text('Belum ada data kategori.'));
    }

    final totalAmount = data.fold(0.0, (sum, item) => sum + item.amount);

    return PieChart(
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
        sectionsSpace: 2,
        centerSpaceRadius: 60,
        sections: List.generate(data.length, (i) {
          final isTouched = i == touchedIndex;
          final radius = isTouched ? 50.0 : 42.0;
          final item = data[i];
          final percentage = (item.amount / totalAmount * 100).toStringAsFixed(
            1,
          );

          return PieChartSectionData(
            color: item.color,
            value: item.amount,
            title: isTouched ? '$percentage%' : '',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: isTouched ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: isTouched
                  ? [
                      const Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }
}

class _CategoryListView extends StatelessWidget {
  final List<Transaction> transactions;
  final List<Category> categories;
  final bool isIncome;
  final int touchedIndex;
  final Function(int) onItemTap;

  const _CategoryListView({
    required this.transactions,
    required this.categories,
    required this.isIncome,
    required this.touchedIndex,
    required this.onItemTap,
  });

  List<_CategoryData> _processData() {
    final type = isIncome ? TransactionType.income : TransactionType.expense;
    final filteredTrx = transactions.where((t) => t.type == type).toList();

    if (filteredTrx.isEmpty) return [];

    final categoryMap = {for (var c in categories) c.id: c};
    final grouped = groupBy(filteredTrx, (t) => t.categoryId);

    var data = grouped.entries.map((e) {
      final catId = e.key;
      final amount = e.value.fold(0.0, (sum, t) => sum + t.amount);
      final category = categoryMap[catId];
      return _CategoryData(
        categoryId: catId,
        name: category?.name ?? 'Lainnya',
        amount: amount,
        color: _CategoryDonutChart
            ._pastelColors[catId % _CategoryDonutChart._pastelColors.length],
        icon: category?.iconName ?? 'help_outline',
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    // Combine categories beyond top 5 into "Lainnya"
    if (data.length > 5) {
      final top5 = data.take(5).toList();
      final others = data.skip(5).toList();
      final othersTotal = others.fold(0.0, (sum, item) => sum + item.amount);

      if (othersTotal > 0) {
        top5.add(
          _CategoryData(
            categoryId: -1,
            name: 'Lainnya',
            amount: othersTotal,
            color: Colors.redAccent,
            icon: 'more_horiz',
          ),
        );
      }
      return top5;
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    final data = _processData();

    if (data.isEmpty) {
      return const Center(child: Text('Belum ada data kategori.'));
    }

    final totalAmount = data.fold(0.0, (sum, item) => sum + item.amount);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        final percentage = (item.amount / totalAmount * 100).toStringAsFixed(1);
        final isSelected = index == touchedIndex;

        return InkWell(
          onTap: () => onItemTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: isSelected ? item.color.withAlpha(30) : null,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: item.color.withAlpha(100), width: 2)
                  : Border.all(
                      color: Theme.of(context).dividerColor.withAlpha(50),
                      width: 1,
                    ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: item.color.withAlpha(50),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  IconHelper.getIcon(item.icon),
                  size: 20,
                  color: item.color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$percentage% dari total',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withAlpha(180),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormatter.format(item.amount),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                    color: item.color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryData {
  final int categoryId;
  final String name;
  final double amount;
  final Color color;
  final String icon;

  _CategoryData({
    required this.categoryId,
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
