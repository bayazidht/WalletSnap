import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/default_category_icons.dart';
import '../../categories/data/category_model.dart';
import '../../categories/logic/category_provider.dart';
import '../../settings/logic/settings_provider.dart';
import '../data/transaction_model.dart';
import 'transaction_detail_screen.dart';

class TransactionItem extends ConsumerWidget {
  final TransactionModel tx;
  const TransactionItem({super.key, required this.tx});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final currencySymbol = ref.watch(settingsProvider).currencySymbol;
    final categories = ref.watch(categoryProvider);

    final categoryModel = categories.firstWhere(
      (c) => c.id == tx.categoryId,
      orElse: () => categories.isNotEmpty
          ? categories.first
          : CategoryModel(
              id: '0',
              name: 'General',
              iconName: 'all_inclusive',
              type: CategoryType.expense,
            ),
    );
    final IconData? categoryIcon = availableIcons[categoryModel.iconName];
    final bool isIncome = tx.type == TransactionType.income;
    final color = isIncome ? Colors.green : colorScheme.error;
    final bgColor = color.withValues(alpha: 0.1);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(transaction: tx),
          ),
        );
      },
      borderRadius: BorderRadius.circular(25),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  categoryIcon ?? Icons.category_rounded,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title.isNotEmpty ? tx.title : categoryModel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tx.title.isNotEmpty
                          ? categoryModel.name
                          : "at ${DateFormat('hh:mm a').format(tx.date)}",
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // অ্যামাউন্ট এবং সময়
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}$currencySymbol${tx.amount.toStringAsFixed(tx.amount % 1 == 0 ? 0 : 2)}',
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (tx.title.isNotEmpty)
                    Text(
                      DateFormat('hh:mm a').format(tx.date),
                      style: TextStyle(
                        color: colorScheme.outline,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
