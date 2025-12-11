import 'package:duwitku/models/wallet.dart';
import 'package:duwitku/providers/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AddEditWalletScreen extends ConsumerStatefulWidget {
  final Wallet? wallet;

  const AddEditWalletScreen({super.key, this.wallet});

  @override
  ConsumerState<AddEditWalletScreen> createState() =>
      _AddEditWalletScreenState();
}

class _AddEditWalletScreenState extends ConsumerState<AddEditWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  WalletType _selectedType = WalletType.bank;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.wallet != null) {
      _nameController.text = widget.wallet!.name;
      _balanceController.text = widget.wallet!.initialBalance.toStringAsFixed(
        0,
      );
      _selectedType = widget.wallet!.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _saveWallet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(walletRepositoryProvider);
      final name = _nameController.text.trim();
      // Parse currency string (remove non-digits)
      final balanceString = _balanceController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final balance = double.tryParse(balanceString) ?? 0.0;

      if (widget.wallet != null) {
        // Update
        final updatedWallet = Wallet(
          id: widget.wallet!.id,
          userId: widget.wallet!.userId,
          name: name,
          initialBalance: balance,
          type: _selectedType,
          isActive: widget.wallet!.isActive,
          createdAt: widget.wallet!.createdAt,
        );
        await repository.updateWallet(updatedWallet);
      } else {
        // Create
        final newWallet = Wallet(
          id: '',
          userId: '',
          name: name,
          initialBalance: balance,
          type: _selectedType,
          isActive: true,
        );
        await repository.addWallet(newWallet);
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.wallet != null
                  ? 'Dompet berhasil diperbarui'
                  : 'Dompet berhasil ditambahkan',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.wallet != null;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Dompet' : 'Tambah Dompet',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _getColorForType(_selectedType).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconForType(_selectedType),
                    size: 48,
                    color: _getColorForType(_selectedType),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Dompet',
                  hintText: 'Contoh: BCA, Dompet Saku',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withAlpha(80),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama dompet tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<WalletType>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Jenis Dompet',
                  prefixIcon: const Icon(Icons.category_outlined),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withAlpha(80),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                items: WalletType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          _getIconForType(type),
                          size: 20,
                          color: _getColorForType(type),
                        ),
                        const SizedBox(width: 12),
                        Text(type.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  CurrencyInputFormatter(
                    thousandSeparator: ThousandSeparator.Period,
                    mantissaLength: 0,
                  ),
                ],
                decoration: InputDecoration(
                  labelText: 'Saldo Awal',
                  prefixText: 'Rp ',
                  // prefixIcon: const Icon(Icons.monetization_on_outlined),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withAlpha(80),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Saldo awal tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _isLoading ? null : _saveWallet,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Text(
                        isEditing ? 'Simpan Perubahan' : 'Buat Dompet',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(WalletType type) {
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

  Color _getColorForType(WalletType type) {
    switch (type) {
      case WalletType.bank:
        return Colors.blue;
      case WalletType.cash:
        return Colors.green;
      case WalletType.eWallet:
        return Colors.purple;
      case WalletType.investment:
        return Colors.orange;
      case WalletType.other:
        return Colors.grey;
    }
  }
}
