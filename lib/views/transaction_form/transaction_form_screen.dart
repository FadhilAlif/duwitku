import 'package:duwitku/models/category.dart';
import 'package:duwitku/models/transaction.dart' as t;
import 'package:duwitku/providers/category_provider.dart';
import 'package:duwitku/providers/transaction_provider.dart';
import 'package:duwitku/utils/icon_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final t.Transaction? transaction;
  const TransactionFormScreen({super.key, this.transaction});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  t.TransactionType _transactionType = t.TransactionType.expense;
  bool _showAllCategories = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction?.amount.toStringAsFixed(0) ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.transaction?.description ?? '',
    );

    if (widget.transaction != null) {
      final trx = widget.transaction!;
      _selectedDate = trx.transactionDate;
      _transactionType = trx.type;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Silakan pilih kategori')));
      return;
    }

    final amount =
        double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0.0;
    final description = _descriptionController.text;
    final repo = ref.read(transactionRepositoryProvider);

    try {
      if (widget.transaction == null) {
        final newTransaction = t.Transaction(
          id: const Uuid().v4(),
          userId: '',
          categoryId: _selectedCategory!.id,
          amount: amount,
          transactionDate: _selectedDate,
          type: _transactionType,
          description: description.isNotEmpty ? description : null,
          sourceType: t.SourceType.app,
        );
        await repo.addTransaction(newTransaction);
      } else {
        final updatedTransaction = t.Transaction(
          id: widget.transaction!.id,
          userId: widget.transaction!.userId,
          categoryId: _selectedCategory!.id,
          amount: amount,
          transactionDate: _selectedDate,
          type: _transactionType,
          description: description.isNotEmpty ? description : null,
          sourceType: widget.transaction!.sourceType,
          receiptImageUrl: widget.transaction!.receiptImageUrl,
        );
        await repo.updateTransaction(updatedTransaction);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan transaksi: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _transactionType == t.TransactionType.expense;
    final themeColor = isExpense ? Colors.red : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transaction == null ? 'Tambah Transaksi' : 'Ubah Transaksi',
        ),
        backgroundColor: themeColor.withAlpha(25),
        elevation: 0,
        foregroundColor: themeColor,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _TypeToggle(
              transactionType: _transactionType,
              onChanged: (type) => setState(() {
                _transactionType = type;
                _selectedCategory = null;
              }),
            ),
            _AmountInput(controller: _amountController, color: themeColor),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kategori',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _CategoryGrid(
                      transactionType: _transactionType,
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (category) =>
                          setState(() => _selectedCategory = category),
                      showAll: _showAllCategories,
                      onShowAll: () =>
                          setState(() => _showAllCategories = true),
                      initialTransaction: widget.transaction,
                    ),
                    const SizedBox(height: 24),
                    _DetailsCard(
                      selectedDate: _selectedDate,
                      descriptionController: _descriptionController,
                      onDateChanged: (date) =>
                          setState(() => _selectedDate = date),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.transaction == null ? 'Simpan' : 'Perbarui',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountInput extends StatelessWidget {
  final TextEditingController controller;
  final Color color;

  const _AmountInput({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      color: color.withAlpha(25),
      child: Center(
        child: TextFormField(
          controller: controller,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            CurrencyInputFormatter(
              thousandSeparator: ThousandSeparator.Period,
              mantissaLength: 0,
            ),
          ],
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixText: 'Rp ',
            prefixStyle: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            hintText: '0',
            hintStyle: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: color.withAlpha(128),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty || value == '0') {
              return 'Jumlah tidak boleh nol';
            }
            return null;
          },
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final t.TransactionType transactionType;
  final ValueChanged<t.TransactionType> onChanged;

  const _TypeToggle({required this.transactionType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SegmentedButton<t.TransactionType>(
        segments: const [
          ButtonSegment(
            value: t.TransactionType.expense,
            label: Text('Pengeluaran'),
            icon: Icon(Icons.arrow_upward),
          ),
          ButtonSegment(
            value: t.TransactionType.income,
            label: Text('Pemasukan'),
            icon: Icon(Icons.arrow_downward),
          ),
        ],
        selected: {transactionType},
        onSelectionChanged: (newSelection) => onChanged(newSelection.first),
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor:
              (transactionType == t.TransactionType.expense
                      ? Colors.red
                      : Colors.green)
                  .withAlpha(50),
          selectedForegroundColor: transactionType == t.TransactionType.expense
              ? Colors.red
              : Colors.green,
        ),
      ),
    );
  }
}

class _CategoryGrid extends ConsumerWidget {
  final t.TransactionType transactionType;
  final Category? selectedCategory;
  final ValueChanged<Category> onCategorySelected;
  final bool showAll;
  final VoidCallback onShowAll;
  final t.Transaction? initialTransaction;

  const _CategoryGrid({
    required this.transactionType,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.showAll,
    required this.onShowAll,
    this.initialTransaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return categoriesAsync.when(
      data: (categories) {
        final filteredCategories = categories
            .where((c) => c.type.name == transactionType.name)
            .toList();

        if (initialTransaction != null && selectedCategory == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              final initialCategory = categories.firstWhere(
                (c) => c.id == initialTransaction!.categoryId,
              );
              onCategorySelected(initialCategory);
            } catch (e) {
              // ignore
            }
          });
        }

        final itemsToShow = showAll
            ? filteredCategories
            : filteredCategories.take(5).toList();

        return Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            ...itemsToShow.map((category) {
              return ChoiceChip(
                label: Text(category.name),
                avatar: Icon(IconHelper.getIcon(category.iconName), size: 18),
                selected: selectedCategory?.id == category.id,
                onSelected: (_) => onCategorySelected(category),
              );
            }),
            if (filteredCategories.length > 5 && !showAll)
              ActionChip(
                label: const Text('Lihat Semua'),
                onPressed: onShowAll,
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const Text('Gagal memuat kategori'),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final DateTime selectedDate;
  final TextEditingController descriptionController;
  final ValueChanged<DateTime> onDateChanged;

  const _DetailsCard({
    required this.selectedDate,
    required this.descriptionController,
    required this.onDateChanged,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date == today) return 'Hari Ini';
    if (date == today.subtract(const Duration(days: 1))) return 'Kemarin';
    return DateFormat.yMMMMd('id_ID').format(date);
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Tanggal', style: TextStyle(fontSize: 15)),
            trailing: ActionChip(
              avatar: const Icon(Icons.keyboard_arrow_down),
              label: Text(_formatDate(selectedDate)),
              onPressed: () => _selectDate(context),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          TextFormField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: 'Deskripsi (Opsional)',
              prefixIcon: Icon(Icons.edit_note),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}
