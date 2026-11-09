import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/dashboard_provider.dart';
import '../utils/app_colors.dart';
import '../utils/date_formatter.dart';
import '../widgets/custom_app_bar.dart';

/// Screen 7: Reports and Analytics
/// Comprehensive visual performance analytics grounded entirely on real SQLite data.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _touchedPieIndex = -1;

  Color _getCategoryColor(int index) {
    const colors = [
      AppColors.primary,
      Color(0xFF7C3AED),
      Color(0xFFD97706),
      Color(0xFF0284C7),
      Color(0xFF16A34A),
      Color(0xFFEA580C),
      Color(0xFF475569),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Reports & Analytics',
        subtitle: 'Food Bank Operations Impact',
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboard, child) {
          final totalReceived = dashboard.totalDonationsQuantity;
          final totalDistributed = dashboard.totalFoodDistributedQuantity;
          final remainingStock = dashboard.totalAvailableStock;

          // Efficiency Rate = (Distributed / Received) * 100
          final double distributionRate = totalReceived > 0
              ? ((totalDistributed / totalReceived) * 100).clamp(0.0, 100.0)
              : 0.0;

          return RefreshIndicator(
            onRefresh: () => dashboard.refreshDashboard(),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Executive Impact Overview Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1A3326), const Color(0xFF14241C)]
                            : [AppColors.primaryDark, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Zero Hunger Relief Ratio',
                          style: TextStyle(color: Color(0xFFE8F5EC), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${distributionRate.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Food Redistribution Rate',
                              style: TextStyle(color: Color(0xFFD1E7DD), fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: distributionRate / 100.0,
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF81C784)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Calculated as Total Food Distributed (${DateFormatter.formatQuantity(totalDistributed)}) '
                          'over Total Received Donations (${DateFormatter.formatQuantity(totalReceived)}).',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Metrics Summary Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          'Total Received',
                          '${DateFormatter.formatQuantity(totalReceived)}',
                          'From ${dashboard.totalDonationsCount} donations',
                          Icons.arrow_downward_rounded,
                          AppColors.primary,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          'Total Distributed',
                          '${DateFormatter.formatQuantity(totalDistributed)}',
                          'Across ${dashboard.totalDistributionsCount} batches',
                          Icons.arrow_upward_rounded,
                          const Color(0xFF7C3AED),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          'Remaining Stock',
                          '${DateFormatter.formatQuantity(remainingStock)}',
                          'Across ${dashboard.totalFoodItems} food items',
                          Icons.warehouse_outlined,
                          const Color(0xFFD97706),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          'Expiring / Low',
                          '${dashboard.expiringSoonCount + dashboard.lowStockCount}',
                          'Items needing attention',
                          Icons.warning_amber_rounded,
                          AppColors.danger,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 3. Monthly Trend Flow (fl_chart BarChart)
                  const Text(
                    'Monthly Food Flow Comparison',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tracks incoming donations vs outgoing community distributions over 6 months.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildMonthlyBarChart(dashboard.monthlyMetrics, isDark),
                  const SizedBox(height: 28),

                  // 4. Food Category Distribution (fl_chart PieChart)
                  const Text(
                    'Inventory Breakdown by Category',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Proportion of food types currently preserved in the warehouse.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildCategoryPieChart(dashboard.categoryMetrics, isDark),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricTile(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3D35) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBarChart(List<dynamic> metrics, bool isDark) {
    if (metrics.isEmpty) {
      return const Center(child: Text('No monthly data recorded yet.'));
    }

    final double maxY = metrics.fold<double>(
      25.0,
      (maxVal, m) => [maxVal, (m.donationQuantity as double), (m.distributionQuantity as double)]
          .reduce((a, b) => a > b ? a : b),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3D35) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLegend('Donations', AppColors.primary),
              const SizedBox(width: 14),
              _buildLegend('Distributions', const Color(0xFF7C3AED)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 210,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.15,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < metrics.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              metrics[idx].monthLabel.split(' ')[0],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, _) => Text(
                        val.toInt().toString(),
                        style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.grey),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark ? const Color(0xFF2E3D35) : const Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(metrics.length, (i) {
                  final m = metrics[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: m.donationQuantity,
                        color: AppColors.primary,
                        width: 11,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: m.distributionQuantity,
                        color: const Color(0xFF7C3AED),
                        width: 11,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChart(List<dynamic> categories, bool isDark) {
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text('No category data available.'),
      );
    }

    final double totalStock = categories.fold<double>(
      0.0,
      (sum, c) => sum + (c.totalQuantity as double),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3D35) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedPieIndex = -1;
                        return;
                      }
                      _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: List.generate(categories.length, (i) {
                  final cat = categories[i];
                  final isTouched = i == _touchedPieIndex;
                  final double percentage = totalStock > 0 ? (cat.totalQuantity / totalStock) * 100 : 0.0;
                  final radius = isTouched ? 65.0 : 55.0;

                  return PieChartSectionData(
                    color: _getCategoryColor(i),
                    value: cat.totalQuantity > 0 ? cat.totalQuantity : 1.0,
                    title: '${percentage.toInt()}%',
                    radius: radius,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend List
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List.generate(categories.length, (i) {
              final cat = categories[i];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(i),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${cat.category} (${DateFormatter.formatQuantity(cat.totalQuantity)})',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

