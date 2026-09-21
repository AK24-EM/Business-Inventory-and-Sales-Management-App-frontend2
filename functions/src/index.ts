/**
 * StoreIQ Cloud Functions — Feature 1: Authentication & RBAC
 *
 * These functions run on GCP (Firebase Cloud Functions, Node 20 runtime) and
 * are the ONLY place that uses the Firebase Admin SDK to perform privileged
 * operations:
 *   1. setUserClaims     — Callable. Sets JWT custom claims {role, assignedStoreId}
 *                          so Cloud Run and Firestore rules can enforce RBAC
 *                          without a Firestore read on every request.
 *   2. createUser        — Callable. Creates a Firebase Auth account + Firestore
 *                          record + claims in one atomic operation, without
 *                          disrupting the calling admin's session.
 *   3. onUserWritten     — Firestore trigger. Keeps JWT claims in sync whenever
 *                          a user document's role/isActive changes in Firestore.
 *   4. revokeUserTokens  — Callable. Immediately revokes all issued tokens for a
 *                          deactivated/deleted user (forces re-auth on all devices).
 *
 * Security:
 *   - All callables verify the caller is authenticated and has owner/admin role
 *     before executing. Unauthenticated or under-privileged calls are rejected.
 *   - Passwords are never stored in plain text; Firebase Auth handles hashing.
 *   - No secrets are embedded in this code; Firebase project config is injected
 *     automatically by the Cloud Functions runtime.
 */

import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

// ── Types ──────────────────────────────────────────────────────────────────

type UserRole = "owner" | "manager" | "employee" | "admin";

interface UserClaims {
  role: UserRole;
  assignedStoreId: string | null;
  storeAccess: "all" | string; // "all" for owner/admin, storeId otherwise
}

// ── Helpers ────────────────────────────────────────────────────────────────

/** Verify the caller is authenticated and has owner or admin role. */
async function requireOwnerOrAdmin(
  auth: functions.https.CallableRequest["auth"]
): Promise<void> {
  if (!auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in to perform this action."
    );
  }
  const callerDoc = await db.collection("users").doc(auth.uid).get();
  if (!callerDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Caller user record not found.");
  }
  const role = callerDoc.data()?.role as UserRole;
  if (role !== "owner" && role !== "admin") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only owners and admins can manage users."
    );
  }
}

/** Build the claims object for a given role and store assignment. */
function buildClaims(role: UserRole, assignedStoreId: string | null): UserClaims {
  return {
    role,
    assignedStoreId: assignedStoreId ?? null,
    storeAccess: role === "owner" || role === "admin" ? "all" : (assignedStoreId ?? ""),
  };
}

// ── 1. setUserClaims ───────────────────────────────────────────────────────

/**
 * Callable: set (or update) JWT custom claims for a user.
 *
 * Called by the Flutter app after a role/store change in UserManagement.
 * The new claims take effect on the user's NEXT token refresh (within 1 hour
 * automatically, or immediately if the client calls getIdToken(forceRefresh: true)).
 *
 * Input:  { uid, role, assignedStoreId? }
 * Output: { success: true }
 */
export const setUserClaims = functions.https.onCall(
  { region: "asia-south1" },
  async (request) => {
    await requireOwnerOrAdmin(request.auth);

    const { uid, role, assignedStoreId = null } = request.data as {
      uid: string;
      role: UserRole;
      assignedStoreId?: string | null;
    };

    if (!uid || !role) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "uid and role are required."
      );
    }

    const claims = buildClaims(role, assignedStoreId);
    await auth.setCustomUserClaims(uid, claims);

    // Also update Firestore to keep it in sync (Firestore rules read both).
    await db.collection("users").doc(uid).update({
      role,
      assignedStoreId: assignedStoreId ?? null,
    });

    functions.logger.info(`Claims set for ${uid}: role=${role}, store=${assignedStoreId}`);
    return { success: true };
  }
);

// ── 2. createUser ──────────────────────────────────────────────────────────

/**
 * Callable: create a new Firebase Auth account + Firestore record + claims.
 *
 * Using Admin SDK here avoids the client-side side-effect of
 * createUserWithEmailAndPassword signing in as the newly created account.
 *
 * Input:  { email, password, name, phone, role, assignedStoreId? }
 * Output: { uid, email, name, role, assignedStoreId }
 */
export const createUser = functions.https.onCall(
  { region: "asia-south1" },
  async (request) => {
    await requireOwnerOrAdmin(request.auth);

    const {
      email,
      password,
      name,
      phone,
      role,
      assignedStoreId = null,
    } = request.data as {
      email: string;
      password: string;
      name: string;
      phone: string;
      role: UserRole;
      assignedStoreId?: string | null;
    };

    if (!email || !password || !name || !phone || !role) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "email, password, name, phone, and role are all required."
      );
    }
    if (password.length < 6) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Password must be at least 6 characters."
      );
    }

    // Create the Firebase Auth account.
    let userRecord: admin.auth.UserRecord;
    try {
      userRecord = await auth.createUser({
        email: email.trim(),
        password,
        displayName: name.trim(),
      });
    } catch (e: unknown) {
      const err = e as admin.FirebaseError;
      if (err.code === "auth/email-already-exists") {
        throw new functions.https.HttpsError(
          "already-exists",
          "An account with this email already exists."
        );
      }
      throw new functions.https.HttpsError("internal", err.message);
    }

    const uid = userRecord.uid;
    const now = admin.firestore.FieldValue.serverTimestamp();
    const claims = buildClaims(role, assignedStoreId);

    // Set custom claims immediately so first token is correct.
    await auth.setCustomUserClaims(uid, claims);

    // Write the Firestore user document.
    const userDoc = {
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role,
      assignedStoreId: assignedStoreId ?? null,
      isActive: true,
      createdAt: now,
      lastLogin: null,
      fcmToken: null,
    };
    await db.collection("users").doc(uid).set(userDoc);

    functions.logger.info(`User created: ${uid} (${email}), role=${role}`);
    return { uid, email: email.trim(), name: name.trim(), role, assignedStoreId };
  }
);

// ── 3. onUserWritten ───────────────────────────────────────────────────────

/**
 * Firestore trigger: keep JWT custom claims in sync with Firestore.
 *
 * Fires when any field in users/{uid} changes.  If role, assignedStoreId,
 * or isActive changed, the claims are updated immediately.
 * If the account is deactivated (isActive → false), all existing tokens
 * are revoked (forcing re-authentication on all devices).
 */
export const onUserWritten = functions.firestore.onDocumentWritten(
  { document: "users/{uid}", region: "asia-south1" },
  async (event) => {
    const uid = event.params.uid;
    const after = event.data?.after?.data();
    const before = event.data?.before?.data();

    // Document deleted — revoke tokens and disable Auth account.
    if (!after) {
      await auth.revokeRefreshTokens(uid).catch(() => {});
      await auth.updateUser(uid, { disabled: true }).catch(() => {});
      return;
    }

    const roleChanged = before?.role !== after.role;
    const storeChanged = before?.assignedStoreId !== after.assignedStoreId;
    const activeChanged = before?.isActive !== after.isActive;

    if (!roleChanged && !storeChanged && !activeChanged) return;

    if (after.isActive === false) {
      // Revoke all tokens immediately — user is deactivated.
      await auth.revokeRefreshTokens(uid);
      await auth.updateUser(uid, { disabled: true });
      functions.logger.info(`Tokens revoked for deactivated user: ${uid}`);
      return;
    }

    if (after.isActive === true && before?.isActive === false) {
      // Re-enable a previously deactivated account.
      await auth.updateUser(uid, { disabled: false });
    }

    if (roleChanged || storeChanged) {
      const claims = buildClaims(
        after.role as UserRole,
        after.assignedStoreId ?? null
      );
      await auth.setCustomUserClaims(uid, claims);
      functions.logger.info(
        `Claims refreshed for ${uid}: role=${after.role}, store=${after.assignedStoreId}`
      );
    }
  }
);

// ── 4. revokeUserTokens ────────────────────────────────────────────────────

/**
 * Callable: immediately revoke all refresh tokens for a user.
 *
 * Use this when an admin manually deactivates a user through the UI — the
 * onUserWritten trigger will also fire, but this provides an explicit, fast
 * path for the UI to confirm the revocation happened.
 *
 * Input:  { uid }
 * Output: { success: true }
 */
export const revokeUserTokens = functions.https.onCall(
  { region: "asia-south1" },
  async (request) => {
    await requireOwnerOrAdmin(request.auth);

    const { uid } = request.data as { uid: string };
    if (!uid) {
      throw new functions.https.HttpsError("invalid-argument", "uid is required.");
    }

    await auth.revokeRefreshTokens(uid);
    await auth.updateUser(uid, { disabled: true });

    // Mark isActive=false in Firestore (triggers onUserWritten as well).
    await db.collection("users").doc(uid).update({ isActive: false });

    functions.logger.info(`Tokens revoked for user: ${uid}`);
    return { success: true };
  }
);
