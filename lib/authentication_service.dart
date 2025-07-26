// lib/authentication_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthenticationService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthenticationService(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      return "Signed in";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signUp({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        await _createInitialUserData(userCredential.user!.uid, email);
      }

      return "Signed up";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> _createInitialUserData(String uid, String email) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'nickname': email.split('@')[0],
      'userAge': 30,
      'userHeightCm': 175.0,
      'userWeightKg': 75.0,
      'gender': 0,
      'activityLevel': 2,
      'userLevel': 1,
      'currentXp': 0.0,
      'bossStage': 1,
      'maxBossHp': 7700.0,
      'bossHp': 7700.0,
      'isToxified': false,
      'lastActiveDate': '',
    });
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}