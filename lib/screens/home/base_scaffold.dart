import 'package:flutter/material.dart';
import 'package:wallet_snap/screens/home/home_screen.dart';
import 'package:wallet_snap/screens/transactions/transactions_screen.dart';
import 'package:wallet_snap/screens/graphs/graphs_screen.dart';
import 'package:wallet_snap/screens/settings/settings_screen.dart';
import 'package:wallet_snap/screens/transactions/add_transaction_screen.dart';

class BaseScaffold extends StatefulWidget {
  const BaseScaffold({super.key});

  @override
  State<BaseScaffold> createState() => BaseScaffoldState();
}

class BaseScaffoldState extends State<BaseScaffold> {
  int _selectedIndex = 0;

  void setSelectedIndex(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const TransactionsScreen(),
    GraphsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      floatingActionButton: SizedBox(
        height: 65,
        width: 65,
        child: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          ),
          backgroundColor: colorScheme.primary,
          elevation: 4,
          shape: CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 35, color: Colors.white),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(context, Icons.home_filled, 'Home', 0),
            _buildNavItem(context, Icons.receipt_long, 'Transactions', 1),

            const SizedBox(width: 48),

            _buildNavItem(context, Icons.bar_chart, 'Graphs', 2),
            _buildNavItem(context, Icons.settings, 'Settings', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => setSelectedIndex(index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 60,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}