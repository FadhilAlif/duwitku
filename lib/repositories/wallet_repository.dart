import 'package:duwitku/models/wallet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Wallet>> getWalletsStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Pengguna tidak terautentikasi');
    }

    return _client
        .from('wallets')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: true)
        .map((maps) => maps.map((map) => Wallet.fromJson(map)).toList());
  }

  Future<void> addWallet(Wallet wallet) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Pengguna tidak terautentikasi');
    }

    final data = wallet.toJson();
    // Remove id if it's empty or generated client-side but we want DB to generate it
    // But since we pass full object, we just ensure user_id is correct
    data['user_id'] = userId;
    // If id is empty string or we want DB to gen it, we shouldn't send it usually unless we gen UUIDs client side.
    // Based on schema: id UUID NOT NULL DEFAULT gen_random_uuid()
    // So we don't send ID for insert usually.

    await _client.from('wallets').insert(data);
  }

  Future<void> updateWallet(Wallet wallet) async {
    final data = wallet.toJson();
    // Don't update user_id typically
    data.remove('user_id');
    data.remove('created_at');

    await _client.from('wallets').update(data).eq('id', wallet.id);
  }

  Future<void> deleteWallet(String id) async {
    await _client.from('wallets').delete().eq('id', id);
  }

  /// Transfer dana dari satu dompet ke dompet lainnya.
  ///
  /// [fromWalletId] - ID dompet sumber (pengirim).
  /// [toWalletId] - ID dompet tujuan (penerima).
  /// [amount] - Jumlah dana yang ditransfer (harus > 0).
  ///
  /// Throws [Exception] jika saldo tidak cukup atau wallet tidak ditemukan.
  Future<void> transferFunds({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
  }) async {
    if (amount <= 0) {
      throw Exception('Jumlah transfer harus lebih dari 0');
    }

    if (fromWalletId == toWalletId) {
      throw Exception('Dompet asal dan tujuan tidak boleh sama');
    }

    // 1. Fetch kedua wallet
    final fromWalletResponse = await _client
        .from('wallets')
        .select()
        .eq('id', fromWalletId)
        .single();

    final toWalletResponse = await _client
        .from('wallets')
        .select()
        .eq('id', toWalletId)
        .single();

    final fromBalance = (fromWalletResponse['initial_balance'] as num)
        .toDouble();
    final toBalance = (toWalletResponse['initial_balance'] as num).toDouble();

    // 2. Validasi saldo cukup
    if (fromBalance < amount) {
      throw Exception(
        'Saldo dompet tidak mencukupi. '
        'Saldo saat ini: ${fromBalance.toStringAsFixed(0)}',
      );
    }

    // 3. Update saldo kedua wallet
    await _client
        .from('wallets')
        .update({'initial_balance': fromBalance - amount})
        .eq('id', fromWalletId);

    await _client
        .from('wallets')
        .update({'initial_balance': toBalance + amount})
        .eq('id', toWalletId);
  }
}
