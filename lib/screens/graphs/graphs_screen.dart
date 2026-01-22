import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:wallet_snap/providers/category_provider.dart';
import 'package:wallet_snap/providers/transaction_provider.dart';
import '../../data/default_category_icons.dart';
import '../../providers/settings_provider.dart';
import '../../services/pdf_service.dart';

class GraphsScreen extends StatelessWidget {
  const GraphsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final chartData = transactionProvider.getChartData(context);
    final currency = Provider.of<SettingsProvider>(context).selectedCurrency;
    final colorScheme = Theme.of(context).colorScheme;

    final categoryExpenses =
        chartData['categoryExpenses'] as Map<String, Map<String, dynamic>>;
    final totalExpense = chartData['totalExpense'] as double;
    final dailySummary =
        chartData['dailySummary'] as Map<String, Map<String, double>>;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: () async {
                final String date = DateFormat(
                  'MMMM yyyy',
                ).format(transactionProvider.selectedDate);
                await PdfService.generateTransactionReport(
                  transactionProvider.filteredTransactions,
                  categoryProvider.categories,
                  date,
                );
              },
              icon: const Icon(Icons.print, size: 18),
              label: const Text(
                "Export",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildAIInsightCard(colorScheme, totalExpense, currency),
            const SizedBox(height: 30),
            _buildSectionHeader(colorScheme, 'Spending Analysis'),
            _buildChartContainer(
              colorScheme,
              child: Column(
                children: [
                  _buildPieChart(
                    context,
                    categoryExpenses,
                    totalExpense,
                    currency,
                  ),
                  const SizedBox(height: 30),
                  _buildLegend(context, categoryExpenses, totalExpense),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionHeader(colorScheme, 'Monthly Flow Analysis'),
            _buildChartContainer(
              colorScheme,
              child: _buildDailyGraph(context, dailySummary, currency),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(
    BuildContext context,
    Map<String, Map<String, dynamic>> categoryExpenses,
    double totalExpense,
    String currency,
  ) {
    if (categoryExpenses.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text('No Data')));
    }
    final colorScheme = Theme.of(context).colorScheme;
    final List<Color> colorPalette = [
      colorScheme.primary,
      colorScheme.tertiary,
      colorScheme.secondary,
      colorScheme.error,
      Colors.cyan,
      Colors.orange,
    ];

    int i = 0;
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 75,
              sections: categoryExpenses.entries.map((entry) {
                final color = colorPalette[i++ % colorPalette.length];
                final double value = entry.value['amount'];
                return PieChartSectionData(
                  color: color,
                  value: value,
                  radius: 18,
                  showTitle: false,
                );
              }).toList(),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Spent',
                style: TextStyle(
                  color: colorScheme.outline,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$currency${totalExpense.toStringAsFixed(0)}',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(
    BuildContext context,
    Map<String, Map<String, dynamic>> categoryExpenses,
    double totalExpense,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final List<Color> colorPalette = [
      colorScheme.primary,
      colorScheme.tertiary,
      colorScheme.secondary,
      colorScheme.error,
      Colors.cyan,
      Colors.orange,
    ];

    int i = 0;
    return Column(
      children: categoryExpenses.entries.map((entry) {
        final color = colorPalette[i++ % colorPalette.length];
        final String categoryName = entry.key;
        final double amount = entry.value['amount'];
        final String iconKey = entry.value['icon'];

        final percentage = totalExpense > 0 ? (amount / totalExpense) : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      availableIcons[iconKey] ?? Icons.category_rounded,
                      size: 18,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      categoryName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: colorScheme.outline,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: color.withValues(alpha: 0.1),
                  color: color,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(ColorScheme colorScheme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildChartContainer(
    ColorScheme colorScheme, {
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
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
      child: child,
    );
  }

  Widget _buildAIInsightCard(
    ColorScheme colorScheme,
    double totalExpense,
    String currency,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI INSIGHT',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your spending is 12% lower than last month. Keep it up!',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.9),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGraph(
    BuildContext context,
    Map<String, Map<String, double>> dailySummary,
    String currency,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (dailySummary.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data found')),
      );
    }

    final days = dailySummary.keys.toList()..sort();
    final double maxVal = _calculateMaxY(dailySummary, days);

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (spot) => colorScheme.surfaceContainerHigh,
                  tooltipBorderRadius: BorderRadius.circular(12),
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      return LineTooltipItem(
                        '$currency${barSpot.y.toInt()}',
                        TextStyle(
                          color: barSpot.bar.color ?? colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxVal / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.1),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      _formatAmount(value),
                      style: TextStyle(
                        color: colorScheme.outline,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 3,
                    getTitlesWidget: (val, meta) {
                      int index = val.toInt();
                      if (index < 0 || index >= days.length)
                        return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          days[index],
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(days.length, (i) {
                    return FlSpot(
                      i.toDouble(),
                      dailySummary[days[i]]!['income'] ?? 0,
                    );
                  }),
                  isCurved: true,
                  color: colorScheme.primary,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: colorScheme.primary,
                        ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.2),
                        colorScheme.primary.withValues(alpha: 0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                LineChartBarData(
                  spots: List.generate(days.length, (i) {
                    return FlSpot(
                      i.toDouble(),
                      dailySummary[days[i]]!['expense'] ?? 0,
                    );
                  }),
                  isCurved: true,
                  color: colorScheme.error,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: colorScheme.error,
                        ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.error.withValues(alpha: 0.2),
                        colorScheme.error.withValues(alpha: 0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Dates with Transactions",
          style: TextStyle(
            color: colorScheme.outline,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  double _calculateMaxY(
    Map<String, Map<String, double>> summary,
    List<String> keys,
  ) {
    double max = 0;
    for (var key in keys) {
      double inc = summary[key]?['income'] ?? 0;
      double exp = summary[key]?['expense'] ?? 0;
      if (inc > max) max = inc;
      if (exp > max) max = exp;
    }
    return max == 0 ? 100 : max * 1.2;
  }

  String _formatAmount(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }
}
