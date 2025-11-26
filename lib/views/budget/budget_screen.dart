import 'package:duwitku/models/budget.dart';
import 'package:duwitku/models/category.dart';
import 'package:duwitku/models/transaction.dart' as t;
import 'package:duwitku/providers/budget_provider.dart';
import 'package:duwitku/providers/category_provider.dart';
import 'package:duwitku/providers/transaction_provider.dart';
import 'package:duwitku/utils/icon_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

// Main Screen Widget
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          const _MonthSelector(),
          Expanded(child: _BudgetBody()),
        ],
      ),
    );
  }
}

// ... _MonthSelector remains unchanged ...
class _MonthSelector extends ConsumerWidget {
  const _MonthSelector();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(budgetMonthProvider);
    final notifier = ref.read(budgetMonthProvider.notifier);

    // Calculate days remaining in selected month
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    );
    final daysRemaining = lastDayOfMonth.difference(now).inDays;
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
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
          ),
          if (isCurrentMonth && daysRemaining >= 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: daysRemaining <= 5
                    ? Colors.red.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: daysRemaining <= 5
                      ? Colors.red.shade200
                      : Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    daysRemaining <= 5
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline,
                    size: 16,
                    color: daysRemaining <= 5
                        ? Colors.red.shade700
                        : Colors.blue.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    daysRemaining == 0
                        ? 'Hari terakhir bulan ini!'
                        : 'Sisa $daysRemaining hari lagi di bulan ini',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: daysRemaining <= 5
                          ? Colors.red.shade700
                          : Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Body Widget (handles async states)
class _BudgetBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsStreamProvider);
    final transactionsAsync = ref.watch(filteredTransactionsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    final isLoading =
        budgetsAsync.isLoading ||
        transactionsAsync.isLoading ||
        categoriesAsync.isLoading;

    final budgets = isLoading
        ? List.generate(
            3,
            (index) => Budget(
              id: index,
              userId: 'dummy',
              categoryId: 0,
              amountLimit: 1000000,
              startDate: DateTime.now(),
              endDate: DateTime.now(),
            ),
          )
        : budgetsAsync.asData?.value ?? [];

    final transactions = isLoading
        ? <t.Transaction>[]
        : transactionsAsync.asData?.value ?? [];

    final categories = isLoading
        ? [
            Category(
              id: 0,
              name: 'Loading Category',
              type: CategoryType.expense,
              iconName: 'help_outline',
            ),
          ]
        : categoriesAsync.asData?.value ?? [];

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(budgetsStreamProvider);
        ref.invalidate(filteredTransactionsStreamProvider);
        ref.invalidate(categoriesStreamProvider);
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: Skeletonizer(
        enabled: isLoading,
        child: budgets.isEmpty && !isLoading
            ? const _EmptyState()
            : _BudgetList(
                budgets: budgets,
                transactions: transactions,
                categories: categories,
              ),
      ),
    );
  }
}

// List of Budgets Widget
class _BudgetList extends StatelessWidget {
  final List<Budget> budgets;
  final List<t.Transaction> transactions;
  final List<Category> categories;

  const _BudgetList({
    required this.budgets,
    required this.transactions,
    required this.categories,
  });

  void _showBudgetModal(BuildContext context, [Budget? budget]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: _BudgetForm(budget: budget),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryMap = {for (var c in categories) c.id: c};
    budgets.sort((a, b) => b.id.compareTo(a.id));

    double totalLimit = budgets.fold(0.0, (sum, b) => sum + b.amountLimit);
    double totalSpent = 0;
    for (var budget in budgets) {
      totalSpent += transactions
          .where(
            (trx) =>
                trx.categoryId == budget.categoryId &&
                trx.type == t.TransactionType.expense,
          )
          .fold(0.0, (sum, trx) => sum + trx.amount);
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
          child: _OverallBudgetGauge(
            totalLimit: totalLimit,
            totalSpent: totalSpent,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 8),
              ...budgets.map((budget) {
                final category = categoryMap[budget.categoryId];
                final spent = transactions
                    .where(
                      (trx) =>
                          trx.categoryId == budget.categoryId &&
                          trx.type == t.TransactionType.expense,
                    )
                    .fold(0.0, (sum, trx) => sum + trx.amount);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BudgetCard(
                    budget: budget,
                    category: category,
                    spent: spent,
                  ),
                );
              }),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: () => _showBudgetModal(context),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Buat Budget Baru'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }
}

// Overall Gauge Widget
class _OverallBudgetGauge extends StatelessWidget {
  final double totalLimit;
  final double totalSpent;
  const _OverallBudgetGauge({
    required this.totalLimit,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final percentage = totalLimit > 0 ? (totalSpent / totalLimit) : 0.0;
    final remaining = totalLimit - totalSpent;
    final statusText = percentage < 0.8
        ? 'Aman'
        : (percentage <= 1.0 ? 'Waspada' : 'Overbudget!');
    final statusColor = percentage < 0.8
        ? const Color.fromARGB(255, 81, 255, 0)
        : (percentage <= 1.0 ? Colors.amber : Colors.red);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Anggaran Bulan Ini',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormatter.format(totalLimit),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(51),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              percentage < 0.8
                                  ? Icons.check_circle
                                  : (percentage <= 1.0
                                        ? Icons.warning
                                        : Icons.error),
                              size: 16,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Terpakai: ${currencyFormatter.format(totalSpent)}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    'Sisa: ${currencyFormatter.format(remaining)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: percentage.clamp(0, 1),
                    strokeWidth: 10,
                    backgroundColor: Colors.white.withAlpha(77),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(percentage * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Budget Card Widget
class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final Category? category;
  final double spent;
  const _BudgetCard({required this.budget, this.category, required this.spent});

  void _showBudgetModal(BuildContext context, [Budget? budget]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: _BudgetForm(budget: budget),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final percentage = budget.amountLimit > 0
        ? (spent / budget.amountLimit)
        : 0.0;
    final remaining = budget.amountLimit - spent;
    final barColor = _getBarColor(percentage);

    return GestureDetector(
      onTap: () => _showBudgetModal(context, budget),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: barColor.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      IconHelper.getIcon(category?.iconName),
                      color: barColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category?.name ?? 'Tanpa Kategori',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(percentage * 100).toStringAsFixed(0)}% terpakai',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: percentage.clamp(0, 1),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Terpakai',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currencyFormatter.format(spent),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: barColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Sisa', style: TextStyle(fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        currencyFormatter.format(remaining),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Limit: ${currencyFormatter.format(budget.amountLimit)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Utility function for color
Color _getBarColor(double percentage) {
  if (percentage < 0.5) return const Color.fromARGB(255, 81, 255, 0);
  if (percentage < 0.8) return Colors.amber;
  if (percentage <= 1.0) return Colors.red;
  return Colors.red.shade900;
}

// Empty State Widget
class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  void _showBudgetModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: const _BudgetForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 80,
                    color: Colors.blue.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Belum Ada Budget',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Buat budget pertama Anda untuk mengelola pengeluaran dengan lebih baik',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _showBudgetModal(context),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Buat Budget Baru'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// The Form widget for Add/Edit
class _BudgetForm extends ConsumerStatefulWidget {
  final Budget? budget;
  const _BudgetForm({this.budget});

  @override
  ConsumerState<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<_BudgetForm> {
  final _formKey = GlobalKey<FormState>();
  Category? _selectedCategory;
  late TextEditingController _amountController;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.budget != null;
    if (_isEditMode) {
      // Deferring this to build method where categories are available
    }
    _amountController = TextEditingController(
      text: _isEditMode ? widget.budget!.amountLimit.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final amount =
        double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0.0;
    final repo = ref.read(budgetRepositoryProvider);
    final selectedMonth = ref.read(budgetMonthProvider);

    try {
      if (_isEditMode) {
        final updatedBudget = Budget(
          id: widget.budget!.id,
          userId: widget.budget!.userId,
          categoryId: _selectedCategory!.id,
          amountLimit: amount,
          startDate: widget.budget!.startDate,
          endDate: widget.budget!.endDate,
        );
        await repo.updateBudget(updatedBudget);
      } else {
        if (_selectedCategory == null) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Pilih kategori terlebih dahulu.')),
          );
          return;
        }
        final newBudget = Budget(
          id: 0,
          userId: '',
          categoryId: _selectedCategory!.id,
          amountLimit: amount,
          startDate: DateTime(selectedMonth.year, selectedMonth.month, 1),
          endDate: DateTime(selectedMonth.year, selectedMonth.month + 1, 0),
        );
        await repo.createBudget(newBudget);
      }
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menyimpan budget: ${e.toString()}')),
      );
    }
  }

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Budget'),
        content: const Text('Apakah Anda yakin ingin menghapus budget ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(budgetRepositoryProvider);
      try {
        await repo.deleteBudget(widget.budget!.id);
        navigator.pop(); // Close bottom sheet
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Gagal menghapus budget: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final budgetsAsync = ref.watch(budgetsStreamProvider);

    return Wrap(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEditMode ? 'Ubah Budget' : 'Budget Baru',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    categoriesAsync.when(
                      data: (categories) => budgetsAsync.when(
                        data: (budgets) {
                          // In edit mode, pre-select the category
                          if (_isEditMode && _selectedCategory == null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                _selectedCategory = categories.firstWhere(
                                  (c) => c.id == widget.budget!.categoryId,
                                );
                              });
                            });
                          }

                          final budgetedCategoryIds = budgets
                              .map((b) => b.categoryId)
                              .toList();
                          final availableCategories = categories.where((c) {
                            if (_isEditMode &&
                                c.id == widget.budget!.categoryId) {
                              return true;
                            }
                            return !budgetedCategoryIds.contains(c.id) &&
                                c.type == CategoryType.expense;
                          }).toList();

                          return DropdownButtonFormField<Category>(
                            initialValue: _selectedCategory,
                            hint: const Text('Pilih Kategori'),
                            isExpanded: true,
                            items: availableCategories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                            onChanged: _isEditMode
                                ? null
                                : (cat) =>
                                      setState(() => _selectedCategory = cat),
                            validator: (v) =>
                                v == null ? 'Kategori wajib diisi' : null,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, s) => const Text('Gagal memuat budget.'),
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) => const Text('Gagal memuat kategori.'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        CurrencyInputFormatter(
                          thousandSeparator: ThousandSeparator.Period,
                          mantissaLength: 0,
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Limit',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.isEmpty || v == '0')
                          ? 'Jumlah tidak boleh nol'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (_isEditMode)
                    TextButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _submit, child: const Text('Simpan')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
