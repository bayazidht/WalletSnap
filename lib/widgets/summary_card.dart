import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final double income;
  final double expense;

  const SummaryCard({super.key, required this.title, required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final currency = Provider.of<SettingsProvider>(context).selectedCurrency;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(100)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withAlpha(200),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildSummaryItem(
                context,
                label: "Income",
                amount: "+ $currency${income.toStringAsFixed(0)}",
                color: Colors.green.shade600,
                isIncome: true,
              ),
              Container(
                height: 40,
                width: 1,
                color: colorScheme.outlineVariant.withAlpha(100),
              ),
              _buildSummaryItem(
                context,
                label: "Expense",
                amount: "- $currency${expense.toStringAsFixed(0)}",
                color: Colors.red.shade600,
                isIncome: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context,
      {required String label, required String amount, required Color color, required bool isIncome}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}