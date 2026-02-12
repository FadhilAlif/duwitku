import 'package:duwitku/models/wallet_group.dart';
import 'package:duwitku/repositories/wallet_group_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final walletGroupRepositoryProvider = Provider<WalletGroupRepository>((ref) {
  return WalletGroupRepository();
});

final walletGroupsStreamProvider =
    StreamProvider.autoDispose<List<WalletGroup>>((ref) {
      final repository = ref.watch(walletGroupRepositoryProvider);
      return repository.getGroupsStream();
    });
