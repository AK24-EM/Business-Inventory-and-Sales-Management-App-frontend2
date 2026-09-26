import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// AuthProvider is the single source of truth for authentication state in
/// the Flutter UI layer.
///
/// It listens to [AuthService.authStateChanges] which mirrors Firebase's own
/// [FirebaseAuth.authStateChanges] stream.  Every time the Firebase session
/// changes — sign-in, sign-out, token refresh, app restart — this provider
/// updates and notifies the GoRouter (via refreshListenable) and all widgets
/// that depend on auth state.
///
/// Role and store isolation:
///   - [currentUser.role] drives route access in AppRouter
///   - [currentUser.assignedStoreId] is passed down to data providers
///   - Custom JWT claims (set by Cloud Functions) carry the same values
///     so Cloud Run and Firestore rules enforce the same access server-side
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final TokenService _tokenService = TokenService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthProvider(this._authService) {
    // The stream emits whenever Firebase auth state changes (login/logout/
    // token refresh/app restart). Null = not signed in.
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  // ── Auth operations ───────────────────────────────────────────────────────

  Future<bool> signIn(String email, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _currentUser = await _authService.signIn(email, password);

      if (_currentUser != null) {
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Invalid credentials';
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = _mapAuthError(e.code);
      notifyListeners();
      return false;
    } on Exception catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = _mapAuthError(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _currentUser = await _authService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      if (_currentUser != null) {
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Registration failed';
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = _mapAuthError(e.code);
      debugPrint('❌ Registration FirebaseAuthException: ${e.code} - ${e.message}');
      notifyListeners();
      return false;
    } on Exception catch (e) {
      _status = AuthStatus.unauthenticated;
      final msg = e.toString().replaceFirst('Exception: ', '');
      _errorMessage = msg;
      debugPrint('❌ Registration Exception: $msg');
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Registration failed: $e';
      debugPrint('❌ Registration error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    await _tokenService.clearToken();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Force-refresh the Firebase ID token.  Call this after the admin
  /// updates a user's role via the Cloud Function so the new custom claims
  /// are reflected immediately without signing out.
  Future<void> refreshToken() async {
    try {
      await _tokenService.getToken(forceRefresh: true);
      // Re-fetch the user record in case Firestore data changed too.
      final uid = _currentUser?.id;
      if (uid != null) {
        final updated = await _authService.getUserById(uid);
        if (updated != null && updated.isActive) {
          _currentUser = updated;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _onAuthStateChanged(UserModel? user) async {
    if (user == null) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    if (!user.isActive) {
      // Account deactivated — force sign out.
      await _authService.signOut();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Account is inactive. Contact your administrator.';
      notifyListeners();
      return;
    }

    _currentUser = user;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  String _mapAuthError(String error) {
    // Firebase Auth exception codes (FirebaseAuthException.code)
    if (error.contains('user-not-found') ||
        error.contains('invalid-credential') ||
        error.contains('wrong-password')) {
      return 'Incorrect email or password.';
    }
    if (error.contains('invalid-email')) return 'Invalid email address.';
    if (error.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (error.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (error.contains('user-disabled') ||
        error.contains('user-record-not-found') ||
        error.contains('user-disabled')) {
      return 'This account has been disabled.';
    }
    if (error.contains('too-many-requests')) {
      return 'Too many attempts. Try again later.';
    }
    if (error.contains('network-request-failed')) {
      return 'No internet connection.';
    }
    if (error.contains('unauthenticated')) {
      return 'Session expired. Please sign in again.';
    }
    if (error.contains('permission-denied')) {
      return 'You do not have permission to perform this action.';
    }
    if (error.contains('sign-in-failed')) {
      return 'Sign in failed. Please try again.';
    }
    return 'Sign in failed. Please try again.';
  }
}
