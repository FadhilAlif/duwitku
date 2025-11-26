import 'package:duwitku/views/analytics/analytics_screen.dart';
import 'package:duwitku/views/budget/budget_screen.dart';
import 'package:duwitku/views/wallet/wallet_screen.dart';
import 'package:flutter/material.dart';

class FinanceHubScreen extends StatelessWidget {
  const FinanceHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Keuangan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(
                icon: Icon(Icons.analytics_outlined, size: 20),
                text: 'Analitik',
              ),
              Tab(
                icon: Icon(Icons.donut_large_outlined, size: 20),
                text: 'Anggaran',
              ),
              Tab(
                icon: Icon(Icons.account_balance_wallet_outlined, size: 20),
                text: 'Dompet',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [AnalyticsScreen(), BudgetScreen(), WalletScreen()],
        ),
      ),
    );
  }
}
