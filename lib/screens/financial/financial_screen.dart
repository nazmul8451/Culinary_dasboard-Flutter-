import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../widgets/stat_card.dart';

class FinancialScreen extends StatelessWidget {
  const FinancialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final isMediumScreen = MediaQuery.of(context).size.width < 900;

    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isSmallScreen ? AppSizes.paddingMD : AppSizes.paddingLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (!isSmallScreen) ...[
            Text(
              'Financial Dashboard',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSM),
            Text(
              'Monitor earnings, escrow, and payouts',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingXL),
          ],

          // Revenue Stats
          GridView.count(
            crossAxisCount: isSmallScreen ? 1 : (isMediumScreen ? 2 : 4),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSizes.paddingMD,
            mainAxisSpacing: AppSizes.paddingMD,
            childAspectRatio: isSmallScreen ? 2.5 : 1.5,
            children: const [
              StatCard(
                title: 'Total Earnings',
                value: '\$45,230',
                icon: Icons.attach_money,
                color: AppColors.success,
                percentageChange: 15.3,
                subtitle: 'This month',
              ),
              StatCard(
                title: 'Subscriptions',
                value: '\$12,450',
                icon: Icons.card_membership,
                color: AppColors.primary,
                percentageChange: 8.2,
                subtitle: 'Active subscriptions',
              ),
              StatCard(
                title: 'Commissions',
                value: '\$32,780',
                icon: Icons.trending_up,
                color: AppColors.secondary,
                percentageChange: 12.5,
                subtitle: 'From orders',
              ),
              StatCard(
                title: 'Escrow Balance',
                value: '\$18,920',
                icon: Icons.account_balance_wallet,
                color: AppColors.warning,
                subtitle: 'Held in Stripe',
              ),
            ],
          ),

          const SizedBox(height: AppSizes.paddingXL),

          // Charts Row
          if (isSmallScreen)
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

          // Payouts Table
          _buildPayoutsCard(isSmallScreen),
        ],
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
