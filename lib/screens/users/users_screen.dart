import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../widgets/chat_dialog.dart';
import '../../core/utils/animations.dart';

import '../../widgets/shimmer_loading.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
                'User Management',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ).animateFadeInUp(),
              const SizedBox(height: AppSizes.paddingSM),
              Text(
                'Manage buyers, sellers, and couriers',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 12 : 14,
                  color: AppColors.textSecondary,
                ),
              ).animateFadeInUp(delay: 100),
              const SizedBox(height: AppSizes.paddingLG),

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
                  isScrollable: isMobile,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'All Users'),
                    Tab(text: 'Verification'),
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
                    _buildUserTable(null, onlyPending: true),
                    _buildUserTable(UserType.buyer),
                    _buildUserTable(UserType.seller),
                    _buildUserTable(UserType.courier),
                  ],
                ).animateFadeInUp(delay: 200),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserTable(UserType? filterType, {bool onlyPending = false}) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

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
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: StreamBuilder<List<UserModel>>(
        stream: filterType == null
            ? UserService.getAllUsers()
            : UserService.getUsersByType(filterType),
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final usersData = snapshot.data ?? [];

          return ShimmerSwitcher(
            isLoading: isLoading,
            skeleton: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              itemCount: 10,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  ShimmerLoading.rounded(height: isSmallScreen ? 150 : 50),
            ),
            child: usersData.isEmpty
                ? Center(
                    key: const ValueKey('empty'),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
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
                  )
                : Builder(
                    key: const ValueKey('list'),
                    builder: (context) {
                      final filteredUsers = usersData.where((user) {
                        final matchesSearch =
                            _searchQuery.isEmpty ||
                            user.name.toLowerCase().contains(_searchQuery) ||
                            user.email.toLowerCase().contains(_searchQuery);
                        final matchesPending =
                            !onlyPending ||
                            user.verificationStatus ==
                                VerificationStatus.pending;
                        return matchesSearch && matchesPending;
                      }).toList();

                      if (isSmallScreen) {
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppSizes.paddingMD),
                          itemCount: filteredUsers.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) =>
                              _buildUserCard(filteredUsers[index]),
                        );
                      }

                      return DataTable2(
                        columnSpacing: 12,
                        horizontalMargin: 12,
                        minWidth: 900,
                        columns: [
                          DataColumn2(
                            label: Text(
                              'Name',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            size: ColumnSize.L,
                          ),
                          DataColumn2(
                            label: Text(
                              'Email',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            size: ColumnSize.L,
                          ),
                          DataColumn2(
                            label: Text(
                              'Type',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            size: ColumnSize.S,
                          ),
                          DataColumn2(
                            label: Text(
                              'Status',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            size: ColumnSize.S,
                          ),
                          DataColumn2(
                            label: Text(
                              'Verification',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            size: ColumnSize.S,
                          ),
                          DataColumn2(
                            label: Text(
                              'Actions',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            size: ColumnSize.M,
                          ),
                        ],
                        rows: filteredUsers
                            .map((user) => _buildUserRow(user))
                            .toList(),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Container(
      margin: EdgeInsets.zero,
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
                CircleAvatar(
                  backgroundColor: _getUserTypeColor(
                    user.userType,
                  ).withOpacity(0.1),
                  backgroundImage:
                      user.profileImage != null && user.profileImage!.isNotEmpty
                      ? NetworkImage(user.profileImage!)
                      : null,
                  child:
                      user.profileImage != null && user.profileImage!.isNotEmpty
                      ? null
                      : Icon(
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
                backgroundImage:
                    user.profileImage != null && user.profileImage!.isNotEmpty
                    ? NetworkImage(user.profileImage!)
                    : null,
                child:
                    user.profileImage != null && user.profileImage!.isNotEmpty
                    ? null
                    : Icon(
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
                _showUserDetails(user);
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
            ListTile(
              leading: const Icon(Icons.message, color: AppColors.primary),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                _openChat(user);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details', style: GoogleFonts.inter()),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: _getUserTypeColor(
                    user.userType,
                  ).withOpacity(0.1),
                  backgroundImage:
                      user.profileImage != null && user.profileImage!.isNotEmpty
                      ? NetworkImage(user.profileImage!)
                      : null,
                  child:
                      user.profileImage != null && user.profileImage!.isNotEmpty
                      ? null
                      : Icon(
                          _getUserTypeIcon(user.userType),
                          size: 40,
                          color: _getUserTypeColor(user.userType),
                        ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingLG),
              _buildDetailItem('Name', user.name),
              _buildDetailItem('Email', user.email),
              _buildDetailItem('User Type', user.userType.name.toUpperCase()),
              _buildDetailItem('Status', user.status.name.toUpperCase()),
              if (user.phone != null) _buildDetailItem('Phone', user.phone!),
              _buildDetailItem(
                'Joined',
                user.createdAt.toString().split('.')[0],
              ),
              const Divider(),
              Text(
                'Verification Status:',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildVerificationRow(
                'Overall',
                user.verificationStatus ?? VerificationStatus.pending,
              ),
              _buildVerificationRow(
                'ID Document',
                user.idVerificationStatus ?? VerificationStatus.pending,
              ),
              _buildVerificationRow(
                'Facial Check',
                user.facialVerificationStatus ?? VerificationStatus.pending,
              ),
              if (user.userType == UserType.seller &&
                  user.trialStartDate != null) ...[
                const Divider(),
                Text(
                  'Trial Period:',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                _buildDetailItem(
                  'Trial Started',
                  user.trialStartDate!.toString().split('.')[0],
                ),
                _buildTrialProgress(user.trialStartDate!),
              ],
              if (user.userType == UserType.seller) ...[
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Shipping Rules:',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showManageShippingRules(user);
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Manage'),
                    ),
                  ],
                ),
                _buildDetailItem('Base Cost/Kg', '\$${user.costPerKg ?? 0.0}'),
                _buildDetailItem('Min Fee', '\$${user.minShippingFee ?? 0.0}'),
                if (user.shippingRules != null &&
                    user.shippingRules!.isNotEmpty)
                  Text(
                    '${user.shippingRules!.length} country rules defined',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
              if (user.metadata != null) ...[
                const Divider(),
                Text(
                  'Metadata:',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                ...user.metadata!.entries.map(
                  (e) => _buildDetailItem(e.key, e.value.toString()),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (user.verificationStatus == VerificationStatus.pending) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _rejectUser(user);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Reject'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _approveUser(user);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve'),
            ),
            const SizedBox(width: AppSizes.paddingSM),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openChat(user);
              },
              icon: const Icon(Icons.message, size: 16),
              label: const Text('Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openChat(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => ChatDialog(user: user),
    );
  }

  void _showManageShippingRules(UserModel user) {
    final costController = TextEditingController(
      text: (user.costPerKg ?? 0.0).toString(),
    );
    final minFeeController = TextEditingController(
      text: (user.minShippingFee ?? 0.0).toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Manage Shipping: ${user.name}',
          style: GoogleFonts.inter(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: costController,
              decoration: const InputDecoration(
                labelText: 'Shipping Cost Per Kg (\$)',
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSizes.paddingMD),
            TextField(
              controller: minFeeController,
              decoration: const InputDecoration(
                labelText: 'Minimum Shipping Fee (\$)',
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSizes.paddingMD),
            const Text(
              'Per-country rules and validation logic are preserved in metadata. Direct editing of map rules will be available in the next update.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
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
              final cost = double.tryParse(costController.text);
              final minFee = double.tryParse(minFeeController.text);
              if (cost != null && minFee != null) {
                await UserService.updateShippingRules(
                  user.id,
                  costPerKg: cost,
                  minShippingFee: minFee,
                );
                Navigator.pop(context);
                _showSnackBar('Shipping rules updated', AppColors.success);
              }
            },
            child: const Text('Save Rules'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _banUser(UserModel user) async {
    try {
      await UserService.updateUserStatus(user.id, UserStatus.banned);
      _showSnackBar('User banned successfully', AppColors.success);
    } catch (e) {
      _showSnackBar('Failed to ban user', AppColors.error);
    }
  }

  Future<void> _activateUser(UserModel user) async {
    try {
      await UserService.updateUserStatus(user.id, UserStatus.active);
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

  Widget _buildVerificationRow(String label, VerificationStatus status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13)),
          _buildStatusBadge(status.name, _getVerificationColor(status)),
        ],
      ),
    );
  }

  Widget _buildTrialProgress(DateTime startDate) {
    final now = DateTime.now();
    final endDate = startDate.add(const Duration(days: 14));
    final totalDays = endDate.difference(startDate).inDays;
    final usedDays = now.difference(startDate).inDays;
    final progress = (usedDays / totalDays).clamp(0.0, 1.0);
    final remainingDays = totalDays - usedDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.background,
          valueColor: AlwaysStoppedAnimation<Color>(
            progress > 0.8 ? AppColors.error : AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          progress >= 1.0
              ? 'Trial Ended'
              : '$remainingDays days remaining in trial',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: progress > 0.8 ? AppColors.error : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Future<void> _approveUser(UserModel user) async {
    try {
      await UserService.updateVerificationStatus(
        user.id,
        VerificationStatus.verified,
      );
      _showSnackBar('User approved successfully', AppColors.success);
    } catch (e) {
      _showSnackBar('Failed to approve user', AppColors.error);
    }
  }

  Future<void> _rejectUser(UserModel user) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Verification'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Enter rejection reason...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await UserService.updateVerificationStatus(
          user.id,
          VerificationStatus.rejected,
          reason: reasonController.text,
        );
        _showSnackBar('User rejected successfully', AppColors.error);
      } catch (e) {
        _showSnackBar('Failed to reject user', AppColors.error);
      }
    }
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
