import 'package:duwitku/models/budget.dart';
import 'package:duwitku/models/category.dart';
import 'package:duwitku/models/transaction.dart' as t;
import 'package:duwitku/providers/budget_provider.dart';
import 'package:duwitku/providers/category_provider.dart';
import 'package:duwitku/providers/transaction_provider.dart';
import 'package:duwitku/utils/icon_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  void _showBudgetDialog(
    BuildContext context,
    WidgetRef ref, [
    Budget? budget,
  ]) {
    showDialog(
      context: context,
      builder: (context) => _BudgetDialog(budget: budget),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Anggaran',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          const _MonthSelector(),
          Expanded(child: _BudgetBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBudgetDialog(context, ref),
        label: const Text('Budget'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _MonthSelector extends ConsumerWidget {
  const _MonthSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(budgetMonthProvider);
    final notifier = ref.read(budgetMonthProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
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
    );
  }
}

class _BudgetBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsStreamProvider);
    final transactionsAsync = ref.watch(filteredTransactionsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return budgetsAsync.when(
      data: (budgets) => transactionsAsync.when(
        data: (transactions) => categoriesAsync.when(
          data: (categories) {
            if (budgets.isEmpty) {
              return const _EmptyState();
            }
            return _BudgetList(
              budgets: budgets,
              transactions: transactions,
              categories: categories,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Error loading categories: $e'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error loading transactions: $e'),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error loading budgets: $e'),
    );
  }
}

class _BudgetList extends StatelessWidget {
  final List<Budget> budgets;
  final List<t.Transaction> transactions;
  final List<Category> categories;

  const _BudgetList({
    required this.budgets,
    required this.transactions,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final categoryMap = {for (var c in categories) c.id: c};

    double totalLimit = budgets.fold(0.0, (sum, b) => sum + b.amountLimit);
    double totalSpent = 0;

    for (var budget in budgets) {
      final spent = transactions
          .where(
            (trx) =>
                trx.categoryId == budget.categoryId &&
                trx.type == t.TransactionType.expense,
          )
          .fold(0.0, (sum, trx) => sum + trx.amount);
      totalSpent += spent;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _OverallBudgetGauge(totalLimit: totalLimit, totalSpent: totalSpent),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemCount: budgets.length,
          itemBuilder: (context, index) {
            final budget = budgets[index];
            final category = categoryMap[budget.categoryId];
            final spent = transactions
                .where(
                  (trx) =>
                      trx.categoryId == budget.categoryId &&
                      trx.type == t.TransactionType.expense,
                )
                .fold(0.0, (sum, trx) => sum + trx.amount);

            return _BudgetCard(
              budget: budget,
              category: category,
              spent: spent,
            );
          },
        ),
      ],
    );
  }
}

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

    String statusText;
    if (percentage < 0.8) {
      statusText = 'Aman';
    } else if (percentage <= 1.0) {
      statusText = 'Waspada';
    } else {
      statusText = 'Overbudget!';
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          width: 180,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: percentage.clamp(0, 1),
                strokeWidth: 12,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getBarColor(percentage),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(percentage * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Sisa Budget: ${currencyFormatter.format(remaining)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  final Budget budget;
  final Category? category;
  final double spent;

  const _BudgetCard({required this.budget, this.category, required this.spent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final percentage = budget.amountLimit > 0
        ? (spent / budget.amountLimit)
        : 0.0;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => _BudgetDialog(budget: budget),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    IconHelper.getIcon(category?.iconName),
                    color: Colors.grey.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category?.name ?? 'Tanpa Kategori',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text.rich(
                TextSpan(
                  text: 'Terpakai ${currencyFormatter.format(spent)}',
                  style: const TextStyle(fontSize: 12),
                  children: [
                    TextSpan(
                      text:
                          ' dari ${currencyFormatter.format(budget.amountLimit)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: percentage.clamp(0, 1),
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getBarColor(percentage),
                ),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _getBarColor(double percentage) {
  if (percentage < 0.5) return Colors.green;
  if (percentage < 0.8) return Colors.orange;
  if (percentage <= 1.0) return Colors.red;
  return Colors.black87;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text('Belum ada budget yang dibuat untuk bulan ini.'),
        ],
      ),
    );
  }
}

class _BudgetDialog extends ConsumerStatefulWidget {
  final Budget? budget;

  const _BudgetDialog({this.budget});

  @override
  ConsumerState<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends ConsumerState<_BudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedCategoryId;
  late TextEditingController _amountController;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.budget != null;
    _selectedCategoryId = widget.budget?.categoryId;
    _amountController = TextEditingController(
      text: _isEditMode ? widget.budget!.amountLimit.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() async {
    FocusScope.of(context).unfocus(); // Dismiss the keyboard first
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih kategori terlebih dahulu.')),
        );
        return;
      }

      final amount =
          double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0.0;
      final repo = ref.read(budgetRepositoryProvider);
      final selectedMonth = ref.read(budgetMonthProvider);
      final startDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
      final endDate = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

      try {
        if (_isEditMode) {
          final updatedBudget = Budget(
            id: widget.budget!.id,
            userId: widget.budget!.userId,
            categoryId: _selectedCategoryId!,
            amountLimit: amount,
            startDate: widget.budget!.startDate,
            endDate: widget.budget!.endDate,
          );
          await repo.updateBudget(updatedBudget);
        } else {
          final newBudget = Budget(
            id: 0, // Will be generated by Supabase
            userId: '', // Will be set by repository
            categoryId: _selectedCategoryId!,
            amountLimit: amount,
            startDate: startDate,
            endDate: endDate,
          );
          await repo.createBudget(newBudget);
        }
        await Future.delayed(
          const Duration(milliseconds: 100),
        ); // Allow keyboard to hide
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan budget: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final budgetsAsync = ref.watch(budgetsStreamProvider);

    return AlertDialog(
      title: Text(_isEditMode ? 'Ubah Budget' : 'Budget Baru'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            categoriesAsync.when(
              data: (categories) => budgetsAsync.when(
                data: (budgets) {
                  final budgetedCategoryIds = budgets
                      .map((b) => b.categoryId)
                      .toList();
                  final availableCategories = categories.where((c) {
                    // Always include the currently selected category to prevent dropdown errors
                    if (_selectedCategoryId != null &&
                        c.id == _selectedCategoryId) {
                      return true;
                    }
                    // In edit mode, include the current budget's category
                    if (_isEditMode && c.id == widget.budget!.categoryId) {
                      return true;
                    }
                    // In add mode, only show categories without a budget for the current month
                    return !budgetedCategoryIds.contains(c.id) &&
                        c.type == CategoryType.expense;
                  }).toList();

                  // Ensure selected category exists in available categories
                  final validSelectedId =
                      _selectedCategoryId != null &&
                          availableCategories.any(
                            (c) => c.id == _selectedCategoryId,
                          )
                      ? _selectedCategoryId
                      : null;

                  return DropdownButtonFormField<int>(
                    value: validSelectedId,
                    hint: const Text('Pilih Kategori'),
                    isExpanded: true,
                    items: availableCategories.map((Category category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Row(
                          children: [
                            Icon(
                              IconHelper.getIcon(category.iconName),
                              size: 20,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: _isEditMode
                        ? null
                        : (int? newValue) {
                            setState(() {
                              _selectedCategoryId = newValue;
                            });
                          },
                    validator: (value) =>
                        value == null ? 'Kategori wajib diisi' : null,
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => const Text('Gagal memuat budget.'),
              ),
              loading: () => const CircularProgressIndicator(),
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
              ),
              validator: (value) {
                if (value == null || value.isEmpty || value == '0') {
                  return 'Jumlah tidak boleh nol';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
