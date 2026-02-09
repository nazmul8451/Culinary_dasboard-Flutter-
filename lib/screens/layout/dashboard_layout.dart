import 'package:flutter/material.dart';
import 'package:flutter_admin_scaffold/admin_scaffold.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../dashboard/overview_screen.dart';
import '../users/users_screen.dart';
import '../orders/orders_screen.dart';
import '../financial/financial_screen.dart';
import '../moderation/moderation_screen.dart';
import '../support/support_tickets_screen.dart';
import '../moderation/moderation_logs_screen.dart';
import '../communications/communications_screen.dart';
import '../auth/admin_management_screen.dart';
import '../../services/message_service.dart';
import '../../services/notification_service.dart';
import '../../controllers/dashboard_controller.dart';
import '../../services/support_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardLayout extends StatefulWidget {
  const DashboardLayout({super.key});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  final _authController = Get.find<AuthController>();
  final _dashboardController = Get.find<DashboardController>();

  void _onMenuItemSelected(AdminMenuItem item) {
    _dashboardController.changeRoute(item.route ?? '/dashboard');
  }

  Widget _getSelectedScreen(String route) {
    switch (route) {
      case '/dashboard':
        return const OverviewScreen();
      case '/users':
        return const UsersScreen();
      case '/orders':
        return const OrdersScreen();
      case '/financial':
        return const FinancialScreen();
      case '/moderation':
        return const ModerationScreen();
      case '/support':
        return const SupportTicketsScreen();
      case '/mod-logs':
        return const ModerationLogsScreen();
      case '/communications':
        return const CommunicationsScreen();
      case '/admin-mgmt':
        return const AdminManagementScreen();
      default:
        return const OverviewScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedRoute = _dashboardController.selectedRoute;
      return StreamBuilder<int>(
        stream: MessageService.getTotalUnreadCount(),
        builder: (context, msgSnapshot) {
          final totalUnread = msgSnapshot.data ?? 0;
          return StreamBuilder<int>(
            stream: SupportService.getNewTicketsCount(),
            builder: (context, supportSnapshot) {
              final unreadTickets = supportSnapshot.data ?? 0;
              return AdminScaffold(
                backgroundColor: AppColors.background,
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 1,
                  title: Text(
                    'Admin Dashboard',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.isMobile(context) ? 18 : 20,
                    ),
                  ),
                  actions: [
                    // Notifications Badge
                    StreamBuilder<int>(
                      stream: NotificationService.getUnreadCount(),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return _buildAppBarAction(
                          icon: Icons.notifications_none_rounded,
                          count: count,
                          onTap: () {
                            // Open notifications overlay or navigate
                          },
                        );
                      },
                    ),
                    // Messages Badge (Messenger style)
                    StreamBuilder<int>(
                      stream: MessageService.getTotalUnreadCount(),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return _buildAppBarAction(
                          icon: Icons.chat_bubble_outline_rounded,
                          count: count,
                          onTap: () {
                            _dashboardController.changeRoute('/communications');
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    // Admin Profile
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          if (!Responsive.isMobile(context))
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _authController.user?.email ?? 'Admin',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Administrator',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(width: 12),
                          PopupMenuButton<String>(
                            icon: CircleAvatar(
                              radius: Responsive.isMobile(context) ? 16 : 20,
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              child: Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: Responsive.isMobile(context) ? 20 : 24,
                              ),
                            ),
                            onSelected: (value) {
                              if (value == 'logout') {
                                _authController.logout();
                                Get.offAllNamed('/login');
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    const Icon(Icons.logout, size: 20),
                                    const SizedBox(width: 12),
                                    Text('Logout', style: GoogleFonts.inter()),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                sideBar: SideBar(
                  key: ValueKey(selectedRoute),
                  backgroundColor: AppColors.drawerBackground,
                  activeBackgroundColor: AppColors.primary,
                  activeIconColor: Colors.white,
                  activeTextStyle: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  iconColor: AppColors.drawerIconUnselected,
                  textStyle: GoogleFonts.inter(
                    color: AppColors.drawerTextUnselected,
                    fontWeight: FontWeight.w500,
                  ),
                  items: [
                    const AdminMenuItem(
                      title: 'Dashboard',
                      route: '/dashboard',
                      icon: Icons.grid_view_rounded,
                    ),
                    const AdminMenuItem(
                      title: 'Users',
                      route: '/users',
                      icon: Icons.people_outline_rounded,
                    ),
                    const AdminMenuItem(
                      title: 'Orders',
                      route: '/orders',
                      icon: Icons.shopping_bag_outlined,
                    ),
                    const AdminMenuItem(
                      title: 'Financial',
                      route: '/financial',
                      icon: Icons.bar_chart_rounded,
                    ),
                    AdminMenuItem(
                      title: unreadTickets > 0 ? 'Support 🔴' : 'Support',
                      route: '/support',
                      icon: unreadTickets > 0
                          ? Icons.help_rounded
                          : Icons.help_outline_rounded,
                    ),
                    const AdminMenuItem(
                      title: 'Moderation',
                      route: '/moderation',
                      icon: Icons.verified_user_rounded,
                    ),
                    AdminMenuItem(
                      title: totalUnread > 0
                          ? 'Messages ($totalUnread)'
                          : 'Messages',
                      route: '/communications',
                      icon: Icons.chat_bubble_outline_rounded,
                    ),
                    const AdminMenuItem(
                      title: 'Logs',
                      route: '/mod-logs',
                      icon: Icons.security_rounded,
                    ),
                    const AdminMenuItem(
                      title: 'Admin Setup',
                      route: '/admin-mgmt',
                      icon: Icons.admin_panel_settings_rounded,
                    ),
                  ],
                  selectedRoute: selectedRoute,
                  onSelected: _onMenuItemSelected,
                  header: Container(
                    height: 100,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.restaurant_menu,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Culinary Tales',
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Admin Console',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                body: _getSelectedScreen(selectedRoute)
                    .animate(key: ValueKey(selectedRoute))
                    .fadeIn(duration: 400.ms, curve: Curves.easeOut),
              );
            },
          );
        },
      );
    });
  }

  Widget _buildAppBarAction({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: Icon(icon, color: AppColors.textSecondary),
            onPressed: onTap,
          ),
          if (count > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
