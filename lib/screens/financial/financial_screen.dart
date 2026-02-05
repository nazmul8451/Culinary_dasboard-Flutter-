import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../widgets/stat_card.dart';
import '../../services/order_service.dart';
import '../../services/subscription_service.dart';

class FinancialScreen extends StatelessWidget {
  const FinancialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isNarrow = screenWidth < 1100;

        // Dynamic crossAxisCount for revenue cards
        final crossAxisCount = isMobile ? 1 : (isNarrow ? 2 : 4);

        // Adjust childAspectRatio based on columns
        final childAspectRatio = isMobile ? 2.2 : (isNarrow ? 1.4 : 1.3);

        return SingleChildScrollView(
          padding: EdgeInsets.all(
            isMobile ? AppSizes.paddingMD : AppSizes.paddingLG,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Financial Dashboard',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingSM),
              Text(
                'Monitor earnings, escrow, and payouts',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 12 : 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingXL),

              // Revenue Stats
              FutureBuilder<Map<String, dynamic>>(
                future: Future.wait([
                  OrderService.getOrderStatistics(),
                  SubscriptionService.getSubscriptionStats(),
                ]).then((results) => {...results[0], ...results[1]}),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: LinearProgressIndicator());
                  }
                  final stats = snapshot.data ?? {};
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSizes.paddingMD,
                    mainAxisSpacing: AppSizes.paddingMD,
                    childAspectRatio: childAspectRatio,
                    children: [
                      StatCard(
                        title: 'Released Revenue',
                        value:
                            '\$${(stats['releasedRevenue'] ?? 0).toStringAsFixed(2)}',
                        icon: Icons.attach_money,
                        color: AppColors.success,
                        subtitle: 'Funds cleared',
                      ),
                      StatCard(
                        title: 'Escrow Held',
                        value:
                            '\$${(stats['escrowHeld'] ?? 0).toStringAsFixed(2)}',
                        icon: Icons.account_balance_wallet,
                        color: AppColors.warning,
                        subtitle: 'Awaiting delivery',
                      ),
                      StatCard(
                        title: 'Monthly Subs',
                        value:
                            '\$${(stats['monthlyRevenue'] ?? 0).toStringAsFixed(2)}',
                        icon: Icons.card_membership,
                        color: AppColors.primary,
                        subtitle: '${stats['activeCount'] ?? 0} Active Vendors',
                      ),
                      StatCard(
                        title: 'Failed Payments',
                        value: '${stats['failedCount'] ?? 0}',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.error,
                        subtitle: 'Past Due Subs',
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: AppSizes.paddingXL),

              // Charts Row
              if (isNarrow)
                Column(
                  children: [
                    _buildRevenueChart(),
                    const SizedBox(height: AppSizes.paddingMD),
                    _buildEscrowCard(),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildRevenueChart()),
                    const SizedBox(width: AppSizes.paddingMD),
                    Expanded(child: _buildEscrowCard()),
                  ],
                ),

              const SizedBox(height: AppSizes.paddingXL),

              // Payouts & Subscriptions Section
              if (isNarrow)
                Column(
                  children: [
                    _buildPayoutsCard(isMobile),
                    const SizedBox(height: AppSizes.paddingMD),
                    _buildSubscriptionsCard(isMobile),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: _buildPayoutsCard(isMobile)),
                    const SizedBox(width: AppSizes.paddingMD),
                    Expanded(flex: 1, child: _buildSubscriptionsCard(isMobile)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionsCard(bool isSmallScreen) {
    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription Oversight',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.paddingMD),
            StreamBuilder<List<SubscriptionModel>>(
              stream: SubscriptionService.getAllSubscriptions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const CircularProgressIndicator();
                final subs = snapshot.data ?? [];
                if (subs.isEmpty)
                  return const Text('No active subscriptions found.');

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subs.length > 5 ? 5 : subs.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final sub = subs[index];
                    return ListTile(
                      title: Text(
                        sub.vendorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Next billing: ${sub.nextBillingDate.toString().split(' ')[0]}',
                      ),
                      trailing: _buildSubscriptionStatusBadge(sub.status),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionStatusBadge(SubscriptionStatus status) {
    Color color;
    switch (status) {
      case SubscriptionStatus.active:
        color = AppColors.success;
        break;
      case SubscriptionStatus.pastDue:
        color = AppColors.error;
        break;
      case SubscriptionStatus.expired:
        color = AppColors.textHint;
        break;
      case SubscriptionStatus.canceled:
        color = AppColors.error;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Overview',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingMD),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: AppColors.border, strokeWidth: 1);
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${(value / 1000).toStringAsFixed(0)}k',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < months.length) {
                            return Text(
                              months[value.toInt()],
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 8000),
                        FlSpot(1, 12000),
                        FlSpot(2, 10000),
                        FlSpot(3, 15000),
                        FlSpot(4, 18000),
                        FlSpot(5, 22000),
                      ],
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 25000,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEscrowCard() {
    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escrow Status',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingLG),
            _buildEscrowItem(
              'Total Held',
              '\$18,920',
              AppColors.warning,
              Icons.lock,
            ),
            const Divider(height: AppSizes.paddingLG),
            _buildEscrowItem(
              'Pending Release',
              '\$8,450',
              AppColors.info,
              Icons.pending,
            ),
            const Divider(height: AppSizes.paddingLG),
            _buildEscrowItem(
              'Released Today',
              '\$3,200',
              AppColors.success,
              Icons.check_circle,
            ),
            const SizedBox(height: AppSizes.paddingLG),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility),
                label: const Text('View Stripe Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSizes.paddingMD,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEscrowItem(
    String label,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingSM),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSM),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSizes.paddingMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                amount,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutsCard(bool isSmallScreen) {
    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Payouts',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'View All',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingMD),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return _buildPayoutItem(
                  'Seller ${index + 1}',
                  '\$${(500 + index * 100).toStringAsFixed(2)}',
                  index % 2 == 0 ? 'Completed' : 'Pending',
                  index % 2 == 0,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutItem(
    String name,
    String amount,
    String status,
    bool isCompleted,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: (isCompleted ? AppColors.success : AppColors.warning)
            .withOpacity(0.1),
        child: Icon(
          isCompleted ? Icons.check : Icons.pending,
          color: isCompleted ? AppColors.success : AppColors.warning,
          size: 20,
        ),
      ),
      title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      subtitle: Text(
        status,
        style: GoogleFonts.inter(
          color: isCompleted ? AppColors.success : AppColors.warning,
          fontSize: 12,
        ),
      ),
      trailing: Text(
        amount,
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
