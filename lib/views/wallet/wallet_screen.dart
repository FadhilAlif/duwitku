import 'package:duwitku/models/transaction.dart';
import 'package:duwitku/models/wallet.dart';
import 'package:duwitku/providers/transaction_provider.dart';
import 'package:duwitku/providers/ui_provider.dart';
import 'package:duwitku/providers/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsStreamProvider);
    final isBalanceVisible = ref.watch(isWalletBalanceVisibleProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletsStreamProvider);
          // Wait briefly to ensure UI updates if data is fast
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: walletsAsync.when(
          data: (wallets) {
            final totalBalance = wallets.fold<double>(
              0,
              (sum, wallet) => sum + wallet.initialBalance,
            );

            if (wallets.isEmpty) {
              return const _EmptyWalletState();
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // Total Balance Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withAlpha(80),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Aset',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white60,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isBalanceVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white60,
                              size: 20,
                            ),
                            onPressed: () => ref
                                .read(isWalletBalanceVisibleProvider.notifier)
                                .toggle(),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isBalanceVisible
                            ? currencyFormat.format(totalBalance)
                            : 'Rp ********',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Action Buttons Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: wallets.length >= 2
                                  ? () => context.push('/transfer')
                                  : null,
                              icon: const Icon(
                                Icons.swap_horiz_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: const Text(
                                'Transfer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.white.withAlpha(100),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                disabledForegroundColor: Colors.white.withAlpha(
                                  80,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/wallet_groups'),
                              icon: const Icon(
                                Icons.folder_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: const Text(
                                'Grup Dompet',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.white.withAlpha(100),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // List Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daftar Dompet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${wallets.length} Akun',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Wallet List
                ...wallets.map((wallet) => _WalletItem(wallet: wallet)),

                const SizedBox(height: 16),

                // Add Wallet Button (Inline)
                InkWell(
                  onTap: () => context.push('/add_edit_wallet'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.outline.withAlpha(100),
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: colorScheme.surfaceContainerLow.withAlpha(128),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tambah Dompet Baru',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            );
          },
          loading: () => Skeletonizer(
            enabled: true,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => const Card(
                margin: EdgeInsets.only(bottom: 12),
                child: SizedBox(height: 80),
              ),
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Terjadi kesalahan: $error'),
                TextButton(
                  onPressed: () => ref.invalidate(walletsStreamProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletItem extends ConsumerWidget {
  final Wallet wallet;

  const _WalletItem({required this.wallet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: Key(wallet.id),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (context) =>
                  context.push('/add_edit_wallet', extra: wallet),
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Ubah',
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => _confirmDelete(context, ref, wallet),
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              icon: Icons.delete,
              label: 'Hapus',
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(16),
              ),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          color: colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
          ),
          margin: EdgeInsets.zero,
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () => context.push('/wallet_detail', extra: wallet),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getColorForType(wallet.type).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconForType(wallet.type),
                      color: _getColorForType(wallet.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          wallet.type.displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(wallet.initialBalance),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _MonthlyChangeIndicator(walletId: wallet.id),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Wallet wallet,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Dompet?'),
        content: Text('Apakah Anda yakin ingin menghapus "${wallet.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(walletRepositoryProvider).deleteWallet(wallet.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dompet berhasil dihapus')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
        }
      }
    }
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

class _EmptyWalletState extends StatelessWidget {
  const _EmptyWalletState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withAlpha(128),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Dompet Masih Kosong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tambahkan dompet pertama Anda untuk mulai mencatat keuangan dengan lebih rapi.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.push('/add_edit_wallet'),
                icon: const Icon(Icons.add),
                label: const Text('Buat Dompet Baru'),
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
      ),
    );
  }
}

// Monthly Change Indicator Widget
class _MonthlyChangeIndicator extends ConsumerWidget {
  final String walletId;

  const _MonthlyChangeIndicator({required this.walletId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(filteredTransactionsStreamProvider);

    return transactionsAsync.when(
      data: (transactions) {
        final walletTransactions = transactions
            .where((t) => t.walletId == walletId)
            .toList();

        if (walletTransactions.isEmpty) {
          return const SizedBox.shrink();
        }

        final income = walletTransactions
            .where((trx) => trx.type == TransactionType.income)
            .fold(0.0, (sum, trx) => sum + trx.amount);

        final expense = walletTransactions
            .where((trx) => trx.type == TransactionType.expense)
            .fold(0.0, (sum, trx) => sum + trx.amount);

        final netChange = income - expense;

        if (netChange == 0) {
          return const SizedBox.shrink();
        }

        final isPositive = netChange > 0;
        final color = isPositive ? Colors.green : Colors.red;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              color: color,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              NumberFormat.compactCurrency(
                locale: 'id_ID',
                symbol: '',
                decimalDigits: 0,
              ).format(netChange.abs()),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
