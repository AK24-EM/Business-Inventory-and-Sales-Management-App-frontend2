import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManagerShell extends StatelessWidget {
  final Widget child;
  const ManagerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final int selectedIndex = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(
              color: Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (i) => _navigate(context, i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFF2563EB), // Vibrant blue matching enterprise UI
          unselectedItemColor: const Color(0xFF64748B), // Slate 500
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
              label: 'Manager Hub',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined, size: 22),
              activeIcon: Icon(Icons.inventory_2_rounded, size: 22),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz_rounded, size: 22),
              activeIcon: Icon(Icons.swap_horiz_rounded, size: 22),
              label: 'Transfers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined, size: 22),
              activeIcon: Icon(Icons.local_shipping_rounded, size: 22),
              label: 'Procurement',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_graph_outlined, size: 22),
              activeIcon: Icon(Icons.auto_graph_rounded, size: 22),
              label: 'Analytics',
            ),
          ],
        ),
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith('/manager/inventory')) {
      return 1;
    }
    if (location.startsWith('/manager/transfers') ||
        location.startsWith('/manager/adjustments')) {
      return 2;
    }
    if (location.startsWith('/manager/purchase-orders') ||
        location.startsWith('/manager/suppliers') ||
        location.startsWith('/manager/damaged') ||
        location.startsWith('/manager/restocking')) {
      return 3;
    }
    if (location.startsWith('/manager/reports') ||
        location.startsWith('/manager/sales-analytics') ||
        location.startsWith('/manager/customer-analytics') ||
        location.startsWith('/manager/festivals') ||
        location.startsWith('/manager/analytics')) {
      return 4;
    }
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/manager');
        break;
      case 1:
        context.go('/manager/inventory');
        break;
      case 2:
        context.go('/manager/transfers');
        break;
      case 3:
        context.go('/manager/purchase-orders');
        break;
      case 4:
        context.go('/manager/analytics');
        break;
    }
  }
}
