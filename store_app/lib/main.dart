import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'routing/app_router.dart';
import 'services/auth_service.dart';
import 'services/inventory_service.dart';
import 'services/sales_service.dart';
import 'services/customer_service.dart';
import 'services/loyalty_service.dart';
import 'services/billing_service.dart';
import 'services/supplier_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = (details) {
    debugPrint('FlutterError: ${details.exception}');
  };

  runZonedGuarded(() {
    runApp(const StoreIQApp());
  }, (error, stack) {
    debugPrint('Uncaught: $error');
  });
}

class StoreIQApp extends StatelessWidget {
  const StoreIQApp({super.key});

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
        ProxyProvider2<InventoryService, CustomerService, SalesService>(
          update: (_, inv, cust, __) => SalesService(inv, cust),
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
