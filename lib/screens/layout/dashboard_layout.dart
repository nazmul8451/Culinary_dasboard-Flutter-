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
import '../../services/message_service.dart';
import '../../controllers/dashboard_controller.dart';
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
        builder: (context, snapshot) {
          final totalUnread = snapshot.data ?? 0;
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
                          backgroundColor: AppColors.primary.withOpacity(0.1),
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
                const AdminMenuItem(
                  title: 'Support',
                  route: '/support',
                  icon: Icons.help_outline_rounded,
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
    });
  }
}
