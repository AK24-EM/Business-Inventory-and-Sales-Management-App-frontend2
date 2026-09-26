import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../models/user_model.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';

/// SplashScreen is shown on app launch while Firebase resolves the auth state.
///
/// Firebase Auth persists sessions across app restarts. On cold start the SDK
/// needs a brief moment to rehydrate the session from secure storage before
/// emitting on [authStateChanges].  We wait for [AuthStatus] to leave its
/// [AuthStatus.initial] state, then the GoRouter redirect guard takes over
/// and navigates to the correct role home (or /login).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _controller.forward();

    _awaitAuthResolution();
  }

  /// Wait until Firebase has resolved the persisted session (status leaves
  /// [AuthStatus.initial]) and then hand off to the GoRouter redirect guard.
  ///
  /// A minimum display time of 1.5 s is enforced so the splash animation
  /// always completes before the transition.
  Future<void> _awaitAuthResolution() async {
    final auth = context.read<AuthProvider>();

    // Wait for both the minimum splash duration AND auth to be resolved.
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1500)),
      _waitForAuthResolution(auth),
    ]);

    if (!mounted) return;

    // GoRouter's refreshListenable will handle the actual navigation — we
    // only need to trigger a redirect by navigating off /splash.
    // Using replace so the user cannot navigate back to the splash.
    final role = auth.currentUser?.role;
    if (auth.isAuthenticated) {
      if (role != null && role.isStaff) {
        context.read<StoreProvider>().loadStores().catchError((_) {});
      }
      context.go(_homeRoute(role));
    } else {
      context.go('/login');
    }
  }

  Future<void> _waitForAuthResolution(AuthProvider auth) async {
    // If already resolved (not initial/loading), return immediately.
    if (auth.status != AuthStatus.initial && !auth.isLoading) return;

    // Otherwise wait for the provider to notify with a resolved state.
    await Future.any([
      // Poll every 100ms until resolved.
      Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return auth.status == AuthStatus.initial || auth.isLoading;
      }),
      // Timeout safety net — never hang on splash forever.
      Future.delayed(const Duration(seconds: 5)),
    ]);
  }

  String _homeRoute(UserRole? role) {
    return role?.homeRoute ?? '/login';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Smart Inventory & Sales',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white60),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
