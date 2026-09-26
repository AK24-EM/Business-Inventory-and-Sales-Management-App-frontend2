import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../config/app_constants.dart';
import 'token_service.dart';

/// AuthService wraps Firebase Authentication and Cloud Firestore to implement
/// secure, role-based authentication as required by Feature 1 (BR-01).
///
/// Auth flow:
///   - Register → customers only (self-service)
///   - Login → shared for all roles; landing is decided from Firestore `role`
///   - Manager / employee accounts → created by owner via Cloud Function
///   - Real-time: Firestore `users/{uid}` snapshot keeps role/isActive in sync
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'asia-south1');
  final TokenService _tokenService = TokenService();

  final _userController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;
  StreamSubscription<User?>? _firebaseAuthSub;
  StreamSubscription<DocumentSnapshot>? _userDocSub;

  AuthService() {
    _firebaseAuthSub =
        _firebaseAuth.authStateChanges().listen(_onFirebaseAuthStateChanged);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Stream<UserModel?> get authStateChanges => _userController.stream;
  UserModel? get currentUser => _currentUser;

  /// Sign in with email + password via Firebase Authentication.
  /// Role / home route come from the Firestore user document (GCP source of truth).
  Future<UserModel?> signIn(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw Exception('sign-in-failed');

    final model = await _fetchUserModel(user);
    if (model == null) throw Exception('user-record-not-found');
    if (!model.isActive) {
      await _firebaseAuth.signOut();
      throw Exception('user-disabled');
    }

    try {
      await user.getIdToken(true);
      final tokenResult = await user.getIdTokenResult(true);
      if (tokenResult.claims?['role'] == null) {
        // Claims sync via onUserWritten Cloud Function; next refresh picks them up.
      }
    } catch (_) {}

    _updateLastLogin(user.uid);
    _attachUserDocListener(user.uid);
    _currentUser = model;
    _userController.add(model);
    return model;
  }

  /// Customer self-registration only. Staff (manager/employee) must be created
  /// by the owner through User Management → Cloud Function `createUser`.
  Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('registration-failed');

      await user.updateDisplayName(name.trim());

      final now = DateTime.now();
      final userModel = UserModel(
        id: user.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: UserRole.customer,
        assignedStoreId: null,
        isActive: true,
        createdAt: now,
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(userModel.toFirestore());

      // Give Cloud Function `onUserWritten` a moment to set JWT claims.
      await Future.delayed(const Duration(milliseconds: 400));
      try {
        await user.getIdToken(true);
      } catch (_) {}

      _attachUserDocListener(user.uid);
      _currentUser = userModel;
      _userController.add(userModel);
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _userDocSub?.cancel();
    _userDocSub = null;
    await _firebaseAuth.signOut();
    await _tokenService.clearToken();
    _currentUser = null;
    _userController.add(null);
  }

  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserModel?> getUserById(String uid) async {
    if (_currentUser != null && _currentUser!.id == uid) return _currentUser;
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return _fetchUserModel(firebaseUser);
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _firebaseAuth.currentUser?.getIdToken(forceRefresh);
  }

  Future<Map<String, dynamic>> getCustomClaims() async {
    final result = await _firebaseAuth.currentUser?.getIdTokenResult(true);
    return result?.claims ?? {};
  }

  // ── User Management (owner/admin via Cloud Functions) ─────────────────────

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

  /// Create manager/employee via GCP Cloud Function (Admin SDK).
  /// Does not disturb the owner's session; sets Auth + Firestore + JWT claims.
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
    String? assignedStoreId,
  }) async {
    if (!role.isOwnerAssignable) {
      throw Exception(
          'Only manager or employee accounts can be assigned by the owner.');
    }

    try {
      final callable = _functions.httpsCallable('createUser');
      final result = await callable.call(<String, dynamic>{
        'email': email.trim(),
        'password': password,
        'name': name.trim(),
        'phone': phone.trim(),
        'role': role.name,
        'assignedStoreId': assignedStoreId,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      final uid = data['uid'] as String;
      return UserModel(
        id: uid,
        name: data['name'] as String? ?? name.trim(),
        email: data['email'] as String? ?? email.trim(),
        phone: phone.trim(),
        role: UserRoleExtension.fromString(data['role'] as String? ?? role.name),
        assignedStoreId: data['assignedStoreId'] as String? ?? assignedStoreId,
        isActive: true,
        createdAt: DateTime.now(),
      );
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }

  Future<void> deactivateUser(String userId) async {
    try {
      final callable = _functions.httpsCallable('revokeUserTokens');
      await callable.call(<String, dynamic>{'uid': userId});
    } on FirebaseFunctionsException {
      // Fallback if callable unavailable — Firestore trigger still revokes.
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'isActive': false});
    }
  }

  Future<void> updateUser(
    String userId, {
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
      // onUserWritten Cloud Function keeps JWT claims in sync with GCP.
    }
  }

  Future<void> updateFcmToken(String userId, String token) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'fcmToken': token});
  }

  void dispose() {
    _firebaseAuthSub?.cancel();
    _userDocSub?.cancel();
    _userController.close();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _onFirebaseAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      await _userDocSub?.cancel();
      _userDocSub = null;
      _currentUser = null;
      _userController.add(null);
      return;
    }

    try {
      try {
        await firebaseUser.getIdToken(true);
      } catch (_) {}

      final model = await _fetchUserModel(firebaseUser);
      if (model == null || !model.isActive) {
        await _firebaseAuth.signOut();
        _currentUser = null;
        _userController.add(null);
        return;
      }
      _attachUserDocListener(firebaseUser.uid);
      _currentUser = model;
      _userController.add(model);
    } catch (_) {
      _currentUser = null;
      _userController.add(null);
    }
  }

  /// Live sync with GCP Firestore — role / isActive changes apply immediately.
  void _attachUserDocListener(String uid) {
    _userDocSub?.cancel();
    _userDocSub = _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .listen((doc) async {
      if (!doc.exists) {
        await signOut();
        return;
      }
      final model = UserModel.fromFirestore(doc);
      if (!model.isActive) {
        await signOut();
        return;
      }
      final roleChanged = _currentUser?.role != model.role;
      _currentUser = model;
      _userController.add(model);
      if (roleChanged) {
        try {
          await _firebaseAuth.currentUser?.getIdToken(true);
        } catch (_) {}
      }
    }, onError: (_) {});
  }

  Future<UserModel?> _fetchUserModel(User? firebaseUser) async {
    if (firebaseUser == null) return null;

    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  void _updateLastLogin(String uid) {
    _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'lastLogin': FieldValue.serverTimestamp()})
        .catchError((_) {});
  }
}
