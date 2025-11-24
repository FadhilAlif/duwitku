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

  const ReceiptReviewScreen({super.key, required this.items, this.imageUrl});

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

  double get _totalAmount {
    return _items.fold(0, (sum, item) => sum + item.amount);
  }

  void _addItem() {
    setState(() {
      _items.add(
        ReceiptItem(description: '', amount: 0, type: TransactionType.expense),
      );
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Transaksi'),
        elevation: 0,
        actions: [
          if (!_isSaving)
            IconButton(
              icon: const Icon(Icons.check_circle),
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
                  child: Column(
                    children: [
                      // Total Amount Summary Card
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primaryContainer,
                              theme.colorScheme.secondaryContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  color: theme.colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Total Transaksi',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Rp ${_totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_items.length} item',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onPrimaryContainer
                                                  .withValues(alpha: 0.7),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.qr_code_scanner,
                                        size: 16,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Scan Struk',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
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
                      // Items List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount:
                              _items.length + 1, // +1 for "Add Item" button
                          itemBuilder: (context, index) {
                            if (index == _items.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: OutlinedButton.icon(
                                  onPressed: _addItem,
                                  icon: const Icon(Icons.add_circle_outline),
                                  label: const Text('Tambah Item Baru'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                    side: BorderSide(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.5),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              );
                            }

                            final item = _items[index];
                            return _ReceiptItemCard(
                              key: ValueKey(item),
                              item: item,
                              index: index,
                              categories: categories,
                              onRemove: () => _removeItem(index),
                              onUpdate: (updatedItem) {
                                setState(() {
                                  // Trigger rebuild to update total amount
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _saveTransactions,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(
              _isSaving
                  ? 'Menyimpan...'
                  : 'Simpan ${_items.length} Transaksi (Rp ${_totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')})',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptItemCard extends StatefulWidget {
  final ReceiptItem item;
  final int index;
  final List<Category> categories;
  final VoidCallback onRemove;
  final ValueChanged<ReceiptItem> onUpdate;

  const _ReceiptItemCard({
    super.key,
    required this.item,
    required this.index,
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
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.index + 1}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: widget.item.description,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi Item',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (val) {
                      widget.item.description = val;
                      widget.onUpdate(widget.item);
                    },
                    onSaved: (val) => widget.item.description = val ?? '',
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: theme.colorScheme.error,
                  onPressed: widget.onRemove,
                  tooltip: 'Hapus',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: widget.item.amount.toStringAsFixed(0),
              decoration: InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                widget.item.amount = double.tryParse(val) ?? 0;
                widget.onUpdate(widget.item);
              },
              onSaved: (val) =>
                  widget.item.amount = double.tryParse(val ?? '0') ?? 0,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Wajib diisi';
                if (double.tryParse(val) == null) return 'Harus angka';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: ValueKey(widget.item.categoryId),
              initialValue: widget.item.categoryId,
              decoration: InputDecoration(
                labelText: 'Kategori',
                prefixIcon: Icon(
                  Icons.category,
                  color: theme.colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              items: widget.categories.map((category) {
                return DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  widget.item.categoryId = val;
                });
                widget.onUpdate(widget.item);
              },
              validator: (val) => val == null ? 'Pilih kategori' : null,
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipe Transaksi',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              size: 14,
                              color: widget.item.type == TransactionType.expense
                                  ? Colors.red.shade700
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            const Flexible(
                              child: Text(
                                'Keluar',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        selected: widget.item.type == TransactionType.expense,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              widget.item.type = TransactionType.expense;
                            });
                            widget.onUpdate(widget.item);
                          }
                        },
                        selectedColor: Colors.red.shade100,
                        backgroundColor: theme.colorScheme.surface,
                        labelStyle: TextStyle(
                          color: widget.item.type == TransactionType.expense
                              ? Colors.red.shade700
                              : theme.colorScheme.onSurface,
                          fontWeight:
                              widget.item.type == TransactionType.expense
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              size: 14,
                              color: widget.item.type == TransactionType.income
                                  ? Colors.green.shade700
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            const Flexible(
                              child: Text(
                                'Masuk',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        selected: widget.item.type == TransactionType.income,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              widget.item.type = TransactionType.income;
                            });
                            widget.onUpdate(widget.item);
                          }
                        },
                        selectedColor: Colors.green.shade100,
                        backgroundColor: theme.colorScheme.surface,
                        labelStyle: TextStyle(
                          color: widget.item.type == TransactionType.income
                              ? Colors.green.shade700
                              : theme.colorScheme.onSurface,
                          fontWeight: widget.item.type == TransactionType.income
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
