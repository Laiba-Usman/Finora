import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Used only on Android / iOS.
  // serverClientId (Web Client ID from google-services.json, client_type: 3)
  // is REQUIRED on Android so GoogleSignIn returns an idToken for Firebase Auth.
  // clientId is the same value but targets the web/Windows plugin.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '391090637096-oetimqm4vuarcnunv6saas38g7i5dp9v.apps.googleusercontent.com',
    serverClientId:
        '391090637096-oetimqm4vuarcnunv6saas38g7i5dp9v.apps.googleusercontent.com',
  );

  // ── Auth State Stream ────────────────────────────────────────────────────

  /// Emits a [UserModel] whenever the Firebase auth state changes.
  Stream<UserModel?> get user {
    return _auth.authStateChanges().map((User? user) {
      if (user == null) return null;
      return UserModel(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        currency: 'USD',
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        photoUrl: user.photoURL,
      );
    });
  }

  /// Returns the currently signed-in user, or null if not signed in.
  UserModel? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserModel(
      uid: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      currency: 'USD',
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      photoUrl: user.photoURL,
    );
  }

  // ── Auth Methods ─────────────────────────────────────────────────────────

  /// Sign in anonymously (Guest Mode).
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new account with email and password.
  Future<UserCredential> signUpWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await credential.user?.updateDisplayName(name);
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with Google — fully platform-aware.
  ///
  /// ▸ **Web / Windows desktop** → Uses [FirebaseAuth.signInWithPopup].
  ///   This opens a browser OAuth popup managed by Firebase itself.
  ///   No `clientId` meta-tag or `google_sign_in_web` quirks required.
  ///
  /// ▸ **Android / iOS** → Uses the [GoogleSignIn] package which shows
  ///   the native account picker, then exchanges credentials with Firebase.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // ── Web ──────────────────────────────────────────────────────────────
      if (kIsWeb) {
        return await _signInWithPopup();
      }

      // ── Windows / macOS / Linux desktop ──────────────────────────────────
      // dart:io is safe here because kIsWeb == false.
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        return await _signInWithPopup();
      }

      // ── Android / iOS — native GoogleSignIn flow ──────────────────────────
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled the picker

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // idToken is required. If null, the serverClientId above is wrong or
      // the SHA-1 fingerprint isn't registered in Firebase Console.
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception(
          'Google Sign-In failed: idToken is null.\n'
          'Make sure:\n'
          '  1. The SHA-1 fingerprint of your debug keystore is registered\n'
          '     in Firebase Console → Project Settings → Your Android App.\n'
          '  2. The serverClientId above matches the web client ID\n'
          '     (client_type: 3) in google-services.json.',
        );
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  /// Firebase popup sign-in used for Web and Windows/macOS/Linux desktop.
  Future<UserCredential> _signInWithPopup() async {
    final googleProvider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile');
    return await _auth.signInWithPopup(googleProvider);
  }

  /// Send a password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out from both Firebase and Google.
  Future<void> signOut() async {
    try {
      try {
        await _googleSignIn.signOut();
      } catch (googleError) {
        print('Google Sign-In signOut error (safe to ignore on desktop): $googleError');
      }
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
