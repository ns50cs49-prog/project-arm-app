const {onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

// Kept in sync with the hardcoded admin identity in login.dart (_adminEmail)
// and main.dart's AuthGate — only that account may reset another user's
// Firebase Auth password directly.
const ADMIN_EMAIL = "raddawan3079@gmail.com";

// The Web API key from firebase_options.dart's `web` FirebaseOptions — this
// is a public client identifier (not a secret; it ships inside the compiled
// web/mobile app already), used below to verify a password change actually
// works by performing a real sign-in exactly like the client would.
const WEB_API_KEY = "AIzaSyDjxo8xDmCjJAW_QxICPr2R65ZbTX_S9mQ";

/**
 * Lets the admin set a patient's Firebase Auth password directly, without a
 * reset email. Runs with the Admin SDK (server-side only) because the client
 * SDK can only change the password of the currently signed-in user.
 *
 * Looks the account up by email (what the patient actually types in at
 * login) rather than trusting a client-supplied uid — the admin patient
 * list's id can come from an appointment/treatment-history record instead
 * of the real `users/{uid}` doc, so it isn't guaranteed to be the patient's
 * actual Firebase Auth uid; the email is.
 */
exports.adminSetPatientPassword = onCall(async (request) => {
  const callerEmail = request.auth?.token?.email;
  if (!request.auth || callerEmail !== ADMIN_EMAIL) {
    throw new HttpsError(
        "permission-denied",
        "เฉพาะแอดมินเท่านั้นที่เปลี่ยนรหัสผ่านผู้ป่วยได้",
    );
  }

  const email = typeof request.data?.email === "string" ? request.data.email.trim() : "";
  const newPassword =
    typeof request.data?.newPassword === "string" ? request.data.newPassword : "";

  if (email === "") {
    throw new HttpsError("invalid-argument", "ไม่พบอีเมลผู้ป่วย");
  }
  if (newPassword.length < 6) {
    throw new HttpsError("invalid-argument", "รหัสผ่านควรมีอย่างน้อย 6 ตัวอักษร");
  }

  let targetUser;
  try {
    targetUser = await admin.auth().getUserByEmail(email);
  } catch (error) {
    logger.warn("adminSetPatientPassword: getUserByEmail failed", {
      email,
      code: error.code,
      message: error.message,
    });
    if (error.code === "auth/user-not-found") {
      throw new HttpsError("not-found", "ไม่พบบัญชีผู้ป่วยนี้ในระบบยืนยันตัวตน");
    }
    // Surface the real Admin SDK error code/message to the client instead
    // of hiding it behind a generic "internal" — this is admin-only UI, so
    // showing the raw diagnostic (e.g. an IAM permission error) directly on
    // screen is more useful than making the admin dig through server logs.
    throw new HttpsError(
        "internal",
        `getUserByEmail failed: ${error.code || "unknown"} - ${error.message || error}`,
    );
  }

  try {
    await admin.auth().updateUser(targetUser.uid, {password: newPassword});
  } catch (error) {
    logger.error("adminSetPatientPassword: updateUser failed", {
      email,
      uid: targetUser.uid,
      code: error.code,
      message: error.message,
    });
    throw new HttpsError(
        "internal",
        `updateUser failed: ${error.code || "unknown"} - ${error.message || error}`,
    );
  }

  // Remembers the password the admin just set (in plaintext) so the admin
  // UI can display "the current password" for accounts whose password was
  // set through this flow. This is a deliberate, requested tradeoff — a
  // patient's *self-registered* password is never captured here (Firebase
  // Auth never exposes it, by design), so this field only reflects
  // admin-issued passwords, not necessarily what a patient set themselves.
  try {
    await admin.firestore().collection("users").doc(targetUser.uid).set({
      adminSetPassword: newPassword,
      adminSetPasswordAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
  } catch (error) {
    logger.warn("adminSetPatientPassword: failed to record adminSetPassword", {
      email,
      uid: targetUser.uid,
      code: error.code,
      message: error.message,
    });
  }

  // Proves the new password actually works by performing a real sign-in
  // with it, the exact same way the patient's app would — this catches
  // any case where Admin SDK reports success but the credential the
  // patient ends up typing still doesn't match (e.g. this admin.auth()
  // call quietly landed on a different account than the one that's really
  // signed in as `email`).
  let verifiedLogin = false;
  let verifyError = null;
  try {
    const verifyResponse = await fetch(
        `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${WEB_API_KEY}`,
        {
          method: "POST",
          headers: {"Content-Type": "application/json"},
          body: JSON.stringify({
            email,
            password: newPassword,
            returnSecureToken: true,
          }),
        },
    );
    const verifyJson = await verifyResponse.json();
    if (verifyResponse.ok) {
      verifiedLogin = true;
    } else {
      verifyError = verifyJson?.error?.message || `HTTP ${verifyResponse.status}`;
    }
  } catch (error) {
    verifyError = error.message || String(error);
  }

  logger.info("adminSetPatientPassword: password updated", {
    email,
    uid: targetUser.uid,
    verifiedLogin,
    verifyError,
  });
  return {
    success: true,
    uid: targetUser.uid,
    verifiedLogin,
    verifyError,
  };
});
