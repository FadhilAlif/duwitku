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

// Main Screen Widget
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggaran', style: TextStyle(fontWeight: FontWeight.bold)),
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
        onPressed: () => _showBudgetModal(context),
        label: const Text('Buat Budget Baru'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

// Month Selector Widget
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
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: notifier.previousMonth),
          Text(
            DateFormat.yMMMM('id_ID').format(selectedMonth),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: notifier.nextMonth),
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

    return budgetsAsync.when(
      data: (budgets) => transactionsAsync.when(
        data: (transactions) => categoriesAsync.when(
          data: (categories) => budgets.isEmpty
              ? const _EmptyState()
              : _BudgetList(budgets: budgets, transactions: transactions, categories: categories),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Error memuat kategori: $e'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error memuat transaksi: $e'),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error memuat budget: $e'),
    );
  }
}

// List of Budgets Widget
class _BudgetList extends StatelessWidget {
  final List<Budget> budgets;
  final List<t.Transaction> transactions;
  final List<Category> categories;

  const _BudgetList({required this.budgets, required this.transactions, required this.categories});

  @override
  Widget build(BuildContext context) {
    final categoryMap = {for (var c in categories) c.id: c};
    budgets.sort((a, b) => b.id.compareTo(a.id));

    double totalLimit = budgets.fold(0.0, (sum, b) => sum + b.amountLimit);
    double totalSpent = 0;
    for (var budget in budgets) {
      totalSpent += transactions
          .where((trx) => trx.categoryId == budget.categoryId && trx.type == t.TransactionType.expense)
          .fold(0.0, (sum, trx) => sum + trx.amount);
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
                .where((trx) => trx.categoryId == budget.categoryId && trx.type == t.TransactionType.expense)
                .fold(0.0, (sum, trx) => sum + trx.amount);

            return _BudgetCard(budget: budget, category: category, spent: spent);
          },
        ),
      ],
    );
  }
}

// Overall Gauge Widget
class _OverallBudgetGauge extends StatelessWidget {
  final double totalLimit;
  final double totalSpent;
  const _OverallBudgetGauge({required this.totalLimit, required this.totalSpent});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final percentage = totalLimit > 0 ? (totalSpent / totalLimit) : 0.0;
    final remaining = totalLimit - totalSpent;
    final statusText = percentage < 0.8 ? 'Aman' : (percentage <= 1.0 ? 'Waspada' : 'Overbudget!');

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
                valueColor: AlwaysStoppedAnimation<Color>(_getBarColor(percentage)),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(percentage * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(statusText, style: Theme.of(context).textTheme.bodyMedium),
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
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 16, left: 16, right: 16),
        child: _BudgetForm(budget: budget),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final percentage = budget.amountLimit > 0 ? (spent / budget.amountLimit) : 0.0;
    return GestureDetector(
      onTap: () => _showBudgetModal(context, budget),
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
                  Icon(IconHelper.getIcon(category?.iconName), color: Colors.grey.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(category?.name ?? 'Tanpa Kategori', style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const Spacer(),
              Text.rich(
                TextSpan(
                  text: 'Terpakai ${currencyFormatter.format(spent)}',
                  style: const TextStyle(fontSize: 12),
                  children: [TextSpan(text: ' dari ${currencyFormatter.format(budget.amountLimit)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))],
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: percentage.clamp(0, 1),
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(_getBarColor(percentage)),
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

// Utility function for color
Color _getBarColor(double percentage) {
  if (percentage < 0.5) return Colors.green;
  if (percentage < 0.8) return Colors.orange;
  if (percentage <= 1.0) return Colors.red;
  return Colors.black87;
}

// Empty State Widget
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Belum ada budget yang dibuat untuk bulan ini.'),
        ],
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
    _amountController = TextEditingController(text: _isEditMode ? widget.budget!.amountLimit.toStringAsFixed(0) : '');
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
    final amount = double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0.0;
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
          messenger.showSnackBar(const SnackBar(content: Text('Pilih kategori terlebih dahulu.')));
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
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan budget: ${e.toString()}')));
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
          TextButton(onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(budgetRepositoryProvider);
      try {
        await repo.deleteBudget(widget.budget!.id);
        navigator.pop(); // Close bottom sheet
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Gagal menghapus budget: ${e.toString()}')));
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
              Text(_isEditMode ? 'Ubah Budget' : 'Budget Baru', style: Theme.of(context).textTheme.titleLarge),
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
                                _selectedCategory = categories.firstWhere((c) => c.id == widget.budget!.categoryId);
                              });
                            });
                          }
                          
                          final budgetedCategoryIds = budgets.map((b) => b.categoryId).toList();
                          final availableCategories = categories.where((c) {
                            if (_isEditMode && c.id == widget.budget!.categoryId) return true;
                            return !budgetedCategoryIds.contains(c.id) && c.type == CategoryType.expense;
                          }).toList();
                          
                          return DropdownButtonFormField<Category>(
                            initialValue: _selectedCategory,
                            hint: const Text('Pilih Kategori'),
                            isExpanded: true,
                            items: availableCategories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                            onChanged: _isEditMode ? null : (cat) => setState(() => _selectedCategory = cat),
                            validator: (v) => v == null ? 'Kategori wajib diisi' : null,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => const Text('Gagal memuat budget.'),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => const Text('Gagal memuat kategori.'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter(thousandSeparator: ThousandSeparator.Period, mantissaLength: 0)],
                      decoration: const InputDecoration(labelText: 'Jumlah Limit', prefixText: 'Rp ', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty || v == '0') ? 'Jumlah tidak boleh nol' : null,
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
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
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