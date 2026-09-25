import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/store_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/product_provider.dart';
import 'providers/loyalty_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/analytics_provider.dart';
import 'routing/app_router.dart';
import 'services/auth_service.dart';
import 'services/inventory_service.dart';
import 'services/sales_service.dart';
import 'services/customer_service.dart';
import 'services/loyalty_service.dart';
import 'services/billing_service.dart';
import 'services/supplier_service.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';

void main() {
  // IMPORTANT: runZonedGuarded must wrap EVERYTHING including ensureInitialized
  // so that the binding, Firebase init, and runApp all share the same zone.
  // Previously ensureInitialized() ran in the root zone while runApp() ran in
  // the guarded zone — causing "FlutterError: Zone mismatch".
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ─── Firestore Web: Disable offline persistence ────────────────────────
    // Offline persistence is not supported on web without IndexedDB multi-tab
    // configuration. Disabling it prevents the b815/ca9 WatchChangeAggregator
    // assertion crash in Firebase JS SDK 11.x on WebSocket reconnects.
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
        sslEnabled: true,
      );
    }
    // ────────────────────────────────────────────────────────────────────────

    FlutterError.onError = (details) {
      debugPrint('FlutterError: ${details.exception}');
    };

    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();

    runApp(StoreIQApp(notificationService: notificationService));
  }, (error, stack) {
    debugPrint('Uncaught: $error\n$stack');
  });
}

class StoreIQApp extends StatelessWidget {
  final NotificationService notificationService;
  
  const StoreIQApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core services
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<InventoryService>(create: (_) => InventoryService()),
        Provider<CustomerService>(create: (_) => CustomerService()),
        Provider<LoyaltyService>(create: (_) => LoyaltyService()),
        Provider<BillingService>(create: (_) => BillingService()),
        Provider<SupplierService>(create: (_) => SupplierService()),
        Provider<NotificationService>.value(value: notificationService),
        ProxyProvider2<InventoryService, CustomerService, SalesService>(
          update: (_, inv, cust, __) => SalesService(inv, cust),
        ),
        ProxyProvider3<SalesService, InventoryService, CustomerService, AnalyticsService>(
          update: (_, sales, inv, cust, __) => AnalyticsService(sales, inv, cust),
        ),

        // State providers
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (ctx) => AuthProvider(ctx.read<AuthService>()),
          update: (ctx, svc, prev) => prev ?? AuthProvider(svc),
        ),
        ChangeNotifierProvider<StoreProvider>(
          create: (_) => StoreProvider(),
        ),
        ChangeNotifierProxyProvider<InventoryService, InventoryProvider>(
          create: (ctx) => InventoryProvider(ctx.read<InventoryService>()),
          update: (ctx, svc, prev) => prev ?? InventoryProvider(svc),
        ),
        ChangeNotifierProxyProvider<SalesService, SalesProvider>(
          create: (ctx) => SalesProvider(ctx.read<SalesService>()),
          update: (ctx, svc, prev) => prev ?? SalesProvider(svc),
        ),
        ChangeNotifierProxyProvider<AnalyticsService, AnalyticsProvider>(
          create: (ctx) => AnalyticsProvider(ctx.read<AnalyticsService>()),
          update: (ctx, svc, prev) => prev ?? AnalyticsProvider(svc),
        ),
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => ProductProvider(),
        ),
        ChangeNotifierProxyProvider<LoyaltyService, LoyaltyProvider>(
          create: (ctx) => LoyaltyProvider(ctx.read<LoyaltyService>()),
          update: (ctx, svc, prev) => prev ?? LoyaltyProvider(svc),
        ),
        ChangeNotifierProxyProvider<SupplierService, SupplierProvider>(
          create: (ctx) => SupplierProvider(ctx.read<SupplierService>()),
          update: (ctx, svc, prev) => prev ?? SupplierProvider(svc),
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter.createRouter(context);
          return MaterialApp.router(
            title: 'StoreIQ',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
