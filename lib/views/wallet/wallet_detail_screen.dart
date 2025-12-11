import 'package:duwitku/models/category.dart';
import 'package:duwitku/models/transaction.dart' as t;
import 'package:duwitku/models/wallet.dart';
import 'package:duwitku/providers/category_provider.dart';
import 'package:duwitku/providers/transaction_provider.dart';
import 'package:duwitku/utils/export_helper.dart';
import 'package:duwitku/utils/icon_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class WalletDetailScreen extends ConsumerWidget {
  final Wallet wallet;

  const WalletDetailScreen({super.key, required this.wallet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(
      walletTransactionsStreamProvider(wallet.id),
    );
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    final isLoading = transactionsAsync.isLoading || categoriesAsync.isLoading;

    final transactions = isLoading
        ? List.generate(
            5,
            (index) => t.Transaction(
              id: 'dummy_$index',
              userId: 'dummy',
              categoryId: 0,
              amount: 100000,
              transactionDate: DateTime.now(),
              type: index % 2 == 0
                  ? t.TransactionType.income
                  : t.TransactionType.expense,
              sourceType: t.SourceType.app,
              description: 'Loading Transaction...',
              walletId: wallet.id,
            ),
          )
        : transactionsAsync.asData?.value ?? [];

    final categories = isLoading
        ? [
            Category(
              id: 0,
              name: 'Loading...',
              type: CategoryType.expense,
              iconName: 'help_outline',
            ),
          ]
        : categoriesAsync.asData?.value ?? [];

    final categoryMap = {for (var c in categories) c.id: c};

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(wallet.name),
        actions: [
          if (!isLoading && transactions.isNotEmpty)
            _ExportButton(transactions: transactions, categoryMap: categoryMap),
        ],
      ),
      body: Column(
        children: [
          _WalletSummaryCard(
            wallet: wallet,
            currencyFormatter: currencyFormatter,
          ),
          Expanded(
            child: Skeletonizer(
              enabled: isLoading,
              child: _WalletTransactionList(
                transactions: transactions,
                categoryMap: categoryMap,
                wallet: wallet,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletSummaryCard extends StatelessWidget {
  final Wallet wallet;
  final NumberFormat currencyFormatter;

  const _WalletSummaryCard({
    required this.wallet,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getWalletIcon(wallet.type),
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Text(
                'Saldo Dompet',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer.withAlpha(204),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormatter.format(wallet.initialBalance),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletTransactionList extends StatelessWidget {
  final List<t.Transaction> transactions;
  final Map<int, Category> categoryMap;
  final Wallet wallet;

  const _WalletTransactionList({
    required this.transactions,
    required this.categoryMap,
    required this.wallet,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada transaksi di dompet ini',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return GroupedListView<t.Transaction, DateTime>(
      physics: const AlwaysScrollableScrollPhysics(),
      elements: transactions,
      groupBy: (trx) => DateTime(
        trx.transactionDate.year,
        trx.transactionDate.month,
        trx.transactionDate.day,
      ),
      groupSeparatorBuilder: (DateTime date) => _ListHeader(date: date),
      itemBuilder: (context, trx) {
        final category = categoryMap[trx.categoryId];
        return _TransactionListItem(
          transaction: trx,
          category: category,
          wallet: wallet,
        );
      },
      order: GroupedListOrder.DESC,
      useStickyGroupSeparators: true,
      floatingHeader: true,
    );
  }
}

class _TransactionListItem extends ConsumerWidget {
  final t.Transaction transaction;
  final Category? category;
  final Wallet wallet;

  const _TransactionListItem({
    required this.transaction,
    this.category,
    required this.wallet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final isIncome = transaction.type == t.TransactionType.income;

    return Slidable(
      key: ValueKey(transaction.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              context.push('/transaction_form', extra: transaction);
            },
            backgroundColor: Colors.yellow.shade700,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Ubah',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        dismissible: DismissiblePane(
          confirmDismiss: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Hapus Transaksi'),
                content: const Text(
                  'Apakah Anda yakin ingin menghapus transaksi ini?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Batal'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Hapus'),
                  ),
                ],
              ),
            );
            return confirm ?? false;
          },
          onDismissed: () async {
            try {
              await ref
                  .read(transactionRepositoryProvider)
                  .deleteTransaction(transaction.id);
            } catch (e) {
              // Error handling
            }
          },
        ),
        children: [
          SlidableAction(
            onPressed: (context) async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hapus Transaksi'),
                  content: const Text(
                    'Apakah Anda yakin ingin menghapus transaksi ini?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menghapus transaksi...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }

                  await ref
                      .read(transactionRepositoryProvider)
                      .deleteTransaction(transaction.id);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transaksi berhasil dihapus'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus transaksi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Hapus',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isIncome
                ? Colors.green.withAlpha(50)
                : Colors.red.withAlpha(50),
            child: Icon(
              IconHelper.getIcon(category?.iconName),
              color: isIncome ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          title: Text(
            transaction.description ?? category?.name ?? 'T/A',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(category?.name ?? 'Tanpa Kategori'),
              Row(
                children: [
                  Icon(
                    _getWalletIcon(wallet.type),
                    size: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    wallet.name,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          trailing: Text(
            '${isIncome ? '+' : '-'} ${currencyFormatter.format(transaction.amount)}',
            style: TextStyle(
              color: isIncome ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  final DateTime date;
  const _ListHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        DateFormat.yMMMMd('id_ID').format(date),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final List<t.Transaction> transactions;
  final Map<int, Category> categoryMap;

  const _ExportButton({required this.transactions, required this.categoryMap});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.download),
      onSelected: (value) async {
        if (value == 'csv') {
          await ExportHelper.exportToCsv(transactions, categoryMap);
        } else if (value == 'pdf') {
          await ExportHelper.exportToPdf(transactions, categoryMap);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'csv',
          child: Row(
            children: [
              Icon(Icons.description, color: Colors.green),
              SizedBox(width: 8),
              Text('Export CSV'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red),
              SizedBox(width: 8),
              Text('Export PDF'),
            ],
          ),
        ),
      ],
    );
  }
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
