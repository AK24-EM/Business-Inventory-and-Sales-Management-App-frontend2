import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';

class OwnerShell extends StatelessWidget {
  final Widget child;
  const OwnerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    if (isWide) return _buildSidebarLayout(context);
    return _buildBottomNavLayout(context);
  }

  Widget _buildBottomNavLayout(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexFromLocation(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => _navigate(context, i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: const Color(0xFF64748B),
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined, size: 22),
              activeIcon: Icon(Icons.dashboard_rounded, size: 22),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_outlined, size: 22),
              activeIcon: Icon(Icons.insights_rounded, size: 22),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.replay_rounded, size: 22),
              activeIcon: Icon(Icons.replay_rounded, size: 22),
              label: 'Restock',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.celebration_outlined, size: 22),
              activeIcon: Icon(Icons.celebration_rounded, size: 22),
              label: 'Festivals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_outlined, size: 22),
              activeIcon: Icon(Icons.smart_toy_rounded, size: 22),
              label: 'AI Insights',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarLayout(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(currentLocation: location),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith('/owner/analytics')) return 1;
    if (location.startsWith('/owner/restocking')) return 2;
    if (location.startsWith('/owner/festivals')) return 3;
    if (location.startsWith('/owner/ai-insights')) return 4;
    return 0;
  }

  void _navigate(BuildContext context, int i) {
    switch (i) {
      case 0:
        context.go('/owner');
        break;
      case 1:
        context.go('/owner/analytics');
        break;
      case 2:
        context.go('/owner/restocking');
        break;
      case 3:
        context.go('/owner/festivals');
        break;
      case 4:
        context.go('/owner/ai-insights');
        break;
    }
  }
}

class _Sidebar extends StatelessWidget {
  final String currentLocation;
  const _Sidebar({required this.currentLocation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.storefront_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('StoreIQ',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      Text('Owner Panel',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _NavItem(
                      icon: Icons.dashboard_outlined,
                      label: 'Dashboard',
                      route: '/owner',
                      currentLocation: currentLocation),
                  _NavItem(
                      icon: Icons.analytics_outlined,
                      label: 'Analytics',
                      route: '/owner/analytics',
                      currentLocation: currentLocation),
                  _NavItem(
                      icon: Icons.refresh_rounded,
                      label: 'Restocking',
                      route: '/owner/restocking',
                      currentLocation: currentLocation),
                  _NavItem(
                      icon: Icons.celebration_outlined,
                      label: 'Festival Demand',
                      route: '/owner/festivals',
                      currentLocation: currentLocation),
                  _NavItem(
                      icon: Icons.smart_toy_outlined,
                      label: 'AI Insights',
                      route: '/owner/ai-insights',
                      currentLocation: currentLocation),
                  _NavItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'Reports',
                      route: '/owner/reports',
                      currentLocation: currentLocation),
                  const Divider(),
                  _NavItem(
                      icon: Icons.store_outlined,
                      label: 'Stores',
                      route: '/owner/stores',
                      currentLocation: currentLocation),
                  _NavItem(
                      icon: Icons.people_outline,
                      label: 'Users',
                      route: '/owner/users',
                      currentLocation: currentLocation),
                  _NavItem(
                      icon: Icons.inventory_2_outlined,
                      label: 'Products',
                      route: '/owner/products',
                      currentLocation: currentLocation),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextButton.icon(
                onPressed: () => context.go('/owner/notifications'),
                icon: const Icon(Icons.notifications_outlined, size: 18),
                label: const Text('Notifications'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentLocation;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentLocation.startsWith(route) &&
        (route == '/owner'
            ? currentLocation == '/owner'
            : true);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go(route),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.textSecondary),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}
