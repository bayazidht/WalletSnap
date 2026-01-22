import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/transaction_item.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    final results = transactionProvider.filteredTransactions.where((tx) {
      final titleMatch = tx.title.toLowerCase().contains(searchQuery.toLowerCase());
      final amountMatch = tx.amount.toString().contains(searchQuery);
      return titleMatch || amountMatch;
    }).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
        ),
        actions: [
          if (searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() { searchQuery = ''; });
                },
                icon: const Icon(Icons.clear),
              ),
            ),
        ],
      ),
      body: searchQuery.isEmpty
          ? _buildEmptyState(Icons.search, "Search for any transaction")
          : results.isEmpty
          ? _buildEmptyState(Icons.receipt_long_rounded, "No transactions found")
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: results.length,
        itemBuilder: (context, index) {
          return TransactionItem(tx: results[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}