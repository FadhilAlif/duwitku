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
    
    await _client
        .from('wallets')
        .update(data)
        .eq('id', wallet.id);
  }

  Future<void> deleteWallet(String id) async {
    await _client.from('wallets').delete().eq('id', id);
  }
}
