import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Current user ──────────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Email / Password Sign Up ──────────────────────────────────
  static Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.updateDisplayName(name);

    // Create Firestore user profile
    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'calorieGoal': 2000,
      'proteinGoal': 150,
      'carbGoal': 250,
      'fatGoal': 65,
    });

    return cred;
  }

  // ── Email / Password Sign In ──────────────────────────────────
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ── Google Sign In ────────────────────────────────────────────
  static Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);

    // Create user doc only on first sign-in
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) {
      await _db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': cred.user!.displayName ?? 'User',
        'email': cred.user!.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'calorieGoal': 2000,
        'proteinGoal': 150,
        'carbGoal': 250,
        'fatGoal': 65,
      });
    }

    return cred;
  }

  // ── Update Display Name ────────────────────────────────────
  static Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(name);
    await user.reload();
    // Also update Firestore profile
    await _db.collection('users').doc(user.uid).update({'name': name});
  }

  // ── Delete Account ────────────────────────────────────────
  static Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // Delete subcollections
    final subcollections = ['journal', 'daily_stats', 'notifications'];
    for (final sub in subcollections) {
      final snap = await _db.collection('users').doc(uid).collection(sub).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }

    // Delete user document
    await _db.collection('users').doc(uid).delete();

    // Sign out of Google
    await GoogleSignIn().signOut();

    // Delete Firebase Auth account
    await user.delete();
  }

  // ── Password Reset ────────────────────────────────────────────
  static Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Sign Out ──────────────────────────────────────────────────
  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  // ── Debug logger ──────────────────────────────────────────────
  static void logError(Object e) {
    if (e is FirebaseAuthException) {
      // ignore: avoid_print
      print('🔴 FirebaseAuthException: code=${e.code} | msg=${e.message}');
    } else {
      // ignore: avoid_print
      print('🔴 Unknown error: $e');
    }
  }

  // ── Friendly error messages ───────────────────────────────────
  static String friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
