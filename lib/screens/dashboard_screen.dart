import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/dashboard_provider.dart';
import '../utils/app_colors.dart';
import '../utils/date_formatter.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/summary_card.dart';
import '../widgets/quick_action_button.dart';
import 'add_donation_screen.dart';
import 'add_inventory_screen.dart';
import 'add_distribution_screen.dart';
import 'expiry_screen.dart';

/// Screen 2: Dashboard
/// Visually attractive dashboard with real-time KPI metrics, charts,
/// quick action buttons, and recent donation & distribution feeds.
class DashboardScreen extends StatelessWidget {
  final void Function(int index)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'FoodBridge',
        subtitle: 'Food Bank Operations Hub',
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboard, child) {
          if (dashboard.isLoading && dashboard.totalFoodItems == 0) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => dashboard.refreshDashboard(),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Welcome & Status Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1B3B2B), const Color(0xFF162D21)]
                            : [AppColors.primary, const Color(0xFF1B5E43)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Rescue & Relief Operations',
                              style: TextStyle(
                                color: Color(0xFFE8F5EC),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt, size: 14, color: Colors.amber),
                                  SizedBox(width: 4),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Empowering Zero Hunger (SDG 2)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Track stock real-time, monitor perishable expiry, and distribute food seamlessly.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Summary Cards Grid
                  const Text(
                    'Operational Metrics',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      SummaryCard(
                        title: 'Total Food Items',
                        value: '${dashboard.totalFoodItems}',
                        subtitle: 'In active registry',
                        icon: Icons.inventory_2_outlined,
                        accentColor: AppColors.info,
                        onTap: () => onNavigateTab?.call(2),
                      ),
                      SummaryCard(
                        title: 'Available Stock',
                        value: '${DateFormatter.formatQuantity(dashboard.totalAvailableStock)} kg',
                        subtitle: 'Total across items',
                        icon: Icons.scale_outlined,
                        accentColor: AppColors.primary,
                        onTap: () => onNavigateTab?.call(2),
                      ),
                      SummaryCard(
                        title: 'Total Donations',
                        value: '${dashboard.totalDonationsCount}',
                        subtitle: '${DateFormatter.formatQuantity(dashboard.totalDonationsQuantity)} units received',
                        icon: Icons.volunteer_activism_outlined,
                        accentColor: const Color(0xFFD97706),
                        onTap: () => onNavigateTab?.call(1),
                      ),
                      SummaryCard(
                        title: 'Distributed Food',
                        value: '${DateFormatter.formatQuantity(dashboard.totalFoodDistributedQuantity)}',
                        subtitle: '${dashboard.totalDistributionsCount} relief batches',
                        icon: Icons.local_shipping_outlined,
                        accentColor: const Color(0xFF7C3AED),
                        onTap: () => onNavigateTab?.call(3),
                      ),
                      SummaryCard(
                        title: 'Expiring Soon',
                        value: '${dashboard.expiringSoonCount}',
                        subtitle: dashboard.expiringSoonCount > 0 ? 'Urgent attention' : 'All safe',
                        icon: Icons.access_time_rounded,
                        accentColor: AppColors.warning,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ExpiryScreen()),
                          );
                        },
                      ),
                      SummaryCard(
                        title: 'Low Stock Items',
                        value: '${dashboard.lowStockCount}',
                        subtitle: dashboard.lowStockCount > 0 ? 'Replenish needed' : 'Well stocked',
                        icon: Icons.warning_amber_rounded,
                        accentColor: AppColors.danger,
                        onTap: () => onNavigateTab?.call(2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Quick Action Buttons
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: QuickActionButton(
                          label: 'Add Donation',
                          icon: Icons.add_circle_outline_rounded,
                          color: AppColors.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddDonationScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: QuickActionButton(
                          label: 'Add Food Item',
                          icon: Icons.post_add_rounded,
                          color: AppColors.info,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddInventoryScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: QuickActionButton(
                          label: 'Distribute Food',
                          icon: Icons.outbox_rounded,
                          color: const Color(0xFF7C3AED),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddDistributionScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: QuickActionButton(
                          label: 'View Inventory',
                          icon: Icons.format_list_bulleted_rounded,
                          color: const Color(0xFFD97706),
                          onTap: () => onNavigateTab?.call(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 4. Monthly Flow Activity Chart
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Donations vs Distributions',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () => onNavigateTab?.call(4),
                        child: const Text('Full Analytics'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  _buildMonthlyFlowChart(context, dashboard.monthlyMetrics, isDark),
                  const SizedBox(height: 28),

                  // 5. Recent Activity: Donations & Distributions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Donations',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () => onNavigateTab?.call(1),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (dashboard.recentDonations.isEmpty)
                    _buildEmptyMiniCard('No donations recorded yet.', isDark)
                  else
                    ...dashboard.recentDonations.map((d) => _buildRecentDonationTile(d, isDark)),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Distributions',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () => onNavigateTab?.call(3),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (dashboard.recentDistributions.isEmpty)
                    _buildEmptyMiniCard('No distributions recorded yet.', isDark)
                  else
                    ...dashboard.recentDistributions.map((dist) => _buildRecentDistributionTile(dist, isDark)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthlyFlowChart(BuildContext context, List<MonthlyMetric> metrics, bool isDark) {
    if (metrics.isEmpty) {
      return _buildEmptyMiniCard('No transaction trends available.', isDark);
    }

    final double maxY = metrics.fold<double>(
      20.0,
      (maxVal, m) => [maxVal, m.donationQuantity, m.distributionQuantity].reduce((a, b) => a > b ? a : b),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3D35) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLegendItem('Donations', AppColors.primary),
              const SizedBox(width: 16),
              _buildLegendItem('Distributions', const Color(0xFF7C3AED)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.15,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDark ? Colors.grey[850]! : Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final metric = metrics[groupIndex];
                      final isDonation = rodIndex == 0;
                      return BarTooltipItem(
                        '${metric.monthLabel}\n',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        children: [
                          TextSpan(
                            text: isDonation
                                ? 'Donated: ${rod.toY.toInt()} units'
                                : 'Distributed: ${rod.toY.toInt()} units',
                            style: TextStyle(
                              color: isDonation ? const Color(0xFF81C784) : const Color(0xFFB388FF),
                              fontSize: 11,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < metrics.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              metrics[idx].monthLabel.split(' ')[0],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
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
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : const Color(0xFF94A3B8),
                          ),
                        );
                      },
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
                        width: 10,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: m.distributionQuantity,
                        color: const Color(0xFF7C3AED),
                        width: 10,
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

  Widget _buildLegendItem(String label, Color color) {
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDonationTile(dynamic donation, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3D35) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation.foodItemName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'From: ${donation.donorName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${DateFormatter.formatQuantity(donation.quantity)} ${donation.unit}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormatter.format(donation.donationDate),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDistributionTile(dynamic distribution, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3D35) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Color(0xFF7C3AED),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  distribution.foodItemName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'To: ${distribution.recipientName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${DateFormatter.formatQuantity(distribution.quantityDistributed)} ${distribution.unit}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormatter.format(distribution.distributionDate),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMiniCard(String message, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3D35) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[400] : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

