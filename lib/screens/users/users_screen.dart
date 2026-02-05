import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/user_model.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.all(
        isSmallScreen ? AppSizes.paddingMD : AppSizes.paddingLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (!isSmallScreen) ...[
            Text(
              'User Management',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSM),
            Text(
              'Manage buyers, sellers, and couriers',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingLG),
          ],

          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users by name or email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSM),
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

          const SizedBox(height: AppSizes.paddingMD),

          // Tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusSM),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'All Users'),
                Tab(text: 'Buyers'),
                Tab(text: 'Sellers'),
                Tab(text: 'Couriers'),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.paddingMD),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserTable(null),
                _buildUserTable(UserType.buyer),
                _buildUserTable(UserType.seller),
                _buildUserTable(UserType.courier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTable(UserType? filterType) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: filterType == null
            ? FirebaseFirestore.instance.collection('users').snapshots()
            : FirebaseFirestore.instance
                  .collection('users')
                  .where('userType', isEqualTo: filterType.name)
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
                    Icons.people_outline,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: AppSizes.paddingMD),
                  Text(
                    'No users found',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          var users = snapshot.data!.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .where(
                (user) =>
                    _searchQuery.isEmpty ||
                    user.name.toLowerCase().contains(_searchQuery) ||
                    user.email.toLowerCase().contains(_searchQuery),
              )
              .toList();

          if (isSmallScreen) {
            // Mobile List View
            return ListView.separated(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              itemCount: users.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final user = users[index];
                return _buildUserCard(user);
              },
            );
          }

          // Desktop Data Table
          return DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            minWidth: 900,
            columns: [
              DataColumn2(
                label: Text(
                  'Name',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                size: ColumnSize.L,
              ),
              DataColumn2(
                label: Text(
                  'Email',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                size: ColumnSize.L,
              ),
              DataColumn2(
                label: Text(
                  'Type',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                size: ColumnSize.S,
              ),
              DataColumn2(
                label: Text(
                  'Status',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                size: ColumnSize.S,
              ),
              DataColumn2(
                label: Text(
                  'Verification',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                size: ColumnSize.S,
              ),
              DataColumn2(
                label: Text(
                  'Actions',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                size: ColumnSize.M,
              ),
            ],
            rows: users.map((user) => _buildUserRow(user)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getUserTypeColor(
                    user.userType,
                  ).withOpacity(0.1),
                  child: Icon(
                    _getUserTypeIcon(user.userType),
                    color: _getUserTypeColor(user.userType),
                  ),
                ),
                const SizedBox(width: AppSizes.paddingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user.email,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingMD),
            Wrap(
              spacing: AppSizes.paddingSM,
              runSpacing: AppSizes.paddingSM,
              children: [
                _buildChip(
                  user.userType.name.toUpperCase(),
                  _getUserTypeColor(user.userType),
                ),
                _buildChip(
                  user.status.name.toUpperCase(),
                  _getStatusColor(user.status),
                ),
                if (user.verificationStatus != null)
                  _buildChip(
                    user.verificationStatus!.name.toUpperCase(),
                    _getVerificationColor(user.verificationStatus!),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingMD),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showUserActions(user),
                    icon: const Icon(Icons.more_horiz, size: 16),
                    label: const Text('Actions'),
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

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSM,
        vertical: AppSizes.paddingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusXS),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  DataRow2 _buildUserRow(UserModel user) {
    return DataRow2(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _getUserTypeColor(
                  user.userType,
                ).withOpacity(0.1),
                child: Icon(
                  _getUserTypeIcon(user.userType),
                  size: 16,
                  color: _getUserTypeColor(user.userType),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user.name,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(user.email, style: GoogleFonts.inter())),
        DataCell(
          _buildStatusBadge(
            user.userType.name,
            _getUserTypeColor(user.userType),
          ),
        ),
        DataCell(
          _buildStatusBadge(user.status.name, _getStatusColor(user.status)),
        ),
        DataCell(
          user.verificationStatus != null
              ? _buildStatusBadge(
                  user.verificationStatus!.name,
                  _getVerificationColor(user.verificationStatus!),
                )
              : const Text('-'),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _showUserActions(user),
                tooltip: 'Edit',
                color: AppColors.primary,
              ),
              if (user.status == UserStatus.active)
                IconButton(
                  icon: const Icon(Icons.block, size: 18),
                  onPressed: () => _banUser(user),
                  tooltip: 'Ban',
                  color: AppColors.error,
                )
              else
                IconButton(
                  icon: const Icon(Icons.check_circle, size: 18),
                  onPressed: () => _activateUser(user),
                  tooltip: 'Activate',
                  color: AppColors.success,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showUserActions(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Actions', style: GoogleFonts.inter()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show user details
              },
            ),
            if (user.status == UserStatus.active)
              ListTile(
                leading: const Icon(Icons.block, color: AppColors.error),
                title: const Text('Ban User'),
                onTap: () {
                  Navigator.pop(context);
                  _banUser(user);
                },
              )
            else
              ListTile(
                leading: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                ),
                title: const Text('Activate User'),
                onTap: () {
                  Navigator.pop(context);
                  _activateUser(user);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _banUser(UserModel user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'status': UserStatus.banned.name,
      });
      _showSnackBar('User banned successfully', AppColors.success);
    } catch (e) {
      _showSnackBar('Failed to ban user', AppColors.error);
    }
  }

  Future<void> _activateUser(UserModel user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'status': UserStatus.active.name,
      });
      _showSnackBar('User activated successfully', AppColors.success);
    } catch (e) {
      _showSnackBar('Failed to activate user', AppColors.error);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Color _getUserTypeColor(UserType type) {
    switch (type) {
      case UserType.buyer:
        return AppColors.secondary;
      case UserType.seller:
        return AppColors.success;
      case UserType.courier:
        return AppColors.warning;
    }
  }

  IconData _getUserTypeIcon(UserType type) {
    switch (type) {
      case UserType.buyer:
        return Icons.shopping_cart;
      case UserType.seller:
        return Icons.store;
      case UserType.courier:
        return Icons.delivery_dining;
    }
  }

  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return AppColors.success;
      case UserStatus.banned:
        return AppColors.error;
      case UserStatus.suspended:
        return AppColors.warning;
    }
  }

  Color _getVerificationColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return AppColors.warning;
      case VerificationStatus.verified:
        return AppColors.success;
      case VerificationStatus.rejected:
        return AppColors.error;
    }
  }
}
