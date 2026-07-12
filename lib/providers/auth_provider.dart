import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

enum AuthStatus { initial, loading, authenticated, guest, unauthenticated, error }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  UserModel? _user;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;

  UserModel? get user => _user;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated || _status == AuthStatus.guest;
  bool get isGuest => _status == AuthStatus.guest;

  AuthProvider() {
    _init();
  }

  void _init() {
    _status = AuthStatus.loading;
    _authService.user.listen((UserModel? user) {
      if (user != null) {
        _user = user;
        // If anonymous, mark as guest, else authenticated
        _status = user.email.isEmpty ? AuthStatus.guest : AuthStatus.authenticated;
      } else {
        _user = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    }, onError: (err) {
      _status = AuthStatus.error;
      _errorMessage = err.toString();
      notifyListeners();
    });
  }

  Future<void> signInAnonymously() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.signInAnonymously();
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.signInWithEmailAndPassword(email, password);
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password, String name) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final credential = await _authService.signUpWithEmailAndPassword(email, password, name);
      final firebaseUser = credential.user;
      if (firebaseUser != null) {
        final newUserModel = UserModel(
          uid: firebaseUser.uid,
          name: name,
          email: email,
          currency: 'USD',
          createdAt: DateTime.now(),
        );
        await _firestoreService.syncProfile(firebaseUser.uid, newUserModel);
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential == null) {
        // User cancelled Google Sign-In, restore status to previous state
        _status = _user == null 
            ? AuthStatus.unauthenticated 
            : (_user!.email.isEmpty ? AuthStatus.guest : AuthStatus.authenticated);
        notifyListeners();
      } else {
        final firebaseUser = credential.user;
        if (firebaseUser != null) {
          final newUserModel = UserModel(
            uid: firebaseUser.uid,
            name: firebaseUser.displayName ?? '',
            email: firebaseUser.email ?? '',
            currency: 'USD',
            createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
            photoUrl: firebaseUser.photoURL,
          );
          await _firestoreService.syncProfile(firebaseUser.uid, newUserModel);
        }
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfileName(String newName) async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(newName);
        
        if (!firebaseUser.isAnonymous) {
          final updatedUserModel = UserModel(
            uid: firebaseUser.uid,
            name: newName,
            email: firebaseUser.email ?? '',
            currency: 'USD',
            createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
            photoUrl: firebaseUser.photoURL,
          );
          await _firestoreService.syncProfile(firebaseUser.uid, updatedUserModel);
        }
        
        _user = UserModel(
          uid: firebaseUser.uid,
          name: newName,
          email: firebaseUser.email ?? '',
          currency: 'USD',
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
          photoUrl: firebaseUser.photoURL,
        );
        _status = firebaseUser.isAnonymous ? AuthStatus.guest : AuthStatus.authenticated;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.signOut();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
