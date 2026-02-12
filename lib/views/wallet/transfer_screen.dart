import 'package:duwitku/models/wallet.dart';
import 'package:duwitku/providers/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TransferScreen extends ConsumerStatefulWidget {
  final Wallet? sourceWallet;

  const TransferScreen({super.key, this.sourceWallet});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  Wallet? _fromWallet;
  Wallet? _toWallet;
  bool _isLoading = false;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fromWallet = widget.sourceWallet;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _executeTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fromWallet == null || _toWallet == null) {
      _showError('Pilih dompet asal dan tujuan');
      return;
    }

    if (_fromWallet!.id == _toWallet!.id) {
      _showError('Dompet asal dan tujuan tidak boleh sama');
      return;
    }

    final amountString = _amountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final amount = double.tryParse(amountString) ?? 0.0;

    if (amount <= 0) {
      _showError('Nominal transfer harus lebih dari 0');
      return;
    }

    if (amount > _fromWallet!.initialBalance) {
      _showError(
        'Saldo tidak mencukupi. '
        'Saldo saat ini: ${_currencyFormat.format(_fromWallet!.initialBalance)}',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(walletRepositoryProvider);
      await repository.transferFunds(
        fromWalletId: _fromWallet!.id,
        toWalletId: _toWallet!.id,
        amount: amount,
      );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Berhasil transfer ${_currencyFormat.format(amount)} '
              'dari ${_fromWallet!.name} ke ${_toWallet!.name}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Gagal transfer: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final walletsAsync = ref.watch(walletsStreamProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Transfer Dana',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: walletsAsync.when(
        data: (wallets) {
          final activeWallets = wallets.where((w) => w.isActive).toList();

          if (activeWallets.length < 2) {
            return _InsufficientWalletsState();
          }

          // Sync _fromWallet dan _toWallet dengan data terbaru dari stream
          if (_fromWallet != null) {
            final updatedFrom = activeWallets
                .where((w) => w.id == _fromWallet!.id)
                .firstOrNull;
            if (updatedFrom != null) _fromWallet = updatedFrom;
          }

          if (_toWallet != null) {
            final updatedTo = activeWallets
                .where((w) => w.id == _toWallet!.id)
                .firstOrNull;
            if (updatedTo != null) _toWallet = updatedTo;
          }

          // Filter wallet tujuan: keluarkan wallet asal
          final destinationWallets = activeWallets
              .where((w) => w.id != _fromWallet?.id)
              .toList();

          return Form(
            key: _formKey,
            child: Column(
              children: [
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Transfer illustration
                        _TransferIllustration(
                          fromWallet: _fromWallet,
                          toWallet: _toWallet,
                        ),
                        const SizedBox(height: 32),

                        // Dompet Asal
                        _WalletDropdown(
                          label: 'Dari Dompet',
                          icon: Icons.output_rounded,
                          wallets: activeWallets,
                          selectedWallet: _fromWallet,
                          currencyFormat: _currencyFormat,
                          onChanged: (wallet) {
                            setState(() {
                              _fromWallet = wallet;
                              // Reset tujuan jika sama
                              if (_toWallet?.id == wallet?.id) {
                                _toWallet = null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // Swap button
                        Center(
                          child: IconButton.filled(
                            onPressed:
                                (_fromWallet != null && _toWallet != null)
                                ? () {
                                    setState(() {
                                      final temp = _fromWallet;
                                      _fromWallet = _toWallet;
                                      _toWallet = temp;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.swap_vert_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme.primaryContainer
                                  .withAlpha(180),
                              foregroundColor: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Dompet Tujuan
                        _WalletDropdown(
                          label: 'Ke Dompet',
                          icon: Icons.input_rounded,
                          wallets: destinationWallets,
                          selectedWallet: _toWallet,
                          currencyFormat: _currencyFormat,
                          onChanged: (wallet) {
                            setState(() => _toWallet = wallet);
                          },
                        ),
                        const SizedBox(height: 32),

                        // Nominal Transfer
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            CurrencyInputFormatter(
                              thousandSeparator: ThousandSeparator.Period,
                              mantissaLength: 0,
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Nominal Transfer',
                            prefixText: 'Rp ',
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
                            helperText: _fromWallet != null
                                ? 'Saldo tersedia: ${_currencyFormat.format(_fromWallet!.initialBalance)}'
                                : null,
                            helperStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nominal tidak boleh kosong';
                            }
                            final parsed = double.tryParse(
                              value.replaceAll(RegExp(r'[^0-9]'), ''),
                            );
                            if (parsed == null || parsed <= 0) {
                              return 'Nominal harus lebih dari 0';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Fixed Transfer Button at bottom
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
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _executeTransfer,
                        icon: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _isLoading ? 'Memproses...' : 'Transfer Sekarang',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Terjadi kesalahan: $error')),
      ),
    );
  }
}

// ============================================================================
// Private Widgets
// ============================================================================

/// Ilustrasi visual transfer: ikon dompet asal → panah → ikon dompet tujuan.
class _TransferIllustration extends StatelessWidget {
  final Wallet? fromWallet;
  final Wallet? toWallet;

  const _TransferIllustration({this.fromWallet, this.toWallet});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(60),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _WalletIcon(wallet: fromWallet, label: 'Asal'),
          Column(
            children: [
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white.withAlpha(200),
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                'Transfer',
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          _WalletIcon(wallet: toWallet, label: 'Tujuan'),
        ],
      ),
    );
  }
}

/// Ikon dompet di ilustrasi transfer.
class _WalletIcon extends StatelessWidget {
  final Wallet? wallet;
  final String label;

  const _WalletIcon({this.wallet, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(40),
            shape: BoxShape.circle,
          ),
          child: Icon(
            wallet != null
                ? _getIconForType(wallet!.type)
                : Icons.account_balance_wallet_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          wallet?.name ?? label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}

/// Dropdown pemilih dompet, termasuk tampilan saldo.
class _WalletDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Wallet> wallets;
  final Wallet? selectedWallet;
  final NumberFormat currencyFormat;
  final ValueChanged<Wallet?> onChanged;

  const _WalletDropdown({
    required this.label,
    required this.icon,
    required this.wallets,
    required this.selectedWallet,
    required this.currencyFormat,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<String>(
      initialValue: selectedWallet?.id,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
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
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      items: wallets.map((wallet) {
        return DropdownMenuItem<String>(
          value: wallet.id,
          child: Row(
            children: [
              Icon(
                _getIconForType(wallet.type),
                size: 20,
                color: _getColorForType(wallet.type),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(wallet.name, overflow: TextOverflow.ellipsis),
              ),
              Text(
                currencyFormat.format(wallet.initialBalance),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (walletId) {
        if (walletId != null) {
          final wallet = wallets.firstWhere((w) => w.id == walletId);
          onChanged(wallet);
        }
      },
      validator: (value) {
        if (value == null) return 'Pilih dompet';
        return null;
      },
      isExpanded: true,
    );
  }
}

/// Tampilan ketika dompet aktif kurang dari 2.
class _InsufficientWalletsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.swap_horiz_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Minimal 2 Dompet Aktif',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda memerlukan minimal 2 dompet aktif untuk melakukan transfer dana antar dompet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.push('/add_edit_wallet'),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Dompet'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

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
