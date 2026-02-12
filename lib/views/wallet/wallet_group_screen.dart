import 'package:duwitku/models/wallet.dart';
import 'package:duwitku/models/wallet_group.dart';
import 'package:duwitku/providers/wallet_group_provider.dart';
import 'package:duwitku/providers/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class WalletGroupScreen extends ConsumerWidget {
  const WalletGroupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(walletGroupsStreamProvider);
    final walletsAsync = ref.watch(walletsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Grup Dompet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add_edit_wallet_group'),
        child: const Icon(Icons.add),
      ),
      body: groupsAsync.when(
        data: (groups) {
          final wallets = walletsAsync.asData?.value ?? [];
          final walletMap = {for (var w in wallets) w.id: w};

          if (groups.isEmpty) {
            return _EmptyGroupState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _GroupCard(group: group, walletMap: walletMap);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Terjadi kesalahan: $error'),
              TextButton(
                onPressed: () => ref.invalidate(walletGroupsStreamProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  final WalletGroup group;
  final Map<String, Wallet> walletMap;

  const _GroupCard({required this.group, required this.walletMap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Hitung total saldo dari wallet member
    final memberWallets = group.walletIds
        .map((id) => walletMap[id])
        .where((w) => w != null)
        .cast<Wallet>()
        .toList();

    final totalBalance = memberWallets.fold<double>(
      0,
      (sum, w) => sum + w.initialBalance,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: Key(group.id),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) =>
                  context.push('/add_edit_wallet_group', extra: group),
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
              onPressed: (_) => _confirmDelete(context, ref),
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
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              childrenPadding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 12,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.folder_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              title: Text(
                group.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${memberWallets.length} dompet • ${currencyFormat.format(totalBalance)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: memberWallets.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Belum ada dompet dalam grup ini',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ]
                  : memberWallets
                        .map((w) => _MemberWalletTile(wallet: w))
                        .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Grup?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus grup "${group.name}"?\n'
          'Dompet di dalamnya tidak akan terhapus.',
        ),
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
        await ref.read(walletGroupRepositoryProvider).deleteGroup(group.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Grup berhasil dihapus')),
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
}

class _MemberWalletTile extends StatelessWidget {
  final Wallet wallet;

  const _MemberWalletTile({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getColorForType(wallet.type).withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconForType(wallet.type),
              color: _getColorForType(wallet.type),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(wallet.name, style: theme.textTheme.bodyMedium)),
          Text(
            currencyFormat.format(wallet.initialBalance),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGroupState extends StatelessWidget {
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
                Icons.folder_open_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Grup',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Buat grup untuk mengelompokkan dompet Anda. '
              'Contoh: Dana Darurat, Tabungan Liburan.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.push('/add_edit_wallet_group'),
              icon: const Icon(Icons.add),
              label: const Text('Buat Grup Baru'),
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
