import 'package:duwitku/views/budget/budget_screen.dart';
import 'package:duwitku/views/home/home_screen.dart';
import 'package:duwitku/views/profile/profile_screen.dart';
import 'package:duwitku/views/transaction/transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    TransactionScreen(),
    BudgetScreen(),
    ProfileScreen(),
  ];

  void _showAddTransactionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      // backgroundColor: Colors.white,
      backgroundColor: const Color(0xFF14894e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Wrap(
          children: <Widget>[
            const ListTile(
              title: Text(
                'Tambah Transaksi Baru',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_document),
              title: const Text('Buat Transaksi'),
              onTap: () {
                Navigator.pop(context);
                context.push('/transaction_form');
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Pindai Struk'),
              onTap: () {
                Navigator.pop(context);
                context.push('/scan_struk');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Chat Prompt'),
              onTap: () {
                Navigator.pop(context);
                context.push('/chat_prompt');
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionModal(context),
        backgroundColor: const Color(0xFF14894e),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 29, 105, 67),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withAlpha((0.1 * 255).round()),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 15.0,
              vertical: 8.0,
            ),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: Colors.white,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: const Color(0xFF14894e),
              color: Colors.black,
              tabs: const [
                GButton(icon: Icons.home, text: 'Beranda'),
                GButton(icon: Icons.receipt_long, text: 'Transaksi'),
                GButton(icon: Icons.account_balance_wallet, text: 'Anggaran'),
                GButton(icon: Icons.person, text: 'Profil'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
