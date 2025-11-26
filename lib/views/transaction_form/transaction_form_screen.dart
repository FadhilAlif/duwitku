import 'package:duwitku/models/category.dart';
import 'package:duwitku/models/transaction.dart' as t;
import 'package:duwitku/models/wallet.dart';
import 'package:duwitku/providers/category_provider.dart';
import 'package:duwitku/providers/profile_provider.dart';
import 'package:duwitku/providers/transaction_provider.dart';
import 'package:duwitku/providers/wallet_provider.dart';
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
  TimeOfDay _selectedTime = TimeOfDay.now();
  Category? _selectedCategory;
  String? _selectedWalletId;
  t.TransactionType _transactionType = t.TransactionType.expense;
  bool _showAllCategories = false;
  bool _isInitialized = false;

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
      _selectedTime = TimeOfDay.fromDateTime(trx.transactionDate);
      _transactionType = trx.type;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      final walletsAsync = ref.read(walletsStreamProvider);
      final profileAsync = ref.read(profileStreamProvider);

      walletsAsync.whenData((wallets) {
        if (wallets.isNotEmpty && !_isInitialized) {
          String? targetWalletId;

          if (widget.transaction != null) {
            // Editing existing transaction - use its wallet
            final walletExists = wallets.any(
              (w) => w.id == widget.transaction!.walletId,
            );
            if (walletExists) {
              targetWalletId = widget.transaction!.walletId;
            } else {
              // Wallet not found, fallback to default or first
              profileAsync.whenData((profile) {
                if (profile.defaultWalletId != null &&
                    wallets.any((w) => w.id == profile.defaultWalletId)) {
                  targetWalletId = profile.defaultWalletId;
                } else {
                  targetWalletId = wallets.first.id;
                }
              });
              targetWalletId ??= wallets.first.id;
            }
          } else {
            // New transaction - use default wallet
            profileAsync.whenData((profile) {
              if (profile.defaultWalletId != null &&
                  wallets.any((w) => w.id == profile.defaultWalletId)) {
                targetWalletId = profile.defaultWalletId;
              } else {
                targetWalletId = wallets.first.id;
              }
            });
            targetWalletId ??= wallets.first.id;
          }

          if (targetWalletId != null && mounted) {
            setState(() {
              _selectedWalletId = targetWalletId;
              _isInitialized = true;
            });
          }
        }
      });
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
    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Silakan pilih dompet')));
      return;
    }

    final amount =
        double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0.0;
    final description = _descriptionController.text;
    final repo = ref.read(transactionRepositoryProvider);

    try {
      if (widget.transaction == null) {
        // Combine selected date with selected time
        final transactionDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        final newTransaction = t.Transaction(
          id: const Uuid().v4(),
          userId: '',
          categoryId: _selectedCategory!.id,
          amount: amount,
          transactionDate: transactionDateTime,
          type: _transactionType,
          description: description.isNotEmpty ? description : null,
          sourceType: t.SourceType.app,
          walletId: _selectedWalletId!,
        );
        await repo.addTransaction(newTransaction);
      } else {
        // Use selected date and time for update
        final transactionDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        final updatedTransaction = t.Transaction(
          id: widget.transaction!.id,
          userId: widget.transaction!.userId,
          categoryId: _selectedCategory!.id,
          amount: amount,
          transactionDate: transactionDateTime,
          type: _transactionType,
          description: description.isNotEmpty ? description : null,
          sourceType: widget.transaction!.sourceType,
          receiptImageUrl: widget.transaction!.receiptImageUrl,
          walletId: _selectedWalletId!,
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
    final walletsAsync = ref.watch(walletsStreamProvider);

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
                    // Wallet Selector
                    if (walletsAsync.asData?.value.isNotEmpty ?? false) ...[
                      Text(
                        'Dompet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value:
                                _isInitialized &&
                                    _selectedWalletId != null &&
                                    walletsAsync.asData!.value.any(
                                      (w) => w.id == _selectedWalletId,
                                    )
                                ? _selectedWalletId
                                : null,
                            isExpanded: true,
                            hint: const Text('Pilih Dompet'),
                            items: walletsAsync.asData!.value.map((wallet) {
                              return DropdownMenuItem(
                                value: wallet.id,
                                child: Row(
                                  children: [
                                    Icon(
                                      _getWalletIcon(wallet.type),
                                      size: 20,
                                      color: Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(wallet.name),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (walletId) {
                              if (walletId != null) {
                                setState(() => _selectedWalletId = walletId);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
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
                      selectedTime: _selectedTime,
                      descriptionController: _descriptionController,
                      onDateChanged: (date) =>
                          setState(() => _selectedDate = date),
                      onTimeChanged: (time) =>
                          setState(() => _selectedTime = time),
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

  IconData _getWalletIcon(WalletType type) {
    switch (type) {
      case WalletType.bank:
        return Icons.account_balance_rounded;
      case WalletType.cash:
        return Icons.payments_rounded;
      case WalletType.eWallet:
        return Icons.account_balance_wallet_rounded;
      case WalletType.investment:
        return Icons.trending_up_rounded;
      case WalletType.other:
        return Icons.category_rounded;
    }
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

        // Initialize category for edit transaction only once
        if (initialTransaction != null && selectedCategory == null) {
          try {
            final initialCategory = categories.firstWhere(
              (c) => c.id == initialTransaction!.categoryId,
            );
            // Set immediately instead of using callback to prevent flicker
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onCategorySelected(initialCategory);
            });
          } catch (e) {
            // Category not found, ignore
          }
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
  final TimeOfDay selectedTime;
  final TextEditingController descriptionController;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const _DetailsCard({
    required this.selectedDate,
    required this.selectedTime,
    required this.descriptionController,
    required this.onDateChanged,
    required this.onTimeChanged,
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

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedTime) {
      onTimeChanged(picked);
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
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Waktu', style: TextStyle(fontSize: 15)),
            trailing: ActionChip(
              avatar: const Icon(Icons.keyboard_arrow_down),
              label: Text(
                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
              ),
              onPressed: () => _selectTime(context),
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
