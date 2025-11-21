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
          final transactions = maps.map((map) => Transaction.fromJson(map)).toList();
          return transactions.where((trx) {
            return trx.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
                   trx.transactionDate.isBefore(endDate.add(const Duration(days: 1)));
          }).toList();
        });
  }

  Future<void> addTransaction(Transaction transaction) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Pengguna tidak terautentikasi');
    }

    final data = transaction.toJson();
    // Ensure the user_id from the authenticated user is used
    data['user_id'] = userId;

    await _client.from('transactions').insert(data);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _client
        .from('transactions')
        .update(transaction.toJson())
        .eq('id', transaction.id);
  }

  Future<void> deleteTransaction(String id) async {
    await _client.from('transactions').delete().eq('id', id);
  }
}
