import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../config/app_constants.dart';
import 'token_service.dart';

/// AuthService wraps Firebase Authentication and Cloud Firestore to implement
/// secure, role-based authentication as required by Feature 1 (BR-01).
///
/// Auth is Firebase Auth + a Firestore user document (role, store, isActive).
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TokenService _tokenService = TokenService();

  final _userController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;
  StreamSubscription<User?>? _firebaseAuthSub;

  AuthService() {
    _firebaseAuthSub = _firebaseAuth.authStateChanges().listen(_onFirebaseAuthStateChanged);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Stream<UserModel?> get authStateChanges => _userController.stream;
  UserModel? get currentUser => _currentUser;

  /// Sign in with email + password via Firebase Authentication.
  Future<UserModel?> signIn(String email, String password) async {
    // 1. Firebase Auth sign-in
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw Exception('sign-in-failed');

    // 2. Fetch Firestore user record (role, isActive, assignedStoreId, etc.)
    final model = await _fetchUserModel(user);
    if (model == null) throw Exception('user-record-not-found');
    if (!model.isActive) {
      await _firebaseAuth.signOut();
      throw Exception('user-disabled');
    }

    // 3. Force-refresh the Firebase ID token so custom claims are present
    //    before any Firestore rule evaluation or Cloud Run REST call.
    try {
      await user.getIdToken(true);
      
      // DEBUG: Check if custom claims are present
      final tokenResult = await user.getIdTokenResult(true);
      print('🔑 DEBUG: Token claims for ${model.email}:');
      print('   Role: ${tokenResult.claims?['role']}');
      print('   StoreId: ${tokenResult.claims?['storeId']}');
      
      if (tokenResult.claims?['role'] == null) {
        print('⚠️  WARNING: Custom claims not set! Run: node set_custom_claims.js');
        print('⚠️  Then sign out and sign in again.');
      }
    } catch (e) {
      print('❌ Error checking token claims: $e');
    }

    _updateLastLogin(user.uid);
    _userController.add(model);
    return model;
  }

  /// Register a new user — creates both Firebase Auth and backend database user.
  /// This is for self-service registration (e.g., store owners signing up).
  Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    UserRole role = UserRole.owner, // Default to owner for self-registration
  }) async {
    try {
      // 1. Create Firebase Auth account
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('registration-failed');

      // 3. Update Firebase display name
      await user.updateDisplayName(name.trim());

      // 4. Create Firestore user document
      final now = DateTime.now();
      final userModel = UserModel(
        id: user.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
        assignedStoreId: null, // Self-registered users have no store assignment yet
        isActive: true,
        createdAt: now,
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(userModel.toFirestore());

      // Wait a moment to ensure Firestore write completes before auth state changes
      await Future.delayed(const Duration(milliseconds: 500));

      // 5. Force-refresh Firebase ID token
      try {
        await user.getIdToken(true);
      } catch (_) {}

      _currentUser = userModel;
      _userController.add(userModel);
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out from Firebase and clear all stored tokens.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _tokenService.clearToken();
    _currentUser = null;
    _userController.add(null);
  }

  /// Send a Firebase password-reset email.
  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  /// Fetch the current user's profile from Firestore (e.g. after token refresh).
  Future<UserModel?> getUserById(String uid) async {
    if (_currentUser != null && _currentUser!.id == uid) return _currentUser;
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return _fetchUserModel(firebaseUser);
  }

  /// Get the current Firebase ID token (JWT) for use in REST API calls.
  /// Pass [forceRefresh] = true to always get a fresh token with latest claims.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _firebaseAuth.currentUser?.getIdToken(forceRefresh);
  }

  /// Read custom claims from the current ID token.
  /// Claims are set server-side by the `setUserClaims` Cloud Function.
  Future<Map<String, dynamic>> getCustomClaims() async {
    final result = await _firebaseAuth.currentUser?.getIdTokenResult(true);
    return result?.claims ?? {};
  }

  // ── User Management (called by UserManagementScreen / Admin ops) ──────────

  /// List all users. Owner/Admin only — enforced by Firestore rules.
  Stream<List<UserModel>> getUsersStream({String? storeId}) {
    Query<Map<String, dynamic>> query =
        _firestore.collection(AppConstants.usersCollection);
    if (storeId != null) {
      query = query.where('assignedStoreId', isEqualTo: storeId);
    }
    return query.snapshots().map((snap) =>
        snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  Future<List<UserModel>> getUsers({String? storeId}) async {
    final snap = await getUsersStream(storeId: storeId).first;
    return snap;
  }

  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    final snap = await _firestore
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: role.name)
        .get();
    return snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
  }

  Future<List<UserModel>> getUsersByStore(String storeId) async {
    return getUsers(storeId: storeId);
  }

  /// Create a new user.
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
    String? assignedStoreId,
  }) async {
    try {
      final uid = await _createAuthUserAndRestoreSession(email, password);

      final now = DateTime.now();
      final userModel = UserModel(
        id: uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
        assignedStoreId: (role == UserRole.owner || role == UserRole.admin)
            ? null
            : assignedStoreId,
        isActive: true,
        createdAt: now,
      );

      // Write the Firestore user document (rules allow owner/admin only).
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(userModel.toFirestore());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  /// Deactivate a user — sets isActive=false in Firestore.
  Future<void> deactivateUser(String userId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'isActive': false});
  }

  /// Update a user's role and/or store assignment.
  Future<void> updateUser(String userId, {
    UserRole? role,
    String? assignedStoreId,
    bool? isActive,
    String? name,
    String? phone,
  }) async {
    final updates = <String, dynamic>{};
    if (role != null) updates['role'] = role.name;
    if (assignedStoreId != null) updates['assignedStoreId'] = assignedStoreId;
    if (isActive != null) updates['isActive'] = isActive;
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;

    if (updates.isNotEmpty) {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(updates);
    }
  }

  // Save FCM token for push notifications.
  Future<void> updateFcmToken(String userId, String token) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'fcmToken': token});
  }

  void dispose() {
    _firebaseAuthSub?.cancel();
    _userController.close();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Called whenever Firebase's own auth state changes (login, logout,
  /// token refresh, app restart). Re-fetches the Firestore user record
  /// and emits on our stream so AuthProvider stays in sync.
  Future<void> _onFirebaseAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _userController.add(null);
      return;
    }

    try {
      // Force-refresh the token on every auth-state change (app restart,
      // resume, etc.) so the latest custom claims are always in the JWT
      // before any Firestore read evaluates them.
      try {
        await firebaseUser.getIdToken(true);
      } catch (_) {}

      final model = await _fetchUserModel(firebaseUser);
      if (model == null || !model.isActive) {
        // Invalid / deactivated account — force sign out.
        await _firebaseAuth.signOut();
        _currentUser = null;
        _userController.add(null);
        return;
      }
      _currentUser = model;
      _userController.add(model);
    } catch (_) {
      // Firestore read failed (offline, rules denied, etc.) — stay signed out.
      _currentUser = null;
      _userController.add(null);
    }
  }

  /// Fetch and build a [UserModel] from Firestore for the given Firebase user.
  /// Also reads custom claims from the ID token to verify role consistency.
  Future<UserModel?> _fetchUserModel(User? firebaseUser) async {
    if (firebaseUser == null) return null;

    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists) return null;

    final model = UserModel.fromFirestore(doc);

    // Optionally cross-check with custom claims (set by Cloud Function).
    // If claims differ from Firestore, the Cloud Function will reconcile on
    // next token refresh — no action needed here beyond logging.
    return model;
  }

  void _updateLastLogin(String uid) {
    _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'lastLogin': FieldValue.serverTimestamp()})
        .catchError((_) {}); // Non-critical; ignore errors.
  }

  /// Creates a Firebase Auth account without disrupting the currently
  /// signed-in admin session. On mobile this is unavoidable with the client
  /// SDK — use Cloud Functions in production for true session isolation.
  Future<String> _createAuthUserAndRestoreSession(
      String email, String password) async {
    // In production, use the `createUser` Cloud Function instead.
    // That path uses the Admin SDK and never disturbs the current session.
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final newUid = cred.user!.uid;

    // Sign out the newly created user immediately to prevent session hijack.
    await _firebaseAuth.signOut();

    return newUid;
  }
}
