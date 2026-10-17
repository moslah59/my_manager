
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final AuthService _instance = AuthService._();

  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _googleInitialized = false;

  // Current logged-in user
  User? get currentUser => _auth.currentUser;

  // Authentication state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Initialize Google Sign-In

  Future<void> _initializeGoogle() async {
    if (_googleInitialized) return;

    await _googleSignIn.initialize(
      serverClientId:
      '285712412582-8kbhk77lgkagonc0qs2tvji3hb9rtse7.apps.googleusercontent.com',
    );

    _googleInitialized = true;
  }


  // Email / Password Login
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Create New Account
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Send Password Reset Email
  Future<void> resetPassword({
    required String email,
  }) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  // Google Sign-In
  Future<UserCredential> signInWithGoogle() async {
    try {
      await _initializeGoogle();

      // Open Google account selection
      final GoogleSignInAccount googleUser =
      await _googleSignIn.authenticate();

      // Get Google authentication token
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'google-id-token-null',
          message:
          'Google ID token পাওয়া যায়নি। Google Sign-In configuration পরীক্ষা করুন।',
        );
      }

      // Create Firebase credential
      final OAuthCredential credential =
      GoogleAuthProvider.credential(
        idToken: idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      debugPrint(
        'Google Login Successful: ${userCredential.user?.email}',
      );

      return userCredential;
    } on GoogleSignInException catch (e, stackTrace) {
      debugPrint('Google Sign-In Error: ${e.code}');
      debugPrint('Google Sign-In Details: ${e.description}');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('Firebase Auth Error: ${e.code}');
      debugPrint('Firebase Auth Message: ${e.message}');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Google Login Unexpected Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();

    if (_googleInitialized) {
      await _googleSignIn.signOut();
    }
  }
}
