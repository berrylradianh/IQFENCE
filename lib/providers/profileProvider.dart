import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';

class ProfileProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instance;

  User? get user => _auth.currentUser;

  // Fetch user data based on role (karyawan or admin)
  Stream<DocumentSnapshot> getUserData() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield* const Stream.empty();
      return;
    }

    // Get the 'karyawan_id' and 'role' from the 'users' collection
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final karyawanId = userDoc.data()?['karyawan_id'] as String?;
    final role = userDoc.data()?['role'] as String?;

    if (karyawanId == null || role == null) {
      yield* const Stream.empty();
      return;
    }

    // Stream data from either 'karyawan' or 'admin' collection based on role
    final collection = role == 'admin' ? 'admin' : 'karyawan';
    yield* _firestore.collection(collection).doc(karyawanId).snapshots();
  }

  // Update user profile in the appropriate collection (karyawan or admin)
  Future<void> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? password,
    String? address,
    String? gender,
    String? age,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in');
    }

    // Get the 'karyawan_id' and 'role' from the 'users' collection
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final karyawanId = userDoc.data()?['karyawan_id'] as String?;
    final role = userDoc.data()?['role'] as String?;

    if (karyawanId == null || role == null) {
      throw Exception('No karyawan_id or role found for the user');
    }

    // Determine the target collection based on role
    final collection = role == 'admin' ? 'admin' : 'karyawan';

    // Prepare updated data
    Map<String, dynamic> updatedData = {};

    if (name != null && name.isNotEmpty) {
      updatedData['nama'] = name;
    }
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      updatedData['phoneNumber'] = phoneNumber;
    }
    if (address != null && address.isNotEmpty) {
      updatedData['alamat'] = address;
    }
    if (gender != null && gender.isNotEmpty) {
      updatedData['gender'] = gender;
    }
    if (age != null && age.isNotEmpty) {
      updatedData['age'] = age;
    }
    if (role.isNotEmpty) {
      updatedData['posisi'] = role; // Ensure posisi matches role
    }

    // Update the appropriate collection if there are changes
    if (updatedData.isNotEmpty) {
      await _firestore
          .collection(collection)
          .doc(karyawanId)
          .update(updatedData);
    }

    // Update Firebase Auth profile if needed
    if (name != null && name.isNotEmpty) {
      await user.updateDisplayName(name);
    }
    if (password != null && password.isNotEmpty) {
      await user.updatePassword(password);
    }

    notifyListeners();
  }

  // Update profile picture in Firebase Storage and the appropriate collection
  Future<String> updateProfilePicture(String imagePath) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in');
    }

    // Get the 'karyawan_id' and 'role' from the 'users' collection
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final karyawanId = userDoc.data()?['karyawan_id'] as String?;
    final role = userDoc.data()?['role'] as String?;

    if (karyawanId == null || role == null) {
      throw Exception('No karyawan_id or role found for the user');
    }

    // Determine the target collection based on role
    final collection = role == 'admin' ? 'admin' : 'karyawan';

    // Upload image to Firebase Storage
    File image = File(imagePath);
    final ref = _storage.ref().child('profile_pictures/$karyawanId.jpg');
    await ref.putFile(image);
    final url = await ref.getDownloadURL();

    // Update the 'foto' field in the appropriate collection
    await _firestore.collection(collection).doc(karyawanId).update({
      'foto': url,
    });

    // Update Firebase Auth profile
    await user.updatePhotoURL(url);

    notifyListeners();
    return url;
  }
}
