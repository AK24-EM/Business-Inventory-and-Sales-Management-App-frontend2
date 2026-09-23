import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/employee/employee_shell.dart';
import '../screens/employee/employee_dashboard_screen.dart';
import '../screens/employee/pos_screen.dart';
import '../screens/employee/inventory_screen.dart';
import '../screens/employee/customers_screen.dart';
import '../screens/employee/loyalty_screen.dart';
import '../screens/employee/enhanced_loyalty_screen.dart';
import '../screens/employee/sale_history_screen.dart';
import '../screens/manager/manager_shell.dart';
import '../screens/manager/manager_dashboard_screen.dart';
import '../screens/manager/stock_transfer_screen.dart';
import '../screens/manager/stock_adjustment_screen.dart';
import '../screens/manager/supplier_screen.dart';
import '../screens/manager/enhanced_supplier_screen.dart';
import '../screens/manager/purchase_order_screen.dart';
import '../screens/manager/customer_analytics_screen.dart';
import '../screens/manager/damaged_products_screen.dart';
import '../screens/manager/manager_reports_screen.dart';
import '../screens/manager/sales_analytics_screen.dart';
import '../screens/manager/manager_analytics_hub_screen.dart';
import '../screens/manager/manager_restocking_screen.dart';
import '../screens/manager/manager_festival_planning_screen.dart';
import '../screens/owner/owner_shell.dart';
import '../screens/owner/owner_dashboard_screen.dart';
import '../screens/owner/analytics_screen.dart';
import '../screens/owner/restocking_screen.dart';
import '../screens/owner/festival_screen.dart';
import '../screens/owner/ai_insights_screen.dart';
import '../screens/owner/owner_reports_screen.dart';
import '../screens/owner/store_management_screen.dart';
import '../screens/owner/user_management_screen.dart';
import '../screens/owner/product_management_screen.dart';
import '../screens/shared/notifications_screen.dart';
import '../screens/shared/billing_screen.dart';
import '../models/user_model.dart';

class AppRouter {
  /// Creates the GoRouter.
  ///
  /// [refreshListenable] is set to [AuthProvider] so that any call to
  /// [notifyListeners] inside AuthProvider (triggered by Firebase auth state
  /// changes) automatically causes the router to re-evaluate its redirect
  /// guard.  This means sign-in/sign-out navigates immediately without any
  /// manual `context.go(...)` calls in the UI.
  static GoRouter createRouter(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return GoRouter(
      initialLocation: '/splash',
      // Re-run the redirect every time AuthProvider notifies.
      // This handles: login, logout, token expiry, account deactivation.
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isInitialising = authProvider.status == AuthStatus.initial;
        final isLoading = authProvider.isLoading;

        final path = state.uri.toString();
        final isSplash = path == '/splash';
        final isLogin = path == '/login';
        final isRegister = path == '/register';

        // Let the splash screen handle itself while Firebase initialises.
        if (isSplash || isInitialising || isLoading) return null;

        // Not authenticated — send to login (unless already there or on register).
        if (!isLoggedIn && !isLogin && !isRegister) return '/login';

        // Authenticated — redirect away from login/splash/register to the role home.
        if (isLoggedIn && (isLogin || isSplash || isRegister)) {
          return _getHomeRoute(authProvider.currentUser?.role);
        }

        // Role-based route guard: prevent an employee from visiting /owner, etc.
        if (isLoggedIn) {
          final role = authProvider.currentUser?.role;
          if (path.startsWith('/owner') && role != UserRole.owner && role != UserRole.admin) {
            return _getHomeRoute(role);
          }
          if (path.startsWith('/manager') && role != UserRole.manager) {
            return _getHomeRoute(role);
          }
          if (path.startsWith('/employee') &&
              role != UserRole.employee) {
            return _getHomeRoute(role);
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),

        // ── Employee Routes ──────────────────────────────────────────────
        ShellRoute(
          builder: (context, state, child) => EmployeeShell(child: child),
          routes: [
            GoRoute(
              path: '/employee',
              builder: (context, state) => const EmployeeDashboardScreen(),
            ),
            GoRoute(
              path: '/employee/pos',
              builder: (context, state) => const PosScreen(),
            ),
            GoRoute(
              path: '/employee/inventory',
              builder: (context, state) => const InventoryScreen(),
            ),
            GoRoute(
              path: '/employee/customers',
              builder: (context, state) => const CustomersScreen(),
            ),
            GoRoute(
              path: '/employee/loyalty',
              builder: (context, state) => const LoyaltyScreen(),
            ),
            GoRoute(
              path: '/employee/loyalty-enhanced',
              builder: (context, state) => const EnhancedLoyaltyScreen(),
            ),
            GoRoute(
              path: '/employee/sales',
              builder: (context, state) => const SaleHistoryScreen(),
            ),
            GoRoute(
              path: '/employee/billing',
              builder: (context, state) => const BillingScreen(),
            ),
            GoRoute(
              path: '/employee/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
          ],
        ),

        // ── Manager Routes ───────────────────────────────────────────────
        ShellRoute(
          builder: (context, state, child) => ManagerShell(child: child),
          routes: [
            GoRoute(
              path: '/manager',
              builder: (context, state) => const ManagerDashboardScreen(),
            ),
            GoRoute(
              path: '/manager/inventory',
              builder: (context, state) => const InventoryScreen(),
            ),
            GoRoute(
              path: '/manager/transfers',
              builder: (context, state) => const StockTransferScreen(),
            ),
            GoRoute(
              path: '/manager/adjustments',
              builder: (context, state) => const StockAdjustmentScreen(),
            ),
            GoRoute(
              path: '/manager/suppliers',
              builder: (context, state) => const SupplierScreen(),
            ),
            GoRoute(
              path: '/manager/suppliers-enhanced',
              builder: (context, state) => const EnhancedSupplierScreen(),
            ),
            GoRoute(
              path: '/manager/purchase-orders',
              builder: (context, state) => const PurchaseOrderScreen(),
            ),
            GoRoute(
              path: '/manager/customer-analytics',
              builder: (context, state) => const CustomerAnalyticsScreen(),
            ),
            GoRoute(
              path: '/manager/damaged',
              builder: (context, state) => const DamagedProductsScreen(),
            ),
            GoRoute(
              path: '/manager/reports',
              builder: (context, state) => const ManagerReportsScreen(),
            ),
            GoRoute(
              path: '/manager/sales-analytics',
              builder: (context, state) => const SalesAnalyticsScreen(),
            ),
            GoRoute(
              path: '/manager/analytics',
              builder: (context, state) => const ManagerAnalyticsHubScreen(),
            ),
            GoRoute(
              path: '/manager/billing',
              builder: (context, state) => const BillingScreen(),
            ),
            GoRoute(
              path: '/manager/restocking',
              builder: (context, state) => const ManagerRestockingScreen(),
            ),
            GoRoute(
              path: '/manager/festivals',
              builder: (context, state) => const ManagerFestivalPlanningScreen(),
            ),
            GoRoute(
              path: '/manager/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
          ],
        ),

        // ── Owner / Admin Routes ─────────────────────────────────────────
        ShellRoute(
          builder: (context, state, child) => OwnerShell(child: child),
          routes: [
            GoRoute(
              path: '/owner',
              builder: (context, state) => const OwnerDashboardScreen(),
            ),
            GoRoute(
              path: '/owner/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
            GoRoute(
              path: '/owner/restocking',
              builder: (context, state) => const RestockingScreen(),
            ),
            GoRoute(
              path: '/owner/festivals',
              builder: (context, state) => const FestivalScreen(),
            ),
            GoRoute(
              path: '/owner/ai-insights',
              builder: (context, state) => const AiInsightsScreen(),
            ),
            GoRoute(
              path: '/owner/reports',
              builder: (context, state) => const OwnerReportsScreen(),
            ),
            GoRoute(
              path: '/owner/sales-analytics',
              builder: (context, state) => const SalesAnalyticsScreen(),
            ),
            GoRoute(
              path: '/owner/stores',
              builder: (context, state) => const StoreManagementScreen(),
            ),
            GoRoute(
              path: '/owner/users',
              builder: (context, state) => const UserManagementScreen(),
            ),
            GoRoute(
              path: '/owner/products',
              builder: (context, state) => const ProductManagementScreen(),
            ),
            GoRoute(
              path: '/owner/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
          ],
        ),
      ],
    );
  }

  static String _getHomeRoute(UserRole? role) {
    switch (role) {
      case UserRole.owner:
      case UserRole.admin:
        return '/owner';
      case UserRole.manager:
        return '/manager';
      case UserRole.employee:
        return '/employee';
      default:
        return '/login';
    }
  }
}
