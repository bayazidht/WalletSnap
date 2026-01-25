import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallet_snap/features/transactions/logic/transaction_provider.dart';
import 'package:wallet_snap/features/transactions/ui/transaction_item.dart';
import '../../settings/logic/settings_provider.dart';
import '../../settings/ui/account_screen.dart';
import 'summary_card.dart';
import 'search_screen.dart';
import 'base_scaffold.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionProvider.notifier).loadLocalData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    final currency = ref.watch(settingsProvider).currency;
    final transactions = ref.watch(filteredTransactionsProvider);
    final todaySummary = ref.watch(todaySummaryProvider);
    final monthSummary = ref.watch(monthSummaryProvider);

    final double totalBalance =
        monthSummary['income']! - monthSummary['expense']!;
    final displayList = transactions.take(4).toList();

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
                style: TextStyle(fontSize: 13, color: Colors.grey),
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
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            ),
            icon: const Icon(Icons.search, size: 24),
          ),
          _buildAvatar(context, user, colorScheme),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            _buildMainBalanceCard(context, ref, totalBalance, currency),
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

            _buildRecentHeader(context, colorScheme),

            if (transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Text('No transactions found this month.'),
              )
            else
              ...displayList.map((tx) => TransactionItem(tx: tx)),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    User? user,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 20, left: 8),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AccountScreen()),
        ),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: colorScheme.primaryContainer,
          backgroundImage: user?.userMetadata?['avatar_url'] != null
              ? NetworkImage(user!.userMetadata!['avatar_url'])
              : const AssetImage('assets/images/default_user.png')
                    as ImageProvider,
        ),
      ),
    );
  }

  Widget _buildMainBalanceCard(
    BuildContext context,
    WidgetRef ref,
    double balance,
    String currency,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedDate = ref.watch(transactionProvider.notifier).selectedDate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Balance', style: TextStyle(fontSize: 15)),
              _buildDateSelector(ref, selectedDate, colorScheme),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$currency ${balance.toStringAsFixed(2)}',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTrendIndicator(),
        ],
      ),
    );
  }

  Widget _buildDateSelector(
    WidgetRef ref,
    DateTime date,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () =>
                ref.read(transactionProvider.notifier).changeMonth(-1),
            icon: const Icon(Icons.chevron_left, size: 20),
          ),
          Text(
            DateFormat('MMM yyyy').format(date),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          IconButton(
            onPressed: () =>
                ref.read(transactionProvider.notifier).changeMonth(1),
            icon: const Icon(Icons.chevron_right, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, color: Colors.greenAccent, size: 14),
          SizedBox(width: 4),
          Text('On track', style: TextStyle(fontSize: 11)),
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
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
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
          const SizedBox(height: 3),
          Align(
            alignment: Alignment.centerRight,
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

  Widget _buildRecentHeader(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(7, 20, 7, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          GestureDetector(
            onTap: () => context
                .findAncestorStateOfType<BaseScaffoldState>()
                ?.setSelectedIndex(1),
            child: Text(
              'View All',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
