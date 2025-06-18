import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iqfence/models/userModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Auth with ChangeNotifier {
  bool isPasswordVisible = true;

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }

  // TODO: get current user
  User get user => _auth.currentUser!;

  //TODO: Check if user is logged in
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  //TODO: stream of user collection from firestore
  Stream<DocumentSnapshot<Map<String, dynamic>>> get userStream {
    return _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .snapshots();
  }

  //TODO: stream of user collection from firestore by id
  Stream<DocumentSnapshot<Map<String, dynamic>>> userStreamById(String id) {
    return _firestore.collection('users').doc(id).snapshots();
  }

  //TODO: create user with  email and password
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      if (password.length < 6) {
        throw 'Password must be at least 6 characters';
      }
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      final User? user = userCredential.user;

      UserModel userModel = UserModel(
        email: email,
        role: 'user',
        displayName: name,
        phoneNumber: phone,
        address: '',
        photoURL: '',
      );

      if (user != null) {
        user.updateDisplayName(name);
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toJson());
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        throw 'The account already exists for that email.';
      } else if (e.code == 'invalid-password') {
        throw 'The password is invalid.';
      } else if (e.code == 'invalid-email') {
        throw 'The email is invalid.';
      } else {
        throw 'An error occurred while creating the user.';
      }
    }
  }

  Future<void> saveLoginStatus(String userRole) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', userRole);
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      String userRole = await getUserRole();
      await saveLoginStatus(userRole);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        throw 'Wrong password provided for that user.';
      } else {
        throw 'An error occurred while signing in.';
      }
    }
  }

  Future<String> getUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      return (userDoc.data() as Map<String, dynamic>)['role'] ?? 'user';
    }
    return 'user';
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String> getLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userRole') ?? 'user';
  }

  // Fungsi untuk mengirim link reset password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'Tidak ada pengguna yang ditemukan dengan email tersebut.';
      } else {
        throw 'Terjadi kesalahan saat mengirim email reset password. Silakan coba lagi.';
      }
    }
  }
}
