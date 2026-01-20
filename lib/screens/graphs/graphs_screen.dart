import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:wallet_snap/providers/transaction_provider.dart';

import '../../providers/settings_provider.dart';

class GraphsScreen extends StatelessWidget {
  const GraphsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final chartData = transactionProvider.getChartData(context);
    final currency = Provider.of<SettingsProvider>(context).selectedCurrency;
    final colorScheme = Theme.of(context).colorScheme;

    final categoryExpenses = chartData['categoryExpenses'] as Map<String, double>;
    final totalExpense = chartData['totalExpense'] as double;
    final monthlySummary = chartData['monthlySummary'] as Map<String, Map<String, double>>;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold))
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildAIInsightCard(colorScheme, totalExpense, currency),
            const SizedBox(height: 30),

            _buildSectionHeader(colorScheme, 'Spending Habits'),
            const SizedBox(height: 12),

            _buildChartContainer(
              colorScheme,
              child: Column(
                children: [
                  _buildPieChart(context, categoryExpenses, totalExpense),
                  const SizedBox(height: 20),
                  _buildPieChartLegend(context, categoryExpenses),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildSectionHeader(colorScheme, 'Cash Flow History'),
            const SizedBox(height: 12),
            _buildChartContainer(
              colorScheme,
              child: _buildBarChart(context, monthlySummary, currency),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ColorScheme colorScheme, String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
    );
  }

  Widget _buildChartContainer(ColorScheme colorScheme, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: child,
    );
  }

  Widget _buildAIInsightCard(ColorScheme colorScheme, double totalExpense, String currency) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('AI INSIGHT', style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your spending is 12% lower than last month. Keep it up!',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, Map<String, double> categoryExpenses, double totalExpense) {
    if (categoryExpenses.isEmpty) return const SizedBox(height: 200, child: Center(child: Text('No Data')));

    final colorPalette = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.error,
      Colors.cyan, Colors.amber, Colors.purple,
    ];

    int i = 0;
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 50,
          sections: categoryExpenses.entries.map((entry) {
            final color = colorPalette[i++ % colorPalette.length];
            return PieChartSectionData(
              color: color,
              value: entry.value,
              radius: 20,
              showTitle: false,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPieChartLegend(BuildContext context, Map<String, double> categoryExpenses) {
    return Wrap(
      spacing: 16,
      runSpacing: 10,
      children: categoryExpenses.entries.map((e) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blue)),
          const SizedBox(width: 6),
          Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      )).toList(),
    );
  }

  Widget _buildBarChart(BuildContext context, Map<String, Map<String, double>> monthlySummary, String currency) {
    final colorScheme = Theme.of(context).colorScheme;
    if (monthlySummary.isEmpty) return const SizedBox(height: 200, child: Center(child: Text('No Data')));

    final lastSixMonths = monthlySummary.keys.toList().reversed.take(6).toList().reversed.toList();

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        if (val < 0 || val >= lastSixMonths.length) return const SizedBox();
                        return Text(lastSixMonths[val.toInt()].split('-')[1], style: const TextStyle(fontSize: 10));
                      }
                  )
              )
          ),
          barGroups: List.generate(lastSixMonths.length, (i) {
            final data = monthlySummary[lastSixMonths[i]]!;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(toY: data['income'] ?? 0, color: colorScheme.primary, width: 8, borderRadius: BorderRadius.circular(4)),
                BarChartRodData(toY: data['expense'] ?? 0, color: colorScheme.error.withOpacity(0.7), width: 8, borderRadius: BorderRadius.circular(4)),
              ],
            );
          }),
        ),
      ),
    );
  }
}