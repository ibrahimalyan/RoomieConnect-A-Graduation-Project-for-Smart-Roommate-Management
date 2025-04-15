import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_application_1/models/user.dart';

class AuthsService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // Convert Firebase User to custom User model
  User? _userFromFirebaseUser(auth.User? user) {
    return user != null ? User(uid: user.uid) : null;
  }

  // Auth change stream
  Stream<User?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // Sign in anonymously
  Future<User?> signInAnonymously() async {
    try {
      auth.UserCredential result = await _auth.signInAnonymously();
      return _userFromFirebaseUser(result.user);
    } catch (e) {
      print('Anonymous sign-in error: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      auth.UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return _userFromFirebaseUser(result.user);
    } catch (e) {
      print('Email sign-in error: $e');
      return null;
    }
  }

  // Register with email and password
  Future<User?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      auth.UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return _userFromFirebaseUser(result.user);
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  // Sign out
  Future signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      return null;
    }
  }
}
