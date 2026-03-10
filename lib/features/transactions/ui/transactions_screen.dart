import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wallet_snap/features/transactions/logic/transaction_provider.dart';
import 'package:wallet_snap/features/categories/logic/category_provider.dart';
import 'package:wallet_snap/features/transactions/ui/transaction_item.dart';
import '../../../core/constants/default_category_icons.dart';
import '../data/transaction_model.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _selectedCategoryId;
  DateTime? _selectedDate;
  TransactionType? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, List<TransactionModel>> _groupTransactions(List<TransactionModel> transactions) {
    Map<String, List<TransactionModel>> grouped = {};
    for (var tx in transactions) {
      String dateKey = DateFormat('yyyy-MM-dd').format(tx.date);
      grouped.putIfAbsent(dateKey, () => []).add(tx);
    }
    return grouped;
  }

  String _formatHeaderDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    if (txDate == today) return "Today";
    if (txDate == yesterday) return "Yesterday";
    return DateFormat('dd MMMM yyyy').format(date);
  }

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> allTransactions, int tabIndex) {
    return allTransactions.where((tx) {

      if (tabIndex == 1 && tx.type != TransactionType.expense) return false;
      if (tabIndex == 2 && tx.type != TransactionType.income) return false;

      if (_selectedType != null && tx.type != _selectedType) return false;
      if (_selectedCategoryId != null && tx.categoryId != _selectedCategoryId) return false;
      if (_selectedDate != null) {
        if (tx.date.year != _selectedDate!.year ||
            tx.date.month != _selectedDate!.month ||
            tx.date.day != _selectedDate!.day) {
          return false;
        }
      }
      return true;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(transactionProvider);
    final transactions = ref.watch(filteredTransactionsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => _showFilterBottomSheet(colorScheme),
            icon: Badge(
              isLabelVisible: _selectedType != null || _selectedCategoryId != null || _selectedDate != null,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.tune_rounded, size: 20, color: colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [Tab(text: 'All'), Tab(text: 'Expense'), Tab(text: 'Income')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(3, (i) => _buildTransactionList(transactions, i, colorScheme)),
      ),
    );
  }

  Widget _buildTransactionList(List<TransactionModel> all, int index, ColorScheme colorScheme) {
    final filtered = _getFilteredTransactions(all, index);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 80, color: colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('No transactions found', style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    final groupedData = _groupTransactions(filtered);
    final sortedDates = groupedData.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final dateKey = sortedDates[dateIndex];
        final txList = groupedData[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 16, bottom: 8),
              child: Text(
                _formatHeaderDate(dateKey),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.outline),
              ),
            ),
            ...txList.map((tx) => TransactionItem(tx: tx)),
          ],
        );
      },
    );
  }

  void _showFilterBottomSheet(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) {
          final categories = ref.watch(categoryProvider);
          final currentCategories = _selectedType == null
              ? []
              : categories.where((c) => c.type.name == _selectedType!.name).toList();

          return Container(
            padding: EdgeInsets.only(
              top: 20, left: 24, right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 30,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategoryId = null;
                          _selectedDate = null;
                          _selectedType = null;
                        });
                        Navigator.pop(context);
                      },
                      child: Text('Clear All', style: TextStyle(color: colorScheme.error)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildFilterLabel('Transaction Type'),
                const SizedBox(height: 10),
                _buildDropdown<TransactionType?>(
                  value: _selectedType,
                  hint: 'All Types',
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Types')),
                    const DropdownMenuItem(value: TransactionType.income, child: Text('Income')),
                    const DropdownMenuItem(value: TransactionType.expense, child: Text('Expense')),
                  ],
                  onChanged: (val) => setStateSheet(() {
                    _selectedType = val;
                    _selectedCategoryId = null;
                  }),
                ),
                const SizedBox(height: 20),
                _buildFilterLabel('Category'),
                const SizedBox(height: 10),
                _buildDropdown<String?>(
                  value: _selectedCategoryId,
                  hint: _selectedType == null ? 'Select type first' : 'All Categories',
                  enabled: _selectedType != null,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Categories')),
                    ...currentCategories.map((cat) => DropdownMenuItem(
                      value: cat.id,
                      child: Row(
                        children: [
                          Icon(availableIcons[cat.iconName] ?? Icons.category_rounded, size: 18, color: colorScheme.primary),
                          const SizedBox(width: 10),
                          Text(cat.name),
                        ],
                      ),
                    )),
                  ],
                  onChanged: (val) => setStateSheet(() => _selectedCategoryId = val),
                ),
                const SizedBox(height: 20),
                _buildFilterLabel('Date'),
                const SizedBox(height: 10),
                _buildDatePickerTrigger(colorScheme, setStateSheet),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('Apply Filter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDatePickerTrigger(ColorScheme colorScheme, StateSetter setStateSheet) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) setStateSheet(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_selectedDate == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(_selectedDate!), style: TextStyle(color: colorScheme.onSurface)),
            Icon(Icons.calendar_today_rounded, size: 18, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterLabel(String label) => Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey));

  Widget _buildDropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required Function(T) onChanged,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: enabled ? Colors.transparent : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          borderRadius: BorderRadius.circular(16),
          value: value,
          isExpanded: true,
          hint: Text(hint),
          items: items,
          onChanged: enabled ? (val) => onChanged(val as T) : null,
        ),
      ),
    );
  }
}