import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrderStatus? _selectedStatus;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                'Order Management',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingSM),
              Text(
                'Track and manage all orders',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 12 : 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingLG),

              // Search and Filter Row
              Wrap(
                spacing: AppSizes.paddingMD,
                runSpacing: AppSizes.paddingMD,
                children: [
                  SizedBox(
                    width: isMobile ? double.infinity : 300,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search orders...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSM,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? double.infinity : 200,
                    child: DropdownButtonFormField<OrderStatus?>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Filter by Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSM,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Orders'),
                        ),
                        ...OrderStatus.values.map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(_getStatusText(status)),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingMD),

              // Orders Table/List
              Expanded(child: _buildOrdersList(isMobile)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrdersList(bool isSmallScreen) {
    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
      ),
      child: StreamBuilder<List<OrderModel>>(
        stream: _selectedStatus == null
            ? OrderService.getAllOrders()
            : OrderService.getOrdersByStatus(_selectedStatus!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: AppSizes.paddingMD),
                  Text(
                    'No orders found',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          var orders = snapshot.data!
              .where(
                (order) =>
                    _searchQuery.isEmpty ||
                    order.buyerName.toLowerCase().contains(_searchQuery) ||
                    order.sellerName.toLowerCase().contains(_searchQuery) ||
                    order.id.toLowerCase().contains(_searchQuery),
              )
              .toList();

          if (isSmallScreen) {
            return ListView.separated(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return _buildOrderCard(orders[index]);
              },
            );
          }

          return DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            minWidth: 1000,
            columns: [
              DataColumn2(
                label: Text(
                  'Order ID',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                size: ColumnSize.S,
              ),
              DataColumn2(
                label: Text(
                  'Customer',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                size: ColumnSize.L,
              ),
              DataColumn2(
                label: Text(
                  'Seller',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                size: ColumnSize.L,
              ),
              DataColumn2(
                label: Text(
                  'Amount',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                size: ColumnSize.S,
              ),
              DataColumn2(
                label: Text(
                  'Status',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                size: ColumnSize.M,
              ),
              DataColumn2(
                label: Text(
                  'Date',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                size: ColumnSize.M,
              ),
              DataColumn2(
                label: Text(
                  'Actions',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                size: ColumnSize.S,
              ),
            ],
            rows: orders.map((order) => _buildOrderRow(order)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingSM,
                    vertical: AppSizes.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(order.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingSM),
            _buildInfoRow(Icons.person, 'Customer', order.buyerName),
            _buildInfoRow(Icons.store, 'Seller', order.sellerName),
            _buildInfoRow(
              Icons.attach_money,
              'Amount',
              '\$${order.grandTotal.toStringAsFixed(2)}',
            ),
            _buildInfoRow(
              Icons.calendar_today,
              'Date',
              _formatDate(order.createdAt),
            ),
            if (order.hasDispute)
              Padding(
                padding: const EdgeInsets.only(top: AppSizes.paddingSM),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.paddingSM),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Has Dispute',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSizes.paddingMD),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showOrderDetails(order),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.paddingXS),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResolveDisputeDialog(OrderModel order) {
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
              _showSnackBar('Refunded to buyer', AppColors.success);
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
              _showSnackBar('Released to seller', AppColors.success);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Release to Seller'),
          ),
        ],
      ),
    );
  }

  void _confirmReleaseEscrow(OrderModel order) {
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
              _showSnackBar('Funds released to seller', AppColors.success);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Confirm Release'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  DataRow2 _buildOrderRow(OrderModel order) {
    return DataRow2(
      cells: [
        DataCell(
          Text(
            '#${order.id.substring(0, 8)}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(Text(order.buyerName, style: GoogleFonts.inter())),
        DataCell(Text(order.sellerName, style: GoogleFonts.inter())),
        DataCell(
          Text(
            '\$${order.grandTotal.toStringAsFixed(2)}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(_buildStatusBadge(order.status)),
        DataCell(
          Text(_formatDate(order.createdAt), style: GoogleFonts.inter()),
        ),
        DataCell(
          IconButton(
            icon: const Icon(Icons.visibility, size: 18),
            onPressed: () => _showOrderDetails(order),
            tooltip: 'View Details',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _getStatusText(status),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  void _showOrderDetails(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Details', style: GoogleFonts.inter()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Order ID', order.id),
              _buildDetailRow('Customer', order.buyerName),
              _buildDetailRow('Seller', order.sellerName),
              if (order.courierName != null)
                _buildDetailRow('Courier', order.courierName!),
              _buildDetailRow(
                'Total Amount',
                '\$${order.totalAmount.toStringAsFixed(2)}',
              ),
              _buildDetailRow(
                'Delivery Fee',
                '\$${order.deliveryFee.toStringAsFixed(2)}',
              ),
              _buildDetailRow(
                'Grand Total',
                '\$${order.grandTotal.toStringAsFixed(2)}',
              ),
              _buildDetailRow('Status', _getStatusText(order.status)),
              _buildDetailRow('Escrow', order.escrowStatus.name.toUpperCase()),
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
                Text(
                  order.disputeDetails ?? 'No details provided.',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (order.hasDispute)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showResolveDisputeDialog(order);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Resolve Dispute'),
            ),
          if (order.escrowStatus == EscrowStatus.held && !order.hasDispute)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmReleaseEscrow(order);
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 13))),
        ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
