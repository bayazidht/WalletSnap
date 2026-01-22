import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallet_snap/providers/transaction_provider.dart';
import 'package:wallet_snap/models/transaction_model.dart';
import 'package:wallet_snap/widgets/transaction_item.dart';

import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/pdf_service.dart';
import '../../widgets/summary_card.dart';
import '../settings/account_screen.dart';
import 'base_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final user = Supabase.instance.client.auth.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    final sortedList = List<TransactionModel>.from(
      transactionProvider.filteredTransactions,
    );
    sortedList.sort((a, b) => b.date.compareTo(a.date));
    final recentTransactions = sortedList.take(4).toList();

    Map<String, double> getFilteredSummary(
      List<TransactionModel> transactions, {
      bool today = false,
    }) {
      double income = 0.0;
      double expense = 0.0;
      final now = DateTime.now();

      for (var tx in transactions) {
        bool shouldInclude = false;
        if (today) {
          if (tx.date.year == now.year &&
              tx.date.month == now.month &&
              tx.date.day == now.day) {
            shouldInclude = true;
          }
        } else {
          if (tx.date.year == transactionProvider.selectedDate.year &&
              tx.date.month == transactionProvider.selectedDate.month) {
            shouldInclude = true;
          }
        }

        if (shouldInclude) {
          if (tx.type == TransactionType.income) {
            income += tx.amount;
          } else {
            expense += tx.amount;
          }
        }
      }
      return {'income': income, 'expense': expense};
    }

    final todaySummary = getFilteredSummary(
      transactionProvider.filteredTransactions,
      today: true,
    );
    final monthSummary = getFilteredSummary(
      transactionProvider.filteredTransactions,
      today: false,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good morning,',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                user?.userMetadata?['full_name']?.split(' ')[0] ?? 'WalletSnap',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(onPressed: ()  {}, icon: Icon(Icons.search, size: 24)),
          IconButton(onPressed: () async {
            final String date = DateFormat('MMMM yyyy').format(transactionProvider.selectedDate);
            await PdfService.generateTransactionReport(sortedList, categoryProvider.categories, date);
          }, icon: Icon(Icons.print_outlined, size: 24)),
          Padding(
            padding: const EdgeInsets.only(right: 20, left: 8),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountScreen(),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage: user?.userMetadata?['avatar_url'] != null
                    ? NetworkImage(user!.userMetadata!['avatar_url'])
                    : const AssetImage('assets/images/default_user.png') as ImageProvider,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 10),

            _buildMainBalanceCard(context, transactionProvider),

            const SizedBox(height: 20),
            _buildAIInsightCard(context, colorScheme),

            const SizedBox(height: 25),
            SummaryCard(
              title: "Today's Summary",
              income: todaySummary['income']!,
              expense: todaySummary['expense']!,
            ),
            SummaryCard(
              title: "This Month",
              income: monthSummary['income']!,
              expense: monthSummary['expense']!,
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 20, 7, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      final BaseScaffoldState? baseScaffoldState = context
                          .findAncestorStateOfType<BaseScaffoldState>();
                      baseScaffoldState?.setSelectedIndex(1);
                    },
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (transactionProvider.filteredTransactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No transactions found.'),
                ),
              )
            else
              ...recentTransactions.map(
                (tx) => TransactionItem(tx: tx),
              ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildMainBalanceCard(
    BuildContext context,
    TransactionProvider provider,
  ) {
    final currency = Provider.of<SettingsProvider>(context).selectedCurrency;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(28)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: TextStyle(
                  color: colorScheme.primary.withValues(alpha: 0.7),
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => provider.changeMonth(-1),
                      icon: Icon(
                        Icons.chevron_left,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    Text(
                      DateFormat('MMM yyyy').format(provider.selectedDate),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => provider.changeMonth(1),
                      icon: Icon(
                        Icons.chevron_right,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$currency ${provider.totalBalance.toStringAsFixed(2)}',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.trending_up,
                  color: Colors.greenAccent,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '+12% vs last month',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightCard(BuildContext context, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI INSIGHT',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your spending is 12% lower this month. Great job managing your Food & Dining expenses!',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              iconAlignment: IconAlignment.end,
              onPressed: () {
                final BaseScaffoldState? baseScaffoldState = context
                    .findAncestorStateOfType<BaseScaffoldState>();
                baseScaffoldState?.setSelectedIndex(2);
              },
              label: const Text('View Details'),
              icon: const Icon(Icons.chevron_right, size: 18),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
