import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _firebaseUser;
  AppUser? _appUser;
  bool _isLoading = true;

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _authService.authStateChanges.listen((user) async {
      _firebaseUser = user;
      if (user != null) {
        await _fetchAppUser(user.uid);
      } else {
        _appUser = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _fetchAppUser(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        _appUser = AppUser.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint("Error fetching user role: $e");
    }
  }

  Future<bool> signIn(String email, String password) async {
    final cred = await _authService.signInWithEmail(email, password);
    return cred != null;
  }
  
  Future<bool> signUp(String email, String password, String role, String name, String phone) async {
    final cred = await _authService.signUpWithEmail(email, password, role, name, phone);
    return cred != null;
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
