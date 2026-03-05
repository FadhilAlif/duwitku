import 'package:duwitku/models/wallet_group.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletGroupRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Stream semua grup dompet milik user beserta wallet member IDs.
  Stream<List<WalletGroup>> getGroupsStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Pengguna tidak terautentikasi');
    }

    // Stream dari tabel wallet_groups
    final groupsStream = _client
        .from('wallet_groups')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    // Untuk setiap emit, fetch members secara terpisah
    return groupsStream.asyncMap((groupMaps) async {
      final groups = <WalletGroup>[];

      for (final groupMap in groupMaps) {
        final groupId = groupMap['id'] as String;

        // Fetch member wallet IDs untuk grup ini
        final membersResponse = await _client
            .from('wallet_group_members')
            .select('wallet_id')
            .eq('group_id', groupId);

        final walletIds = (membersResponse as List)
            .map((m) => m['wallet_id'] as String)
            .toList();

        groups.add(WalletGroup.fromJson(groupMap, walletIds: walletIds));
      }

      return groups;
    });
  }

  /// Buat grup baru dengan daftar wallet.
  Future<void> addGroup({
    required String name,
    required List<String> walletIds,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Pengguna tidak terautentikasi');
    }

    // 1. Insert grup
    final groupResponse = await _client
        .from('wallet_groups')
        .insert({'user_id': userId, 'name': name})
        .select('id')
        .single();

    final groupId = groupResponse['id'] as String;

    // 2. Insert members
    if (walletIds.isNotEmpty) {
      final members = walletIds
          .map((wId) => {'group_id': groupId, 'wallet_id': wId})
          .toList();
      await _client.from('wallet_group_members').insert(members);
    }
  }

  /// Update nama grup dan sync wallet members.
  Future<void> updateGroup({
    required String groupId,
    required String name,
    required List<String> walletIds,
  }) async {
    // 1. Update nama
    await _client
        .from('wallet_groups')
        .update({'name': name})
        .eq('id', groupId);

    // 2. Hapus semua member lama
    await _client.from('wallet_group_members').delete().eq('group_id', groupId);

    // 3. Insert member baru
    if (walletIds.isNotEmpty) {
      final members = walletIds
          .map((wId) => {'group_id': groupId, 'wallet_id': wId})
          .toList();
      await _client.from('wallet_group_members').insert(members);
    }
  }

  /// Hapus grup (members terhapus otomatis via CASCADE).
  Future<void> deleteGroup(String groupId) async {
    await _client.from('wallet_groups').delete().eq('id', groupId);
  }
}
