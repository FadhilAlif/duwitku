import 'package:duwitku/models/wallet.dart';
import 'package:duwitku/providers/wallet_provider.dart';
import 'package:flutter/material.dart';
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
      _balanceController.text =
          widget.wallet!.initialBalance.toStringAsFixed(0);
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
      final balance = double.tryParse(_balanceController.text) ?? 0.0;

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
        // ID and UserID will be handled by DB/Repo
        final newWallet = Wallet(
          id: '', // Placeholder, ignored by insert logic usually
          userId: '', // Placeholder, filled by repo
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
    final isEditing = widget.wallet != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Dompet' : 'Tambah Dompet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Dompet',
                  hintText: 'Contoh: BCA, Dompet Saku',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama dompet tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<WalletType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Jenis Dompet',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: WalletType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                decoration: const InputDecoration(
                  labelText: 'Saldo Awal',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Saldo awal tidak boleh kosong';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Format angka tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _saveWallet,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isEditing ? 'Simpan Perubahan' : 'Buat Dompet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
