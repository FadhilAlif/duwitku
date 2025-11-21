import 'package:duwitku/models/category.dart';
import 'package:duwitku/models/transaction.dart' as t;
import 'package:duwitku/providers/category_provider.dart';
import 'package:duwitku/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.transaction?.amount.toString() ?? '');
    _descriptionController =
        TextEditingController(text: widget.transaction?.description ?? '');
    if (widget.transaction != null) {
      final trx = widget.transaction!;
      _selectedDate = trx.transactionDate;
      _transactionType = trx.type;
      // _selectedCategory will be set in the build method once categories are loaded.
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih kategori')),
        );
        return;
      }

      final amount = double.parse(_amountController.text);
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
            description: description,
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
            description: description,
            sourceType: widget.transaction!.sourceType,
            receiptImageUrl: widget.transaction!.receiptImageUrl,
          );
          await repo.updateTransaction(updatedTransaction);
        }

        if (mounted) {
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan transaksi: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.transaction == null ? 'Tambah Transaksi' : 'Ubah Transaksi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Jumlah'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Silakan masukkan jumlah';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Silakan masukkan nomor yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text('Tanggal: ${DateFormat.yMd().format(_selectedDate)}'),
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: const Text('Pilih Tanggal'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (categories) {
                  final filteredCategories = categories
                      .where((cat) => cat.type.name == _transactionType.name)
                      .toList();
                  
                  if (widget.transaction != null && _selectedCategory == null) {
                    try {
                      _selectedCategory = categories.firstWhere((cat) => cat.id == widget.transaction!.categoryId);
                    } catch (e) {
                      _selectedCategory = filteredCategories.isNotEmpty ? filteredCategories.first : null;
                    }
                  }
                  if (_selectedCategory != null && _selectedCategory!.type.name != _transactionType.name) {
                    _selectedCategory = filteredCategories.isNotEmpty ? filteredCategories.first : null;
                  }

                  return DropdownButtonFormField<Category>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: filteredCategories.map((Category category) {
                      return DropdownMenuItem<Category>(
                        value: category,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (Category? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    validator: (value) => value == null ? 'Silakan pilih kategori' : null,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const Text('Tidak dapat memuat kategori'),
              ),
              const SizedBox(height: 16),
              SegmentedButton<t.TransactionType>(
                segments: const [
                  ButtonSegment(value: t.TransactionType.expense, label: Text('Pengeluaran')),
                  ButtonSegment(value: t.TransactionType.income, label: Text('Pemasukan')),
                ],
                selected: {_transactionType},
                onSelectionChanged: (Set<t.TransactionType> newSelection) {
                  setState(() {
                    _transactionType = newSelection.first;
                    _selectedCategory = null; 
                  });
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(widget.transaction == null ? 'Simpan Transaksi' : 'Perbarui Transaksi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}