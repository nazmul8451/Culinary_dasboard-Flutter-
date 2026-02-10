import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_model.dart';
import '../core/constants/app_colors.dart';
import '../services/user_service.dart';
import '../services/order_service.dart';
import 'shimmer_loading.dart';

class OrderDetailsDialog extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onUpdate;

  const OrderDetailsDialog({super.key, required this.order, this.onUpdate});

  @override
  Widget build(BuildContext context) {
    // Calculate total from items if totalAmount is 0
    final calculatedTotal = order.items.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    final displayTotal = order.totalAmount > 0
        ? order.totalAmount
        : calculatedTotal;

    return FutureBuilder<Map<String, String?>>(
      future:
          Future.wait([
            order.buyerName.isEmpty
                ? UserService.getUserById(order.buyerId)
                : Future.value(null),
            order.sellerName.isEmpty
                ? UserService.getUserById(order.sellerId)
                : Future.value(null),
          ]).then(
            (users) => {
              'buyerName':
                  users[0]?.name ??
                  (order.buyerName.isEmpty ? null : order.buyerName),
              'sellerName':
                  users[1]?.name ??
                  (order.sellerName.isEmpty ? null : order.sellerName),
            },
          ),
      builder: (context, snapshot) {
        final buyerName = snapshot.data?['buyerName'];
        final sellerName = snapshot.data?['sellerName'];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modern Header with Gradient
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Details',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '#${order.id.substring(0, 12)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(order.status),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Participants Section
                        _buildSection('Participants', Icons.people_outline, [
                          _buildModernDetailRow(
                            Icons.person,
                            'Customer',
                            isLoading
                                ? ShimmerLoading.rounded(height: 15, width: 150)
                                : buyerName ?? 'Unknown',
                            AppColors.primary,
                          ),
                          _buildModernDetailRow(
                            Icons.store,
                            'Seller',
                            isLoading
                                ? ShimmerLoading.rounded(height: 15, width: 150)
                                : sellerName ?? 'Unknown',
                            AppColors.secondary,
                          ),
                          if (order.courierName != null)
                            _buildModernDetailRow(
                              Icons.delivery_dining,
                              'Courier',
                              order.courierName!,
                              AppColors.warning,
                            ),
                        ]),

                        const SizedBox(height: 20),

                        // Order Items Section
                        if (order.items.isNotEmpty) ...[
                          _buildSection(
                            'Order Items',
                            Icons.shopping_bag_outlined,
                            order.items
                                .map((item) => _buildModernItemRow(item))
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Payment Summary
                        _buildSection('Payment Summary', Icons.payment, [
                          _buildPricingRow('Subtotal', displayTotal, false),
                          _buildPricingRow(
                            'Delivery Fee',
                            order.deliveryFee,
                            false,
                          ),
                          const Divider(height: 16),
                          _buildPricingRow(
                            'Grand Total',
                            order.grandTotal,
                            true,
                          ),
                        ]),

                        const SizedBox(height: 20),

                        // Delivery Information
                        _buildSection(
                          'Delivery Information',
                          Icons.local_shipping_outlined,
                          [
                            _buildInfoTile(
                              Icons.location_on_outlined,
                              'Address',
                              order.deliveryAddress,
                            ),
                            _buildInfoTile(
                              Icons.calendar_today,
                              'Order Date',
                              _formatDate(order.createdAt),
                            ),
                            if (order.trackingNumber != null)
                              _buildInfoTile(
                                Icons.qr_code,
                                'Tracking',
                                '${order.trackingNumber} (${order.trackingProvider ?? 'N/A'})',
                              ),
                            _buildInfoTile(
                              Icons.account_balance_wallet,
                              'Escrow Status',
                              order.escrowStatus.name.toUpperCase(),
                            ),
                          ],
                        ),

                        if (order.notes != null) ...[
                          const SizedBox(height: 20),
                          _buildSection('Notes', Icons.note_outlined, [
                            Text(
                              order.notes!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ]),
                        ],

                        // Dispute Section
                        if (order.hasDispute) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.error.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_rounded,
                                      color: AppColors.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'DISPUTE ACTIVE',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.error,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  'Reason',
                                  order.disputeReason ?? 'N/A',
                                ),
                                if (order.sellerResponse != null)
                                  _buildDetailRow(
                                    'Seller Response',
                                    order.sellerResponse!,
                                  ),
                                if (order.buyerEvidence.isNotEmpty)
                                  _buildEvidenceRow(
                                    context,
                                    'Buyer Evidence',
                                    order.buyerEvidence,
                                  ),
                                if (order.sellerEvidence.isNotEmpty)
                                  _buildEvidenceRow(
                                    context,
                                    'Seller Evidence',
                                    order.sellerEvidence,
                                  ),
                              ],
                            ),
                          ),
                        ],

                        // Timeline
                        const SizedBox(height: 20),
                        _buildSection(
                          'Order Timeline',
                          Icons.timeline,
                          order.history.isEmpty
                              ? [
                                  Text(
                                    'No tracking events recorded.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ]
                              : order.history
                                    .map((h) => _buildTimelineItem(h))
                                    .toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Delete Order Button
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDeleteOrder(context);
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                          size: 18,
                        ),
                        label: Text(
                          'Delete',
                          style: GoogleFonts.inter(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (order.hasDispute)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showResolveDisputeDialog(context);
                          },
                          icon: const Icon(Icons.gavel, size: 18),
                          label: const Text('Resolve Dispute'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      if (order.escrowStatus == EscrowStatus.held &&
                          !order.hasDispute)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmReleaseEscrow(context);
                          },
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Release Escrow'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, dynamic value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: value is Widget
                ? value
                : Text(
                    value.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Modern Section Builder
  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // Modern Detail Row with Icon
  Widget _buildModernDetailRow(
    IconData icon,
    String label,
    dynamic value,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                value is Widget
                    ? value
                    : Text(
                        value.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modern Item Row
  Widget _buildModernItemRow(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.fastfood,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Quantity: ${item.quantity}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${item.totalPrice.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Pricing Row
  Widget _buildPricingRow(String label, double amount, bool isBold) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: isBold ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: isBold ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // Info Tile
  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showResolveDisputeDialog(BuildContext context) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Dispute'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Review the claim and decide the outcome.',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Resolution Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await OrderService.resolveDispute(
                order.id,
                refundBuyer: true,
                resolutionNotes: notesController.text,
              );
              Navigator.pop(context);
              onUpdate?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Refund Buyer'),
          ),

          ElevatedButton(
            onPressed: () async {
              await OrderService.resolveDispute(
                order.id,
                refundBuyer: false,
                resolutionNotes: notesController.text,
              );
              Navigator.pop(context);
              onUpdate?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Release to Seller'),
          ),
        ],
      ),
    );
  }

  void _confirmReleaseEscrow(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Release Escrow'),
        content: const Text(
          'Are you sure you want to release funds to the seller? This action is permanent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await OrderService.updateEscrowStatus(
                order.id,
                EscrowStatus.released,
              );
              Navigator.pop(context);
              onUpdate?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Confirm Release'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteOrder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Order',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this order? This action cannot be undone.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Order ID: ${order.id}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await OrderService.deleteOrder(order.id);
                Navigator.pop(context); // Close confirmation dialog
                onUpdate?.call(); // Refresh the list
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Order deleted successfully',
                      style: GoogleFonts.inter(),
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to delete order: $e',
                      style: GoogleFonts.inter(),
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete Order'),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceRow(
    BuildContext context,
    String label,
    List<String> urls,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _viewFullImage(context, urls[index]),
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        urls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.broken_image,
                              size: 32,
                              color: AppColors.textHint,
                            ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(OrderHistory entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(entry.status),
                  shape: BoxShape.circle,
                ),
              ),
              Container(width: 2, height: 20, color: AppColors.border),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(entry.status),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  _formatDate(entry.timestamp),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (entry.message != null)
                  Text(entry.message!, style: GoogleFonts.inter(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Could not load image'),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
