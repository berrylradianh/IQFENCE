import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<bool> reauthenticateUser(String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await _auth.currentUser?.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      throw Exception('Re-authentication failed: $e');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  Future<void> updateDisplayName(String name) async {
    try {
      await _auth.currentUser?.updateDisplayName(name);
    } catch (e) {
      throw Exception('Failed to update display name: $e');
    }
  }

  Future<void> updatePhotoURL(String photoUrl) async {
    try {
      await _auth.currentUser?.updatePhotoURL(photoUrl);
    } catch (e) {
      throw Exception('Failed to update photo URL: $e');
    }
  }
}
