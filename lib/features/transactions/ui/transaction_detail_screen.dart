import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_snap/features/transactions/logic/transaction_provider.dart';
import 'package:wallet_snap/features/transactions/ui/add_transaction_screen.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/default_category_icons.dart';
import '../../categories/data/category_model.dart';
import '../../categories/logic/category_provider.dart';
import '../../settings/logic/settings_provider.dart';
import '../data/transaction_model.dart';


class TransactionDetailScreen extends ConsumerWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final currencySymbol = ref.watch(settingsProvider).currencySymbol;
    final transactions = ref.watch(transactionProvider);
    final currentTx = transactions.firstWhere(
          (element) => element.id == transaction.id,
      orElse: () => transaction,
    );
    final categories = ref.watch(categoryProvider);
    final category = categories.firstWhere(
          (c) => c.id == currentTx.categoryId,
      orElse: () => CategoryModel(
          id: '0',
          name: 'General',
          iconName: 'all_inclusive',
          type: CategoryType.expense
      ),
    );

    final String categoryName = category.name;
    final IconData categoryIcon = availableIcons[category.iconName] ?? Icons.category_rounded;

    final isIncome = currentTx.type == TransactionType.income;
    final amountColor = isIncome ? Colors.green.shade600 : colorScheme.error;

    Future<void> deleteTransaction() async {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Transaction?'),
          content: const Text('This action cannot be undone. Are you sure?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await ref.read(transactionProvider.notifier).deleteTransaction(currentTx.id);

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted')),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 80, width: 80,
                      decoration: BoxDecoration(
                        color: amountColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        categoryIcon,
                        color: amountColor,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      categoryName,
                      style: TextStyle(
                        fontSize: 18,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${isIncome ? '+' : '-'}$currencySymbol${currentTx.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _buildDetailsCard(currentTx, colorScheme, isIncome),
              const SizedBox(height: 40),
              _buildActionButtons(context, deleteTransaction, currentTx, colorScheme),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDetailsCard(TransactionModel currentTx, ColorScheme colorScheme, bool isIncome) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          children: [
            if (currentTx.title.isNotEmpty) ...[
              _buildInfoTile(colorScheme, Icons.title_rounded, 'Title', currentTx.title, colorScheme.primary),
              const Divider(height: 32),
            ],
            _buildInfoTile(
                colorScheme,
                Icons.swap_vert_rounded, 'Type',
                isIncome ? 'Income' : 'Expense',
                isIncome ? Colors.green : Colors.red
            ),
            const Divider(height: 32),
            _buildInfoTile(
                colorScheme,
                Icons.calendar_today_rounded, 'Date',
                DateFormat('EEEE, MMM d, yyyy').format(currentTx.date),
                colorScheme.primary
            ),
            const Divider(height: 32),
            _buildInfoTile(
                colorScheme,
                Icons.access_time_rounded, 'Time',
                DateFormat('hh:mm a').format(currentTx.date),
                Colors.orange
            ),
            if (currentTx.notes.isNotEmpty) ...[
              const Divider(height: 32),
              _buildInfoTile(colorScheme, Icons.notes_rounded, 'Notes', currentTx.notes, colorScheme.secondary),
            ],
          ],
        ),
      ),
    );
  }

  // অ্যাকশন বাটন লজিক
  Widget _buildActionButtons(BuildContext context, VoidCallback onDelete, TransactionModel currentTx, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              onPressed: onDelete,
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              color: colorScheme.error,
              isOutlined: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddTransactionScreen(transactionToEdit: currentTx),
                  ),
                );
              },
              icon: Icons.edit_rounded,
              label: 'Edit',
              color: colorScheme.primary,
              isOutlined: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(ColorScheme colorScheme, IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({required VoidCallback onPressed, required IconData icon, required String label, required Color color, required bool isOutlined}) {
    return SizedBox(
      height: 56,
      child: isOutlined
          ? OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      )
          : FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: FilledButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }
}