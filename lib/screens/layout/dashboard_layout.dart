import 'package:flutter/material.dart';
import 'package:flutter_admin_scaffold/admin_scaffold.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../dashboard/overview_screen.dart';
import '../users/users_screen.dart';
import '../orders/orders_screen.dart';
import '../financial/financial_screen.dart';
import '../moderation/moderation_screen.dart';

class DashboardLayout extends StatefulWidget {
  const DashboardLayout({super.key});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  final _authController = Get.find<AuthController>();
  Widget _selectedScreen = const OverviewScreen();
  String _selectedRoute = '/dashboard';

  void _onMenuItemSelected(AdminMenuItem item) {
    setState(() {
      _selectedRoute = item.route ?? '/dashboard';
      switch (item.route) {
        case '/dashboard':
          _selectedScreen = const OverviewScreen();
          break;
        case '/users':
          _selectedScreen = const UsersScreen();
          break;
        case '/orders':
          _selectedScreen = const OrdersScreen();
          break;
        case '/financial':
          _selectedScreen = const FinancialScreen();
          break;
        case '/moderation':
          _selectedScreen = const ModerationScreen();
          break;
        default:
          _selectedScreen = const OverviewScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Culinary Admin Dashboard',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Admin Profile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _authController.user?.email ?? 'Admin',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Administrator',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  icon: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.person, color: AppColors.primary),
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
        backgroundColor: Colors.white,
        activeBackgroundColor: AppColors.primary.withOpacity(0.1),
        activeIconColor: AppColors.primary,
        activeTextStyle: GoogleFonts.inter(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        iconColor: AppColors.textSecondary,
        textStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        items: const [
          AdminMenuItem(
            title: 'Dashboard',
            route: '/dashboard',
            icon: Icons.dashboard,
          ),
          AdminMenuItem(
            title: 'User Management',
            route: '/users',
            icon: Icons.people,
          ),
          AdminMenuItem(
            title: 'Order Management',
            route: '/orders',
            icon: Icons.shopping_bag,
          ),
          AdminMenuItem(
            title: 'Financial',
            route: '/financial',
            icon: Icons.attach_money,
          ),
          AdminMenuItem(
            title: 'Content Moderation',
            route: '/moderation',
            icon: Icons.verified_user,
          ),
        ],
        selectedRoute: _selectedRoute,
        onSelected: _onMenuItemSelected,
        header: Container(
          height: 100,
          width: double.infinity,
          color: AppColors.primary,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.restaurant_menu,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  'Culinary Tales',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _selectedScreen,
    );
  }
}
