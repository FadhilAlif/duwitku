import 'dart:async';
import 'package:duwitku/models/budget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BudgetRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Budget>> streamBudgets(DateTime month) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Pengguna tidak terautentikasi');
    }

    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    // Workaround: Supabase stream has limited filtering.
    // Fetch all user's budgets and filter on the client.
    // For larger datasets, a database function (RPC) would be more performant.
    return _client
        .from('budgets')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((maps) {
          final budgets = maps.map((map) => Budget.fromJson(map)).toList();
          return budgets.where((b) {
            final budgetStart = b.startDate;
            final budgetEnd = b.endDate;
            // Check for any overlap between the budget's date range and the selected month.
            return budgetStart.isBefore(monthEnd) &&
                budgetEnd.isAfter(monthStart);
          }).toList();
        });
  }

  Future<void> createBudget(Budget budget) async {
    final data = budget.toJson();
    data['user_id'] = _client.auth.currentUser!.id;
    await _client.from('budgets').insert(data);
  }

  Future<void> updateBudget(Budget budget) async {
    final data = budget.toJson();
    await _client.from('budgets').update(data).eq('id', budget.id);
  }

  Future<void> deleteBudget(int id) async {
    await _client.from('budgets').delete().eq('id', id);
  }
}
