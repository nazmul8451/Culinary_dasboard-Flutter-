import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../widgets/chat_dialog.dart';
import '../../core/utils/animations.dart';
import '../../services/fcm_service.dart';
import '../../controllers/dashboard_controller.dart';

import '../../widgets/shimmer_loading.dart';
import '../../widgets/keep_alive_wrapper.dart';

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
    final dashboardController = Get.find<DashboardController>();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: dashboardController.usersTabIndex,
    );
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Management',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ).animateFadeInUp(),
                  const SizedBox(height: AppSizes.paddingSM),
                  Text(
                    'Manage buyers, sellers, and couriers',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ).animateFadeInUp(delay: 100),
                  const SizedBox(height: AppSizes.paddingLG),
                  _buildSearchField(),
                  const SizedBox(height: AppSizes.paddingMD),
                  _buildTabBar(isMobile),
                  const SizedBox(height: AppSizes.paddingMD),
                ],
              ),
            ),
          ),
          _buildSliverUserList(),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.all(
        isMobile ? AppSizes.paddingMD : AppSizes.paddingLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Management',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ).animateFadeInUp(),
          const SizedBox(height: AppSizes.paddingSM),
          Text(
            'Manage buyers, sellers, and couriers',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ).animateFadeInUp(delay: 100),
          const SizedBox(height: AppSizes.paddingLG),
          _buildSearchField(),
          const SizedBox(height: AppSizes.paddingMD),
          _buildTabBar(isMobile),
          const SizedBox(height: AppSizes.paddingMD),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                KeepAliveWrapper(child: _buildUserTable(null)),
                KeepAliveWrapper(
                  child: _buildUserTable(null, onlyPending: true),
                ),
                KeepAliveWrapper(child: _buildUserTable(UserType.buyer)),
                KeepAliveWrapper(child: _buildUserTable(UserType.seller)),
                KeepAliveWrapper(child: _buildUserTable(UserType.courier)),
              ],
            ).animateFadeInUp(delay: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
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
    );
  }

  Widget _buildTabBar(bool isMobile) {
    return Container(
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
        onTap: (index) {
          if (isMobile) setState(() {});
        },
        tabs: const [
          Tab(text: 'All Users'),
          Tab(text: 'Verification'),
          Tab(text: 'Buyers'),
          Tab(text: 'Sellers'),
          Tab(text: 'Couriers'),
        ],
      ),
    );
  }

  UserType? _getSelectedType() {
    switch (_tabController.index) {
      case 2:
        return UserType.buyer;
      case 3:
        return UserType.seller;
      case 4:
        return UserType.courier;
      default:
        return null;
    }
  }

  bool _getOnlyPending() => _tabController.index == 1;

  Widget _buildSliverUserList() {
    final filterType = _getSelectedType();
    final onlyPending = _getOnlyPending();

    return StreamBuilder<List<UserModel>>(
      stream: filterType == null
          ? UserService.getAllUsers()
          : UserService.getUsersByType(filterType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMD),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ShimmerLoading.rounded(height: 150),
                ),
                childCount: 5,
              ),
            ),
          );
        }

        final usersData = snapshot.data ?? [];
        if (usersData.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: AppSizes.paddingMD),
                  Text(
                    'No users found',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        final filteredUsers = usersData.where((user) {
          final matchesSearch =
              _searchQuery.isEmpty ||
              user.name.toLowerCase().contains(_searchQuery) ||
              user.email.toLowerCase().contains(_searchQuery);
          final matchesPending =
              !onlyPending ||
              user.verificationStatus == VerificationStatus.pending;
          return matchesSearch && matchesPending;
        }).toList();

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMD),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildUserCard(filteredUsers[index]),
              );
            }, childCount: filteredUsers.length),
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
          TextButton.icon(
            onPressed: () => _showUserActions(user),
            icon: const Icon(Icons.more_horiz, size: 16),
            label: const Text('Actions'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient Header
              Container(
                padding: const EdgeInsets.all(20),
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
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'User Actions',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionTile(
                      icon: Icons.info_outline,
                      title: 'View Details',
                      iconColor: AppColors.info,
                      onTap: () {
                        Navigator.pop(context);
                        _showUserDetails(user);
                      },
                    ),
                    if (user.status == UserStatus.active)
                      _buildActionTile(
                        icon: Icons.block,
                        title: 'Ban User',
                        iconColor: AppColors.error,
                        onTap: () {
                          Navigator.pop(context);
                          _banUser(user);
                        },
                      )
                    else
                      _buildActionTile(
                        icon: Icons.check_circle_outline,
                        title: 'Activate User',
                        iconColor: AppColors.success,
                        onTap: () {
                          Navigator.pop(context);
                          _activateUser(user);
                        },
                      ),
                    _buildActionTile(
                      icon: Icons.notifications_none,
                      title: 'Send Notification',
                      iconColor: AppColors.warning,
                      onTap: () {
                        Navigator.pop(context);
                        _showPushNotificationDialog(user);
                      },
                    ),
                  ],
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getUserTypeColor(user.userType),
                      _getUserTypeColor(user.userType).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            user.profileImage != null &&
                                user.profileImage!.isNotEmpty
                            ? NetworkImage(user.profileImage!)
                            : null,
                        child:
                            user.profileImage != null &&
                                user.profileImage!.isNotEmpty
                            ? null
                            : Icon(
                                _getUserTypeIcon(user.userType),
                                size: 24,
                                color: _getUserTypeColor(user.userType),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.userType.name.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
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
                      _buildSectionHeader('Contact Information'),
                      _buildInfoTile(Icons.email_outlined, 'Email', user.email),
                      if (user.phone != null)
                        _buildInfoTile(
                          Icons.phone_outlined,
                          'Phone',
                          user.phone!,
                        ),
                      _buildInfoTile(
                        Icons.calendar_today_outlined,
                        'Joined',
                        user.createdAt.toString().split('.')[0],
                      ),

                      const SizedBox(height: 24),
                      _buildSectionHeader('Account Status'),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: user.status == UserStatus.active
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: user.status == UserStatus.active
                                ? AppColors.success.withOpacity(0.3)
                                : AppColors.error.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              user.status == UserStatus.active
                                  ? Icons.check_circle
                                  : Icons.block,
                              size: 16,
                              color: user.status == UserStatus.active
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              user.status.name.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: user.status == UserStatus.active
                                    ? AppColors.success
                                    : AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      _buildSectionHeader('Verification Status'),
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
                        user.facialVerificationStatus ??
                            VerificationStatus.pending,
                      ),

                      if (user.metadata != null &&
                          (user.metadata!.containsKey('nidUrl') ||
                              user.metadata!.containsKey('idDocumentUrl') ||
                              user.metadata!.containsKey('documentUrl'))) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader('ID Document'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            final url =
                                user.metadata!['nidUrl'] ??
                                user.metadata!['idDocumentUrl'] ??
                                user.metadata!['documentUrl'];
                            if (url != null) {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      InteractiveViewer(
                                        child: Image.network(url),
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.border.withOpacity(0.5),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                user.metadata!['nidUrl'] ??
                                    user.metadata!['idDocumentUrl'] ??
                                    user.metadata!['documentUrl'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image_outlined,
                                          size: 40,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Failed to load image',
                                          style: GoogleFonts.inter(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                              ),
                            ),
                          ),
                        ),
                      ] else if (user.verificationStatus ==
                          VerificationStatus.pending) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader('ID Document'),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.warning.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'No document uploaded',
                                style: GoogleFonts.inter(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (user.userType == UserType.seller &&
                          user.trialStartDate != null) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader('Trial Period'),
                        _buildInfoTile(
                          Icons.timer_outlined,
                          'Trial Started',
                          user.trialStartDate!.toString().split('.')[0],
                        ),
                        const SizedBox(height: 8),
                        _buildTrialProgress(user.trialStartDate!),
                      ],

                      if (user.userType == UserType.seller) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Shipping Rules',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showManageShippingRules(user);
                              },
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Manage'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Footer Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (user.verificationStatus ==
                        VerificationStatus.pending) ...[
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _rejectUser(user);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _approveUser(user);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Text('Approve'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openChat(user);
                        },
                        icon: const Icon(Icons.message, size: 16),
                        label: const Text('Message'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
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
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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

  void _showPushNotificationDialog(UserModel user) {
    final titleController = TextEditingController(text: 'Update from Admin');
    final bodyController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gradient Header
                Container(
                  padding: const EdgeInsets.all(20),
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
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Send Notification',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Notification Title',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: bodyController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          hintText: 'Enter message content...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (bodyController.text.isEmpty) return;
                                setDialogState(() => isLoading = true);
                                try {
                                  await FcmService.sendNotificationToUser(
                                    userId: user.id,
                                    title: titleController.text,
                                    body: bodyController.text,
                                    type: 'admin_direct',
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Notification sent successfully',
                                        ),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setDialogState(() => isLoading = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to send: $e'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        icon: isLoading
                            ? Container(
                                width: 16,
                                height: 16,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send, size: 18),
                        label: Text(isLoading ? 'Sending...' : 'Send Now'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.info, AppColors.info.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_shipping,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Shipping Rules',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: costController,
                      decoration: const InputDecoration(
                        labelText: 'Shipping Cost Per Kg',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: minFeeController,
                      decoration: const InputDecoration(
                        labelText: 'Minimum Shipping Fee',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.remove_circle_outline),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Direct editing of map rules will be available in the next update.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
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
                          _showSnackBar(
                            'Shipping rules updated',
                            AppColors.success,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      // Approve main verification status
      await UserService.updateVerificationStatus(
        user.id,
        VerificationStatus.verified,
      );

      // Approve detailed statuses as well for consistency
      await UserService.updateDetailedVerification(
        user.id,
        idStatus: VerificationStatus.verified,
        facialStatus: VerificationStatus.verified,
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.error, AppColors.error.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Reject Verification',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Please provide a reason for rejecting this user\'s verification. This will be sent to the user.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Rejection Reason',
                        hintText: 'e.g. ID document is blurry',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirm Rejection'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
