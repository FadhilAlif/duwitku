import 'dart:async';

import 'package:duwitku/models/transaction.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Transaction>> getTransactionsStream({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Pengguna tidak terautentikasi');
    }

    // Workaround: Filter client-side if the analyzer has issues with Supabase builder methods.
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('transaction_date', ascending: false)
        .map((maps) {
          final transactions = maps
              .map((map) => Transaction.fromJson(map))
              .toList();
          return transactions.where((trx) {
            return trx.transactionDate.isAfter(
                  startDate.subtract(const Duration(days: 1)),
                ) &&
                trx.transactionDate.isBefore(
                  endDate.add(const Duration(days: 1)),
                );
          }).toList();
        });
  }

  Future<void> addTransaction(Transaction transaction) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Pengguna tidak terautentikasi');
    }

    // 1. Fetch Wallet
    final walletResponse = await _client
        .from('wallets')
        .select()
        .eq('id', transaction.walletId)
        .single();
    
    final currentBalance = (walletResponse['initial_balance'] as num).toDouble();
    double newBalance = currentBalance;

    if (transaction.type == TransactionType.income) {
      newBalance += transaction.amount;
    } else {
      newBalance -= transaction.amount;
    }

    // 2. Update Wallet Balance
    await _client
        .from('wallets')
        .update({'initial_balance': newBalance})
        .eq('id', transaction.walletId);

    // 3. Insert Transaction
    final data = transaction.toJson();
    data['user_id'] = userId;

    await _client.from('transactions').insert(data);
  }

  Future<void> addTransactions(List<Transaction> transactions) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Pengguna tidak terautentikasi');
    }

    // Group transactions by wallet to batch updates
    final Map<String, double> walletChanges = {};

    for (var trx in transactions) {
      final amount = trx.type == TransactionType.income ? trx.amount : -trx.amount;
      walletChanges[trx.walletId] = (walletChanges[trx.walletId] ?? 0) + amount;
    }

    // Update Wallets
    for (var entry in walletChanges.entries) {
      final walletId = entry.key;
      final change = entry.value;

      final walletResponse = await _client
          .from('wallets')
          .select()
          .eq('id', walletId)
          .single();
      
      final currentBalance = (walletResponse['initial_balance'] as num).toDouble();
      await _client
          .from('wallets')
          .update({'initial_balance': currentBalance + change})
          .eq('id', walletId);
    }

    // Insert Transactions
    final data = transactions.map((t) {
      final json = t.toJson();
      json['user_id'] = userId;
      return json;
    }).toList();

    await _client.from('transactions').insert(data);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    // 1. Fetch Old Transaction to compare
    final oldTrxResponse = await _client
        .from('transactions')
        .select()
        .eq('id', transaction.id)
        .single();
    final oldTrx = Transaction.fromJson(oldTrxResponse);

    // 2. Handle Wallet Updates
    if (oldTrx.walletId == transaction.walletId) {
      // Same Wallet: Adjust difference
      double balanceChange = 0;
      
      // Revert old
      if (oldTrx.type == TransactionType.income) {
        balanceChange -= oldTrx.amount;
      } else {
        balanceChange += oldTrx.amount;
      }

      // Apply new
      if (transaction.type == TransactionType.income) {
        balanceChange += transaction.amount;
      } else {
        balanceChange -= transaction.amount;
      }

      if (balanceChange != 0) {
        final walletResponse = await _client
            .from('wallets')
            .select()
            .eq('id', transaction.walletId)
            .single();
        final currentBalance = (walletResponse['initial_balance'] as num).toDouble();
        
        await _client
            .from('wallets')
            .update({'initial_balance': currentBalance + balanceChange})
            .eq('id', transaction.walletId);
      }
    } else {
      // Wallet Changed: Revert from old, Apply to new
      
      // Revert from Old Wallet
      final oldWalletResponse = await _client
          .from('wallets')
          .select()
          .eq('id', oldTrx.walletId)
          .single();
      final oldWalletBalance = (oldWalletResponse['initial_balance'] as num).toDouble();
      
      double oldRevertChange = 0;
      if (oldTrx.type == TransactionType.income) {
        oldRevertChange -= oldTrx.amount;
      } else {
        oldRevertChange += oldTrx.amount;
      }
      
      await _client
          .from('wallets')
          .update({'initial_balance': oldWalletBalance + oldRevertChange})
          .eq('id', oldTrx.walletId);

      // Apply to New Wallet
      final newWalletResponse = await _client
          .from('wallets')
          .select()
          .eq('id', transaction.walletId)
          .single();
      final newWalletBalance = (newWalletResponse['initial_balance'] as num).toDouble();

      double newApplyChange = 0;
      if (transaction.type == TransactionType.income) {
        newApplyChange += transaction.amount;
      } else {
        newApplyChange -= transaction.amount;
      }

      await _client
          .from('wallets')
          .update({'initial_balance': newWalletBalance + newApplyChange})
          .eq('id', transaction.walletId);
    }

    // 3. Update Transaction
    await _client
        .from('transactions')
        .update(transaction.toJson())
        .eq('id', transaction.id);
  }

  Future<void> deleteTransaction(String id) async {
    // 1. Fetch Transaction to revert balance
    final trxResponse = await _client
        .from('transactions')
        .select()
        .eq('id', id)
        .single();
    final trx = Transaction.fromJson(trxResponse);

    // 2. Revert Wallet Balance
    final walletResponse = await _client
        .from('wallets')
        .select()
        .eq('id', trx.walletId)
        .single();
    final currentBalance = (walletResponse['initial_balance'] as num).toDouble();

    double balanceChange = 0;
    // Revert logic (Reverse of add)
    if (trx.type == TransactionType.income) {
      balanceChange -= trx.amount; // Was income, so subtract
    } else {
      balanceChange += trx.amount; // Was expense, so add back
    }

    await _client
        .from('wallets')
        .update({'initial_balance': currentBalance + balanceChange})
        .eq('id', trx.walletId);

    // 3. Delete Transaction
    await _client.from('transactions').delete().eq('id', id);
  }

  Future<double> getMaxTransactionAmount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    try {
      final response = await _client
          .from('transactions')
          .select('amount')
          .eq('user_id', userId)
          .order('amount', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return 0;
      return (response['amount'] as num).toDouble();
    } catch (e) {
      return 0;
    }
  }
}
