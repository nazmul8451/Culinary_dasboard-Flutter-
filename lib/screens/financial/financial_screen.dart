import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:html' as html;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../widgets/stat_card.dart';
import '../../services/order_service.dart';
import '../../services/subscription_service.dart';
import '../../core/utils/animations.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../models/order_model.dart';

import '../../widgets/shimmer_loading.dart';

class FinancialScreen extends StatelessWidget {
  const FinancialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isNarrow = screenWidth < 1100;

        return FutureBuilder<Map<String, dynamic>>(
          future:
              Future.wait([
                OrderService.getOrderStatistics(),
                SubscriptionService.getSubscriptionStats(),
                OrderService.getMonthlyRevenue(),
              ]).then(
                (results) => {
                  ...results[0] as Map,
                  ...results[1] as Map,
                  'chartData': results[2] as List<double>,
                },
              ),
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final stats = snapshot.data ?? {};
            final crossAxisCount = isMobile ? 1 : (isNarrow ? 2 : 4);
            final childAspectRatio = isMobile ? 2.2 : (isNarrow ? 1.7 : 1.8);

            return ShimmerSwitcher(
              isLoading: isLoading,
              skeleton: _buildShimmerLoading(isMobile, isNarrow),
              child: SingleChildScrollView(
                key: const ValueKey('content'),
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
                    ).animateFadeInUp(),
                    const SizedBox(height: AppSizes.paddingSM),
                    Text(
                      'Monitor earnings, escrow, and payouts',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : 14,
                        color: AppColors.textSecondary,
                      ),
                    ).animateFadeInUp(delay: 100),
                    const SizedBox(height: AppSizes.paddingXL),

                    // Revenue Stats
                    GridView.count(
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
                        ).animateStaggered(0),
                        StatCard(
                          title: 'Escrow Held',
                          value:
                              '\$${(stats['escrowHeld'] ?? 0).toStringAsFixed(2)}',
                          icon: Icons.account_balance_wallet,
                          color: AppColors.warning,
                          subtitle: 'Awaiting delivery',
                        ).animateStaggered(1),
                        StatCard(
                          title: 'Monthly Subs',
                          value:
                              '\$${(stats['monthlyRevenue'] ?? 0).toStringAsFixed(2)}',
                          icon: Icons.card_membership,
                          color: AppColors.primary,
                          subtitle:
                              '${stats['activeCount'] ?? 0} Active Vendors',
                        ).animateStaggered(2),
                        StatCard(
                          title: 'Admin Commission',
                          value:
                              '\$${(stats['adminCommission'] ?? 0).toStringAsFixed(2)}',
                          icon: Icons.account_balance_rounded,
                          color: AppColors.error,
                          subtitle: '10% order cut',
                        ).animateStaggered(3),
                      ],
                    ),

                    const SizedBox(height: AppSizes.paddingXL),

                    // Charts Row
                    if (isNarrow)
                      Column(
                        children: [
                          _buildRevenueChart(stats['chartData'] ?? []),
                          const SizedBox(height: AppSizes.paddingMD),
                          _buildEscrowCard(stats),
                        ],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildRevenueChart(
                              stats['chartData'] ?? [],
                            ).animateFadeInUp(delay: 200),
                          ),
                          const SizedBox(width: AppSizes.paddingMD),
                          Expanded(
                            child: _buildEscrowCard(
                              stats,
                            ).animateSlideInRight(delay: 300),
                          ),
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
                          Expanded(
                            flex: 1,
                            child: _buildSubscriptionsCard(isMobile),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubscriptionsCard(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSubscriptionStatusBadge(sub.status),
                          if (sub.status == SubscriptionStatus.pastDue ||
                              sub.status == SubscriptionStatus.canceled) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.block,
                                color: AppColors.error,
                                size: 20,
                              ),
                              tooltip: 'Suspend Vendor',
                              onPressed: () =>
                                  _suspendVendorForNonPayment(context, sub),
                            ),
                          ],
                        ],
                      ),
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

  Widget _buildRevenueChart(List<double> monthlyRevenue) {
    final now = DateTime.now();
    final months = [];
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      months.add(
        [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ][d.month - 1],
      );
    }

    double maxVal = 1000;
    for (var val in monthlyRevenue) {
      if (val > maxVal) maxVal = val;
    }
    maxVal = (maxVal / 1000).ceil() * 1000.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
                    horizontalInterval: maxVal / 5,
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
                            '\$${(value / 1000).toStringAsFixed(1)}k',
                            style: GoogleFonts.inter(
                              fontSize: 10,
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
                          if (value.toInt() >= 0 &&
                              value.toInt() < months.length) {
                            return Text(
                              months[value.toInt()],
                              style: GoogleFonts.inter(
                                fontSize: 10,
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
                      spots: monthlyRevenue.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value);
                      }).toList(),
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
                  maxY: maxVal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEscrowCard(Map<String, dynamic> stats) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
              '\$${(stats['escrowHeld'] ?? 0).toStringAsFixed(2)}',
              AppColors.warning,
              Icons.lock,
            ),
            const Divider(height: AppSizes.paddingLG),
            _buildEscrowItem(
              'Pending Release',
              '\$${(stats['pendingRelease'] ?? 0).toStringAsFixed(2)}',
              AppColors.info,
              Icons.pending,
            ),
            const Divider(height: AppSizes.paddingLG),
            _buildEscrowItem(
              'Released Total',
              '\$${(stats['releasedRevenue'] ?? 0).toStringAsFixed(2)}',
              AppColors.success,
              Icons.check_circle,
            ),
            const SizedBox(height: AppSizes.paddingLG),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  const url =
                      'https://dashboard.stripe.com/acct_1C4VxjLWripuEZOe/dashboard';
                  html.window.open(url, '_blank');
                },
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
            StreamBuilder<List<OrderModel>>(
              stream: OrderService.getAllOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());

                final allOrders = snapshot.data ?? [];
                // Filter for delivered or released orders which represent "payouts"
                final payouts = allOrders
                    .where(
                      (o) =>
                          o.status == OrderStatus.delivered ||
                          o.escrowStatus == EscrowStatus.released,
                    )
                    .toList();

                if (payouts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSizes.paddingMD),
                    child: Text('No recent payouts found.'),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payouts.length > 5 ? 5 : payouts.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final order = payouts[index];
                    return _buildPayoutItem(
                      order.sellerName,
                      '\$${order.grandTotal.toStringAsFixed(2)}',
                      order.escrowStatus == EscrowStatus.released
                          ? 'Completed'
                          : 'Pending',
                      order.escrowStatus == EscrowStatus.released,
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

  Future<void> _suspendVendorForNonPayment(
    BuildContext context,
    SubscriptionModel sub,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Vendor?'),
        content: Text(
          'Are you sure you want to suspend "${sub.vendorName}" for non-payment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await UserService.updateUserStatus(sub.vendorId, UserStatus.suspended);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vendor suspended successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error suspending vendor: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildShimmerLoading(bool isMobile, bool isNarrow) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isMobile ? AppSizes.paddingMD : AppSizes.paddingLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading.rounded(height: 30, width: 250),
          const SizedBox(height: AppSizes.paddingSM),
          ShimmerLoading.rounded(height: 15, width: 200),
          const SizedBox(height: AppSizes.paddingXL),
          GridView.count(
            crossAxisCount: isMobile ? 1 : (isNarrow ? 2 : 4),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSizes.paddingMD,
            mainAxisSpacing: AppSizes.paddingMD,
            childAspectRatio: isMobile ? 2.2 : (isNarrow ? 1.7 : 1.8),
            children: List.generate(
              4,
              (index) => ShimmerLoading.rounded(height: 100),
            ),
          ),
          const SizedBox(height: AppSizes.paddingXL),
          if (isNarrow)
            Column(
              children: [
                ShimmerLoading.rounded(height: 300),
                const SizedBox(height: AppSizes.paddingMD),
                ShimmerLoading.rounded(height: 300),
              ],
            )
          else
            Row(
              children: [
                Expanded(flex: 2, child: ShimmerLoading.rounded(height: 350)),
                const SizedBox(width: AppSizes.paddingMD),
                Expanded(child: ShimmerLoading.rounded(height: 350)),
              ],
            ),
          const SizedBox(height: AppSizes.paddingXL),
          Row(
            children: [
              Expanded(child: ShimmerLoading.rounded(height: 400)),
              if (!isNarrow) const SizedBox(width: AppSizes.paddingMD),
              if (!isNarrow)
                Expanded(child: ShimmerLoading.rounded(height: 400)),
            ],
          ),
        ],
      ),
    );
  }
}
