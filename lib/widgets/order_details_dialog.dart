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

        return AlertDialog(
          title: Text('Order Details', style: GoogleFonts.inter()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Order ID', order.id),
                _buildDetailRow(
                  'Customer',
                  isLoading
                      ? ShimmerLoading.rounded(height: 15, width: 150)
                      : '$buyerName (${order.buyerId.length > 8 ? order.buyerId.substring(0, 8) : order.buyerId})',
                ),
                _buildDetailRow(
                  'Seller',
                  isLoading
                      ? ShimmerLoading.rounded(height: 15, width: 150)
                      : '$sellerName (${order.sellerId.length > 8 ? order.sellerId.substring(0, 8) : order.sellerId})',
                ),
                if (order.courierName != null)
                  _buildDetailRow(
                    'Courier',
                    '${order.courierName} (${order.courierId?.length != null && order.courierId!.length > 8 ? order.courierId!.substring(0, 8) : order.courierId ?? ''})',
                  ),

                // Product Items Section
                if (order.items.isNotEmpty) ...[
                  const Divider(),
                  Text(
                    'ORDERED ITEMS',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => _buildItemRow(item)),
                  const Divider(),
                ],

                _buildDetailRow(
                  'Subtotal',
                  '\$${displayTotal.toStringAsFixed(2)}',
                ),
                _buildDetailRow(
                  'Delivery Fee',
                  '\$${order.deliveryFee.toStringAsFixed(2)}',
                ),
                _buildDetailRow(
                  'Grand Total',
                  '\$${order.grandTotal.toStringAsFixed(2)}',
                  isBold: true,
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Status', _getStatusText(order.status)),
                _buildDetailRow(
                  'Escrow',
                  order.escrowStatus.name.toUpperCase(),
                ),
                _buildDetailRow('Address', order.deliveryAddress),
                _buildDetailRow('Date', _formatDate(order.createdAt)),
                if (order.trackingNumber != null) ...[
                  _buildDetailRow('Tracking #', order.trackingNumber!),
                  _buildDetailRow(
                    'Provider',
                    order.trackingProvider ?? 'Unknown',
                  ),
                ],
                if (order.notes != null) _buildDetailRow('Notes', order.notes!),
                if (order.hasDispute) ...[
                  const Divider(),
                  Text(
                    'DISPUTE INFORMATION',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 8),
                  _buildDetailRow('Reason', order.disputeReason ?? 'N/A'),
                  if (order.sellerResponse != null)
                    _buildDetailRow('Seller Response', order.sellerResponse!),
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

                // Order History Timeline
                const Divider(),
                Text(
                  'ORDER TIMELINE',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                if (order.history.isEmpty)
                  const Text('No tracking events recorded.')
                else
                  ...order.history.map((h) => _buildTimelineItem(h)),
              ],
            ),
          ),
          actions: [
            if (order.hasDispute)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showResolveDisputeDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('Resolve Dispute'),
              ),
            if (order.escrowStatus == EscrowStatus.held && !order.hasDispute)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmReleaseEscrow(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                child: const Text('Release Escrow'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
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

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.productName} (×${item.quantity})',
              style: GoogleFonts.inter(fontSize: 13),
            ),
          ),
          Text(
            '\$${item.totalPrice.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
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
