import 'package:duwitku/models/category.dart';
import 'package:duwitku/models/transaction.dart' as t;
import 'package:duwitku/providers/category_provider.dart';
import 'package:duwitku/providers/transaction_provider.dart';
import 'package:duwitku/utils/icon_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';

enum TransactionFilter { all, income, expense, date, category }

// Filter Notifier
class TransactionScreenFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => TransactionFilter.all;

  void setFilter(TransactionFilter filter) {
    state = filter;
  }
}

// Search Query Notifier
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final transactionScreenFilterProvider =
    NotifierProvider<TransactionScreenFilterNotifier, TransactionFilter>(() {
      return TransactionScreenFilterNotifier();
    });

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

class TransactionScreen extends ConsumerWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(filteredTransactionsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          _SearchBar(),
          _FilterChips(),
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) => categoriesAsync.when(
                data: (categories) {
                  final categoryMap = {for (var c in categories) c.id: c};
                  return _FilteredTransactionList(
                    transactions: transactions,
                    categoryMap: categoryMap,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) =>
                    Center(child: Text('Gagal memuat kategori: $err')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Terjadi kesalahan: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
          fillColor: Colors.black,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(transactionScreenFilterProvider);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        children: TransactionFilter.values.map((filter) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(filter.name.capitalize()),
              selected: currentFilter == filter,
              onSelected: (selected) {
                if (selected) {
                  ref
                      .read(transactionScreenFilterProvider.notifier)
                      .setFilter(filter);
                }
              },
            ),
          );
        }).toList(),
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
    final filter = ref.watch(transactionScreenFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

    final filteredTransactions = transactions.where((trx) {
      final category = categoryMap[trx.categoryId];
      final searchMatch =
          trx.description?.toLowerCase().contains(searchQuery) ??
          false ||
              (category?.name.toLowerCase().contains(searchQuery) ?? false);

      final typeMatch =
          filter == TransactionFilter.all ||
          (filter == TransactionFilter.income &&
              trx.type == t.TransactionType.income) ||
          (filter == TransactionFilter.expense &&
              trx.type == t.TransactionType.expense);

      return searchMatch && typeMatch;
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
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Ubah',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        dismissible: DismissiblePane(
          onDismissed: () {
            ref
                .read(transactionRepositoryProvider)
                .deleteTransaction(transaction.id);
          },
        ),
        children: [
          SlidableAction(
            onPressed: (context) {
              ref
                  .read(transactionRepositoryProvider)
                  .deleteTransaction(transaction.id);
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
    return Center(
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
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
