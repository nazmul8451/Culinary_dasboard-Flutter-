import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../widgets/stat_card.dart';
import '../../models/user_model.dart';
import '../../models/order_model.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title
          Text(
            'Dashboard Overview',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.paddingSM),
          Text(
            'Welcome back! Here\'s what\'s happening with your platform.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.paddingXL),

          // Statistics Cards
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              final totalUsers = snapshot.data?.docs.length ?? 0;
              final buyers =
                  snapshot.data?.docs
                      .where(
                        (doc) => (doc.data() as Map)['userType'] == 'buyer',
                      )
                      .length ??
                  0;
              final sellers =
                  snapshot.data?.docs
                      .where(
                        (doc) => (doc.data() as Map)['userType'] == 'seller',
                      )
                      .length ??
                  0;
              final couriers =
                  snapshot.data?.docs
                      .where(
                        (doc) => (doc.data() as Map)['userType'] == 'courier',
                      )
                      .length ??
                  0;

              return GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSizes.paddingMD,
                mainAxisSpacing: AppSizes.paddingMD,
                childAspectRatio: 1.5,
                children: [
                  StatCard(
                    title: 'Total Users',
                    value: totalUsers.toString(),
                    icon: Icons.people,
                    color: AppColors.primary,
                    percentageChange: 12.5,
                  ),
                  StatCard(
                    title: 'Buyers',
                    value: buyers.toString(),
                    icon: Icons.shopping_cart,
                    color: AppColors.secondary,
                  ),
                  StatCard(
                    title: 'Sellers',
                    value: sellers.toString(),
                    icon: Icons.store,
                    color: AppColors.success,
                  ),
                  StatCard(
                    title: 'Couriers',
                    value: couriers.toString(),
                    icon: Icons.delivery_dining,
                    color: AppColors.warning,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: AppSizes.paddingXL),

          // Order Statistics
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, snapshot) {
              final totalOrders = snapshot.data?.docs.length ?? 0;
              final pendingOrders =
                  snapshot.data?.docs
                      .where(
                        (doc) => (doc.data() as Map)['status'] == 'pending',
                      )
                      .length ??
                  0;
              final onTheWayOrders =
                  snapshot.data?.docs
                      .where(
                        (doc) => (doc.data() as Map)['status'] == 'onTheWay',
                      )
                      .length ??
                  0;
              final deliveredOrders =
                  snapshot.data?.docs
                      .where(
                        (doc) => (doc.data() as Map)['status'] == 'delivered',
                      )
                      .length ??
                  0;

              return GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSizes.paddingMD,
                mainAxisSpacing: AppSizes.paddingMD,
                childAspectRatio: 1.5,
                children: [
                  StatCard(
                    title: 'Total Orders',
                    value: totalOrders.toString(),
                    icon: Icons.shopping_bag,
                    color: AppColors.primary,
                    percentageChange: 8.3,
                  ),
                  StatCard(
                    title: 'Pending',
                    value: pendingOrders.toString(),
                    icon: Icons.pending,
                    color: AppColors.warning,
                  ),
                  StatCard(
                    title: 'On The Way',
                    value: onTheWayOrders.toString(),
                    icon: Icons.local_shipping,
                    color: AppColors.info,
                  ),
                  StatCard(
                    title: 'Delivered',
                    value: deliveredOrders.toString(),
                    icon: Icons.check_circle,
                    color: AppColors.success,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: AppSizes.paddingXL),

          // Recent Activity Section
          Row(
            children: [
              Expanded(child: _buildRecentOrdersCard()),
              const SizedBox(width: AppSizes.paddingMD),
              Expanded(child: _buildPendingVerificationsCard()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersCard() {
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
                  'Recent Orders',
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
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
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
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final order = OrderModel.fromFirestore(
                      snapshot.data!.docs[index],
                    );
                    return ListTile(
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
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('verificationStatus', isEqualTo: 'pending')
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
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
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = UserModel.fromFirestore(
                      snapshot.data!.docs[index],
                    );
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
