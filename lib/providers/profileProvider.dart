import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';

class ProfileProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instance;


  User get user => _auth.currentUser!;

  Stream<DocumentSnapshot> getUserData() {
    return _firestore
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .snapshots();
  }

  Future<void> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? password,
    String? photoURL,
    String? address,
    String? gender,
    String? age,
  }) async {
    Map<String, dynamic> updatedData = {};

    if (name != null && name.isNotEmpty) {
      updatedData['displayName'] = name;
    }
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      updatedData['phoneNumber'] = phoneNumber;
    }
    if (address != null && address.isNotEmpty) {
      updatedData['address'] = address;
    }
    if (gender != null && gender.isNotEmpty) {
      updatedData['gender'] = gender;
    }
    if (age != null && age.isNotEmpty) {
      updatedData['age'] = age;
    }
    if (updatedData.isNotEmpty) {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .update(updatedData);
    }

    if (password != null && password.isNotEmpty) {
      await _auth.currentUser?.updatePassword(password);
    }

    if (photoURL != null && photoURL.isNotEmpty) {
      await _auth.currentUser?.updatePhotoURL(photoURL);
    }

    notifyListeners();
  }

  Future<String> updateProfilePicture(String imagePath) async {
    File image = File(imagePath);
    final ref = _storage.ref().child('profile_pictures/${user.uid}');
    await ref.putFile(image);
    final url = await ref.getDownloadURL();
    await updateUserProfile(photoURL: url);
    return url;
  }
}