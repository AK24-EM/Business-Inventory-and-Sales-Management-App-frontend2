import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supplies Bearer tokens for the StoreIQ REST API.
///
/// Cloud Run verifies **Firebase ID tokens** via firebase-admin (legacy HS256
/// JWTs from POST /auth/login are still accepted if sent). Login does not
/// request a separate API password token.
class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  static const _apiTokenKey = 'api_bearer_token';
  static const _firebaseTokenKey = 'firebase_id_token';

  /// No-op kept for older call sites. REST uses the Firebase ID token.
  Future<void> setApiToken(String token) async {}

  /// Firebase ID token for `Authorization: Bearer` on Cloud Run.
  Future<String?> getToken({bool forceRefresh = false}) async {
    return getFirebaseToken(forceRefresh: forceRefresh);
  }

  Future<String?> getFirebaseToken({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      return await user.getIdToken(forceRefresh);
    } catch (_) {
      try {
        return await user.getIdToken(true);
      } catch (_) {
        return null;
      }
    }
  }

  Future<Map<String, dynamic>> getClaims({bool forceRefresh = false}) async {
    final result = await FirebaseAuth.instance.currentUser
        ?.getIdTokenResult(forceRefresh);
    return result?.claims ?? {};
  }

  Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_apiTokenKey);
      await prefs.remove(_firebaseTokenKey);
    } catch (_) {}
  }
}
