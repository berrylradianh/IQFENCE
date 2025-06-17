import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart'; // Added rxdart import

class ProfileProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  ProfileProvider() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Stream<DocumentSnapshot> getUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.error(Exception('No user is currently signed in'));
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      final role = userDoc.data()?['role'] as String?;
      final adminId = userDoc.data()?['admin_id'] as String?;
      final karyawanId = userDoc.data()?['karyawan_id'] as String?;

      if (role == null) {
        throw Exception('User role not found');
      }

      final collection = role == 'admin' ? 'admin' : 'karyawan';
      final docId = role == 'admin' ? adminId : karyawanId;

      if (docId == null) {
        throw Exception(
            role == 'admin' ? 'Admin ID not found' : 'Karyawan ID not found');
      }

      return FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .snapshots();
    }).switchMap((stream) => stream);
  }

  Future<void> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? password,
    String? address,
    String? gender,
    String? age,
    String? photoUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in');
    }

    // Get user role and ID from users collection
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final role = userDoc.data()?['role'] as String?;
    final adminId = userDoc.data()?['admin_id'] as String?;
    final karyawanId = userDoc.data()?['karyawan_id'] as String?;

    if (role == null) {
      throw Exception('User role not found');
    }

    final collection = role == 'admin' ? 'admin' : 'karyawan';
    final docId = role == 'admin' ? adminId : karyawanId;

    if (docId == null) {
      throw Exception(
          role == 'admin' ? 'Admin ID not found' : 'Karyawan ID not found');
    }

    // Prepare update data for Firestore
    final updateData = <String, dynamic>{};
    if (name != null && name.isNotEmpty) updateData['nama'] = name;
    if (phoneNumber != null && phoneNumber.isNotEmpty)
      updateData['phoneNumber'] = phoneNumber; // Fixed null safety issue
    if (address != null) updateData['alamat'] = address;
    if (gender != null) updateData['gender'] = gender;
    if (age != null) updateData['age'] = age;
    if (photoUrl != null) updateData['foto'] = photoUrl;

    // Update Firestore document
    if (updateData.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .update(updateData);
    }

    // Update Firebase Authentication profile
    if (name != null && name.isNotEmpty) {
      await user.updateDisplayName(name);
    }
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }
    if (password != null && password.isNotEmpty) {
      await user.updatePassword(password);
    }

    notifyListeners();
  }
}
