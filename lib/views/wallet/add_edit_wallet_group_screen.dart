import 'package:duwitku/models/wallet.dart';
import 'package:duwitku/models/wallet_group.dart';
import 'package:duwitku/providers/wallet_group_provider.dart';
import 'package:duwitku/providers/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AddEditWalletGroupScreen extends ConsumerStatefulWidget {
  final WalletGroup? group;

  const AddEditWalletGroupScreen({super.key, this.group});

  @override
  ConsumerState<AddEditWalletGroupScreen> createState() =>
      _AddEditWalletGroupScreenState();
}

class _AddEditWalletGroupScreenState
    extends ConsumerState<AddEditWalletGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Set<String> _selectedWalletIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _nameController.text = widget.group!.name;
      _selectedWalletIds.addAll(widget.group!.walletIds);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(walletGroupRepositoryProvider);
      final name = _nameController.text.trim();
      final walletIds = _selectedWalletIds.toList();

      if (widget.group != null) {
        await repository.updateGroup(
          groupId: widget.group!.id,
          name: name,
          walletIds: walletIds,
        );
      } else {
        await repository.addGroup(name: name, walletIds: walletIds);
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.group != null
                  ? 'Grup berhasil diperbarui'
                  : 'Grup berhasil dibuat',
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
    final isEditing = widget.group != null;
    final walletsAsync = ref.watch(walletsStreamProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Grup' : 'Buat Grup Baru',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon header
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.folder_rounded,
                          size: 40,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nama Grup
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Grup',
                        hintText: 'Contoh: Dana Darurat, Tabungan',
                        prefixIcon: const Icon(Icons.label_outline),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withAlpha(80),
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
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama grup tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Pilih Dompet
                    Text(
                      'Pilih Dompet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Centang dompet yang ingin dimasukkan ke grup ini',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Wallet Checkbox List
                    walletsAsync.when(
                      data: (wallets) {
                        final activeWallets = wallets
                            .where((w) => w.isActive)
                            .toList();

                        if (activeWallets.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Belum ada dompet aktif',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: activeWallets
                              .map(
                                (wallet) => _WalletCheckboxTile(
                                  wallet: wallet,
                                  isSelected: _selectedWalletIds.contains(
                                    wallet.id,
                                  ),
                                  onChanged: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedWalletIds.add(wallet.id);
                                      } else {
                                        _selectedWalletIds.remove(wallet.id);
                                      }
                                    });
                                  },
                                ),
                              )
                              .toList(),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Text('Error: $error'),
                    ),
                  ],
                ),
              ),
            ),

            // Save Button at bottom
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _save,
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
                            isEditing ? 'Simpan Perubahan' : 'Buat Grup',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

class _WalletCheckboxTile extends StatelessWidget {
  final Wallet wallet;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  const _WalletCheckboxTile({
    required this.wallet,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: isSelected
          ? colorScheme.primary.withAlpha(15)
          : colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary.withAlpha(100)
              : colorScheme.outlineVariant.withAlpha(60),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onChanged(!isSelected),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getColorForType(wallet.type).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getIconForType(wallet.type),
                  color: _getColorForType(wallet.type),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      wallet.type.displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: isSelected,
                onChanged: (v) => onChanged(v ?? false),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper functions
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
