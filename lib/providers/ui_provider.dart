import 'package:flutter_riverpod/flutter_riverpod.dart';

// Navigation index for the bottom navigation bar
class BottomNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final bottomNavIndexProvider = NotifierProvider<BottomNavIndexNotifier, int>(
  () {
    return BottomNavIndexNotifier();
  },
);

// Visibility toggle for balance/income/expense on Home Screen
class BalanceVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() {
    state = !state;
  }
}

final isBalanceVisibleProvider =
    NotifierProvider<BalanceVisibilityNotifier, bool>(() {
      return BalanceVisibilityNotifier();
    });

// Visibility toggle for wallet balance
class WalletBalanceVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() => false; // Default hidden

  void toggle() {
    state = !state;
  }
}

final isWalletBalanceVisibleProvider =
    NotifierProvider<WalletBalanceVisibilityNotifier, bool>(() {
      return WalletBalanceVisibilityNotifier();
    });
