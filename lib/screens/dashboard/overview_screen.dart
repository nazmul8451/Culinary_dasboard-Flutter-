import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../widgets/stat_card.dart';
import '../../models/user_model.dart';
import '../../models/order_model.dart';
import '../../services/user_service.dart';
import '../../services/order_service.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/order_details_dialog.dart';
import '../../core/utils/animations.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isNarrow = screenWidth < 1100;

        // Dynamic crossAxisCount for statistics cards
        final crossAxisCount = isMobile ? 1 : (isNarrow ? 2 : 4);

        // Adjust childAspectRatio based on columns
        // Decreasing ratio makes cards taller to prevent overflow
        final childAspectRatio = isMobile ? 2.0 : (isNarrow ? 1.7 : 1.8);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Overview',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ).animateFadeInUp(),
              const SizedBox(height: AppSizes.paddingSM),
              Text(
                'Welcome back! Here\'s what\'s happening with your platform.',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 12 : 14,
                  color: AppColors.textSecondary,
                ),
              ).animateFadeInUp(delay: 100),
              const SizedBox(height: AppSizes.paddingXL),

              // User Statistics Cards
              FutureBuilder<Map<String, int>>(
                future: UserService.getUserStatistics(),
                builder: (context, snapshot) {
                  final stats =
                      snapshot.data ??
                      {'total': 0, 'buyers': 0, 'sellers': 0, 'couriers': 0};

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSizes.paddingMD,
                    mainAxisSpacing: AppSizes.paddingMD,
                    childAspectRatio: childAspectRatio,
                    children: [
                      StatCard(
                        title: 'Total Users',
                        value: stats['total'].toString(),
                        icon: Icons.people,
                        color: AppColors.primary,
                        percentageChange: 12.5,
                      ).animateStaggered(0),
                      StatCard(
                        title: 'Buyers',
                        value: stats['buyers'].toString(),
                        icon: Icons.shopping_cart,
                        color: AppColors.secondary,
                      ).animateStaggered(1),
                      StatCard(
                        title: 'Sellers',
                        value: stats['sellers'].toString(),
                        icon: Icons.store,
                        color: AppColors.success,
                      ).animateStaggered(2),
                      StatCard(
                        title: 'Couriers',
                        value: stats['couriers'].toString(),
                        icon: Icons.delivery_dining,
                        color: AppColors.warning,
                      ).animateStaggered(3),
                    ],
                  );
                },
              ),

              const SizedBox(height: AppSizes.paddingXL),

              // Order Statistics
              FutureBuilder<Map<String, dynamic>>(
                future: OrderService.getOrderStatistics(),
                builder: (context, snapshot) {
                  final stats =
                      snapshot.data ??
                      {'total': 0, 'pending': 0, 'onTheWay': 0, 'delivered': 0};

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSizes.paddingMD,
                    mainAxisSpacing: AppSizes.paddingMD,
                    childAspectRatio: childAspectRatio,
                    children: [
                      StatCard(
                        title: 'Total Orders',
                        value: stats['total'].toString(),
                        icon: Icons.shopping_bag,
                        color: AppColors.primary,
                        percentageChange: 8.3,
                      ).animateStaggered(0),
                      StatCard(
                        title: 'Pending',
                        value: stats['pending'].toString(),
                        icon: Icons.pending,
                        color: AppColors.warning,
                      ).animateStaggered(1),
                      StatCard(
                        title: 'On The Way',
                        value: stats['onTheWay'].toString(),
                        icon: Icons.local_shipping,
                        color: AppColors.info,
                      ).animateStaggered(2),
                      StatCard(
                        title: 'Delivered',
                        value: stats['delivered'].toString(),
                        icon: Icons.check_circle,
                        color: AppColors.success,
                      ).animateStaggered(3),
                    ],
                  );
                },
              ),

              const SizedBox(height: AppSizes.paddingXL),

              // Recent Activity Section
              if (isNarrow)
                Column(
                  children: [
                    _buildRecentOrdersCard(),
                    const SizedBox(height: AppSizes.paddingMD),
                    _buildPendingVerificationsCard(),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildRecentOrdersCard().animateSlideInRight(
                        delay: 400,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMD),
                    Expanded(
                      child: _buildPendingVerificationsCard()
                          .animateSlideInRight(delay: 500),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentOrdersCard() {
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
                  'Recent Orders',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Get.find<DashboardController>().changeRoute('/orders'),
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
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingLG),
                      child: Text(
                        'Error loading orders: ${snapshot.error}',
                        style: GoogleFonts.inter(color: AppColors.error),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSizes.paddingLG),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final orders = snapshot.data?.take(5).toList() ?? [];

                if (orders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingXL),
                      child: Text(
                        'No recent orders',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return ListTile(
                      onTap: () => showDialog(
                        context: context,
                        builder: (context) => OrderDetailsDialog(order: order),
                      ),
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(
                          order.status,
                        ).withOpacity(0.1),
                        child: Icon(
                          Icons.shopping_bag,
                          color: _getStatusColor(order.status),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        order.buyerName,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '\$${order.grandTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingSM,
                          vertical: AppSizes.paddingXS,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusXS,
                          ),
                        ),
                        child: Text(
                          _getStatusText(order.status),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(order.status),
                          ),
                        ),
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

  Widget _buildPendingVerificationsCard() {
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
                  'Pending Verifications',
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
            StreamBuilder<List<UserModel>>(
              stream: UserService.getAllUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final pendingUsers = snapshot.data!
                    .where(
                      (user) =>
                          user.verificationStatus == VerificationStatus.pending,
                    )
                    .take(5)
                    .toList();

                if (pendingUsers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingXL),
                      child: Text(
                        'No pending verifications',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingUsers.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = pendingUsers[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.warning.withOpacity(0.1),
                        child: Icon(
                          user.userType == UserType.seller
                              ? Icons.store
                              : Icons.delivery_dining,
                          color: AppColors.warning,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        user.name,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        user.userType.name.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textHint,
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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
      case OrderStatus.preparing:
        return AppColors.info;
      case OrderStatus.onTheWay:
        return AppColors.secondary;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.onTheWay:
        return 'On The Way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}
