import 'package:duwitku/models/wallet.dart';
import 'package:duwitku/repositories/wallet_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository();
});

final walletsStreamProvider = StreamProvider.autoDispose<List<Wallet>>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getWalletsStream();
});
