import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;

        return Padding(
          padding: EdgeInsets.all(
            isMobile ? AppSizes.paddingMD : AppSizes.paddingLG,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Content Moderation',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingSM),
              Text(
                'Review and moderate platform content',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 12 : 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingLG),

              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: isMobile,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Product Approvals'),
                    Tab(text: 'Reported Content'),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.paddingMD),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProductApprovals(isMobile, screenWidth),
                    _buildReportedContent(isMobile),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductApprovals(bool isSmallScreen, double screenWidth) {
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
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: AppSizes.paddingMD),
                  Text(
                    'No pending approvals',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isSmallScreen ? 1 : (screenWidth < 900 ? 2 : 3),
              crossAxisSpacing: AppSizes.paddingMD,
              mainAxisSpacing: AppSizes.paddingMD,
              childAspectRatio: isSmallScreen
                  ? 1.2
                  : (screenWidth < 1200 ? 0.85 : 0.95),
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final product = snapshot.data!.docs[index];
              return _buildProductCard(product);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(DocumentSnapshot product) {
    final data = product.data() as Map<String, dynamic>;
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusMD),
            ),
            child: Container(
              height: 150,
              width: double.infinity,
              color: AppColors.surfaceVariant,
              child: data['imageUrl'] != null
                  ? Image.network(
                      data['imageUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: AppColors.textHint,
                        );
                      },
                    )
                  : const Icon(
                      Icons.fastfood,
                      size: 48,
                      color: AppColors.textHint,
                    ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'Unnamed Product',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.paddingXS),
                  Text(
                    data['description'] ?? 'No description',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.paddingSM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${data['price'] ?? '0.00'}',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (data['unitWeight'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${data['unitWeight']} ${data['unitType'] ?? 'kg'}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveProduct(product.id),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.paddingSM,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingSM),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rejectProduct(product.id),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.paddingSM,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportedContent(bool isSmallScreen) {
    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.report_off, size: 64, color: AppColors.textHint),
                  const SizedBox(height: AppSizes.paddingMD),
                  Text(
                    'No reported content',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final report = snapshot.data!.docs[index];
              return _buildReportCard(report);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(DocumentSnapshot report) {
    final data = report.data() as Map<String, dynamic>;
    return Container(
      margin: EdgeInsets.all(AppSizes.paddingSM),
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingSM),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                  ),
                  child: const Icon(
                    Icons.report,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSizes.paddingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['type'] ?? 'Report',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Reported by: ${data['reporterName'] ?? 'Unknown'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingMD),
            Text(
              data['reason'] ?? 'No reason provided',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: AppSizes.paddingMD),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _dismissReport(report.id),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Dismiss'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.paddingSM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _takeAction(report.id),
                    icon: const Icon(Icons.gavel, size: 16),
                    label: const Text('Take Action'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveProduct(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update({'status': 'approved'});
      _showSnackBar('Product approved successfully', AppColors.success);
    } catch (e) {
      _showSnackBar('Failed to approve product', AppColors.error);
    }
  }

  Future<void> _rejectProduct(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update({'status': 'rejected'});
      _showSnackBar('Product rejected', AppColors.error);
    } catch (e) {
      _showSnackBar('Failed to reject product', AppColors.error);
    }
  }

  Future<void> _dismissReport(String reportId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({'status': 'dismissed'});
      _showSnackBar('Report dismissed', AppColors.success);
    } catch (e) {
      _showSnackBar('Failed to dismiss report', AppColors.error);
    }
  }

  Future<void> _takeAction(String reportId) async {
    // TODO: Implement action logic
    _showSnackBar('Action taken', AppColors.success);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }
}
