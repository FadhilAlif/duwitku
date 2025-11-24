import 'package:duwitku/models/category.dart';
import 'package:duwitku/models/transaction.dart' as t;
import 'package:duwitku/providers/category_provider.dart';
import 'package:duwitku/providers/transaction_provider.dart';
import 'package:duwitku/utils/export_helper.dart';
import 'package:duwitku/utils/icon_helper.dart';
import 'package:duwitku/views/transaction/transaction_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

class TransactionScreen extends ConsumerWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(filteredTransactionsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    final isLoading = transactionsAsync.isLoading || categoriesAsync.isLoading;

    final transactions = isLoading
        ? List.generate(
            6,
            (index) => t.Transaction(
              id: 'dummy_$index',
              userId: 'dummy',
              categoryId: 0,
              amount: 50000 * (index + 1).toDouble(),
              transactionDate: DateTime.now(),
              type: index % 2 == 0
                  ? t.TransactionType.income
                  : t.TransactionType.expense,
              sourceType: t.SourceType.app,
              description: 'Loading Transaction...',
            ),
          )
        : transactionsAsync.asData?.value ?? [];

    final categories = isLoading
        ? [
            Category(
              id: 0,
              name: 'Loading Category',
              type: CategoryType.expense,
              iconName: 'help_outline',
            )
          ]
        : categoriesAsync.asData?.value ?? [];

    final categoryMap = {for (var c in categories) c.id: c};

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          if (!isLoading && transactions.isNotEmpty)
            _ExportButton(
              transactions: transactions,
              categoryMap: categoryMap,
            ),
        ],
      ),
      body: Column(
        children: [
          const _FilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(filteredTransactionsStreamProvider);
                ref.invalidate(categoriesStreamProvider);
                // Wait a bit for the providers to refresh
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: Skeletonizer(
                enabled: isLoading,
                child: _FilteredTransactionList(
                  transactions: transactions,
                  categoryMap: categoryMap,
                ),
              ),
            ),
          ),
        ],
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

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).setQuery(value),
              decoration: InputDecoration(
                hintText: 'Cari transaksi...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16.0),
                  ),
                ),
                builder: (context) => const TransactionFilterSheet(),
              );
            },
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
            child: const Icon(Icons.tune),
          ),
        ],
      ),
    );
  }
}

class _FilteredTransactionList extends ConsumerWidget {
  final List<t.Transaction> transactions;
  final Map<int, Category> categoryMap;

  const _FilteredTransactionList({
    required this.transactions,
    required this.categoryMap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

    final filteredTransactions = transactions.where((trx) {
      if (searchQuery.isEmpty) return true;

      final category = categoryMap[trx.categoryId];
      return (trx.description?.toLowerCase().contains(searchQuery) ?? false) ||
          (category?.name.toLowerCase().contains(searchQuery) ?? false);
    }).toList();

    if (filteredTransactions.isEmpty) {
      return const _EmptyState();
    }

    final totalAmount = filteredTransactions.fold<double>(0.0, (sum, trx) {
      if (trx.type == t.TransactionType.income) {
        return sum + trx.amount;
      } else {
        return sum - trx.amount;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Menampilkan ${filteredTransactions.length} Transaksi: Total ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(totalAmount)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: GroupedListView<t.Transaction, DateTime>(
            physics: const AlwaysScrollableScrollPhysics(),
            elements: filteredTransactions,
            groupBy: (trx) => DateTime(
              trx.transactionDate.year,
              trx.transactionDate.month,
              trx.transactionDate.day,
            ),
            groupSeparatorBuilder: (DateTime date) => _ListHeader(date: date),
            itemBuilder: (context, trx) {
              final category = categoryMap[trx.categoryId];
              return _TransactionListItem(transaction: trx, category: category);
            },
            order: GroupedListOrder.DESC,
            useStickyGroupSeparators: true,
            floatingHeader: true,
          ),
        ),
      ],
    );
  }
}

class _TransactionListItem extends ConsumerWidget {
  final t.Transaction transaction;
  final Category? category;

  const _TransactionListItem({required this.transaction, this.category});

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

              // Force refresh not strictly needed with stream but good practice if needed
              // ref.invalidate(filteredTransactionsStreamProvider);
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
          subtitle: Text(category?.name ?? 'Tanpa Kategori'),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada transaksi nih',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
