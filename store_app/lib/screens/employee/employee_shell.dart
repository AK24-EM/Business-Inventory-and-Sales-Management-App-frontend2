import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmployeeShell extends StatelessWidget {
  final Widget child;
  const EmployeeShell({super.key, required this.child});

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
          selectedItemColor: const Color(0xFF2563EB), // Vibrant blue matching inspiration
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
              icon: Icon(Icons.point_of_sale_outlined, size: 22),
              activeIcon: Icon(Icons.point_of_sale_rounded, size: 22),
              label: 'POS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined, size: 22),
              activeIcon: Icon(Icons.inventory_2_rounded, size: 22),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_rounded, size: 22),
              activeIcon: Icon(Icons.insights_rounded, size: 22),
              label: 'Owner Hub',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.badge_outlined, size: 22),
              activeIcon: Icon(Icons.badge_rounded, size: 22),
              label: 'Customers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none_rounded, size: 22),
              activeIcon: Icon(Icons.notifications_rounded, size: 22),
              label: 'Alerts & PO',
            ),
          ],
        ),
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location == '/employee/pos' || location.startsWith('/employee/pos')) return 0;
    if (location.startsWith('/employee/inventory')) return 1;
    if (location == '/employee' || location.startsWith('/employee/dashboard')) return 2;
    if (location.startsWith('/employee/customers')) return 3;
    if (location.startsWith('/employee/sales') || location.startsWith('/employee/loyalty')) return 4;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/employee/pos');
        break;
      case 1:
        context.go('/employee/inventory');
        break;
      case 2:
        context.go('/employee');
        break;
      case 3:
        context.go('/employee/customers');
        break;
      case 4:
        context.go('/employee/sales');
        break;
    }
  }
}
