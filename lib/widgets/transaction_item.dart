import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/default_category_icons.dart';
import '../models/transaction_model.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/transactions/transaction_detail_screen.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel tx;
  const TransactionItem({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currency = Provider.of<SettingsProvider>(context).selectedCurrency;
    final categoryProvider = Provider.of<CategoryProvider>(context);

    final categoryModel = categoryProvider.getCategoryById(tx.categoryId);
    final IconData? categoryIconData = availableIcons[categoryModel.iconName];
    final bool isIncome = tx.type == TransactionType.income;

    final color = isIncome ? Colors.green : Colors.red;
    final bgColor = color.withOpacity(0.12);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => TransactionDetailScreen(transaction: tx)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(categoryIconData, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryModel.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(tx.date),
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}$currency${tx.amount.toStringAsFixed(0)}',
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
