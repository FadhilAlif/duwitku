import 'package:duwitku/models/receipt_item.dart';
import 'package:duwitku/models/transaction.dart';
import 'package:duwitku/providers/category_provider.dart';
import 'package:duwitku/providers/transaction_provider.dart';
import 'package:duwitku/models/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class ReceiptReviewScreen extends ConsumerStatefulWidget {
  final List<ReceiptItem> items;
  final String? imageUrl;

  const ReceiptReviewScreen({
    super.key,
    required this.items,
    this.imageUrl,
  });

  @override
  ConsumerState<ReceiptReviewScreen> createState() =>
      _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends ConsumerState<ReceiptReviewScreen> {
  late List<ReceiptItem> _items;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  void _addItem() {
    setState(() {
      _items.add(ReceiptItem(
        description: '',
        amount: 0,
        type: TransactionType.expense,
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _saveTransactions() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    try {
      final userId = 'placeholder'; // Will be set by repository
      final transactions = _items.map((item) {
        if (item.categoryId == null) {
          throw Exception('Semua item harus memiliki kategori');
        }
        return Transaction(
          id: const Uuid().v4(),
          userId: userId,
          categoryId: item.categoryId!,
          amount: item.amount,
          transactionDate: DateTime.now(),
          type: item.type,
          description: item.description,
          sourceType: SourceType.receiptScan,
          receiptImageUrl: widget.imageUrl,
        );
      }).toList();

      await ref
          .read(transactionRepositoryProvider)
          .addTransactions(transactions);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${transactions.length} transaksi berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/main'); // Navigate to home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Transaksi'),
        actions: [
          if (!_isSaving)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveTransactions,
              tooltip: 'Simpan Semua',
            ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : categoriesAsync.when(
              data: (categories) {
                return Form(
                  key: _formKey,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _items.length + 1, // +1 for "Add Item" button
                    itemBuilder: (context, index) {
                      if (index == _items.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: OutlinedButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Item'),
                          ),
                        );
                      }

                      final item = _items[index];
                      return _ReceiptItemCard(
                        key: ValueKey(item),
                        item: item,
                        categories: categories,
                        onRemove: () => _removeItem(index),
                        onUpdate: (updatedItem) {
                          // Item is updated by reference or we could update state
                          // Since objects are mutable here for simplicity in form
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Item: ${_items.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              FilledButton(
                onPressed: _isSaving ? null : _saveTransactions,
                child: Text(_isSaving ? 'Menyimpan...' : 'Simpan Semua'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptItemCard extends StatefulWidget {
  final ReceiptItem item;
  final List<Category> categories;
  final VoidCallback onRemove;
  final ValueChanged<ReceiptItem> onUpdate;

  const _ReceiptItemCard({
    super.key,
    required this.item,
    required this.categories,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<_ReceiptItemCard> createState() => _ReceiptItemCardState();
}

class _ReceiptItemCardState extends State<_ReceiptItemCard> {
  @override
  void initState() {
    super.initState();
    // Auto-match category if not set
    if (widget.item.categoryId == null) {
      _matchCategory();
    }
  }

  void _matchCategory() {
    // Simple string matching logic
    final description = widget.item.description.toLowerCase();
    for (var category in widget.categories) {
      if (description.contains(category.name.toLowerCase())) {
        setState(() {
          widget.item.categoryId = category.id;
        });
        break;
      }
    }
    
    // Default to 'Lainnya' or similar if available and still null? 
    // For now, leave as null to force user selection if no match.
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: widget.item.description,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                    onSaved: (val) => widget.item.description = val ?? '',
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: widget.item.amount.toStringAsFixed(0),
                    decoration: const InputDecoration(
                      labelText: 'Nominal',
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (val) =>
                        widget.item.amount = double.tryParse(val ?? '0') ?? 0,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Wajib diisi';
                      if (double.tryParse(val) == null) return 'Harus angka';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    key: ValueKey(widget.item.categoryId),
                    initialValue: widget.item.categoryId,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: widget.categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(
                          category.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        widget.item.categoryId = val;
                      });
                    },
                    validator: (val) => val == null ? 'Pilih kategori' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Tipe: '),
                ChoiceChip(
                  label: const Text('Pengeluaran'),
                  selected: widget.item.type == TransactionType.expense,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        widget.item.type = TransactionType.expense;
                      });
                    }
                  },
                  selectedColor: Colors.red.shade100,
                  labelStyle: TextStyle(
                    color: widget.item.type == TransactionType.expense
                        ? Colors.red
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Pemasukan'),
                  selected: widget.item.type == TransactionType.income,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        widget.item.type = TransactionType.income;
                      });
                    }
                  },
                  selectedColor: Colors.green.shade100,
                  labelStyle: TextStyle(
                    color: widget.item.type == TransactionType.income
                        ? Colors.green
                        : null,
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
