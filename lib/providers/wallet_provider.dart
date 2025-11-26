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

// Provider untuk menghitung total aset dari semua wallet aktif
// Catatan: initial_balance sudah mencerminkan saldo riil (initial + semua transaksi)
// karena setiap add/update/delete transaksi sudah mengupdate initial_balance di repository
final totalAssetsProvider = StreamProvider.autoDispose<double>((ref) {
  final walletsStream = ref.watch(walletsStreamProvider);

  return walletsStream.when(
    data: (wallets) async* {
      // Hitung total dari semua wallet aktif
      // initial_balance sudah termasuk semua transaksi yang pernah terjadi
      final totalAssets = wallets
          .where((w) => w.isActive)
          .fold(0.0, (sum, wallet) => sum + wallet.initialBalance);

      yield totalAssets;
    },
    loading: () => Stream.value(0),
    error: (error, stack) => Stream.value(0),
  );
});
