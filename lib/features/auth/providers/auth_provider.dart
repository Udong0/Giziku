import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get email => _user?.email;

  Future<void> signIn(String email, String password) =>
      FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

  Future<void> register(String email, String password) =>
      FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

  Future<void> signOut() => FirebaseAuth.instance.signOut();
}