import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iqfence/models/user_profile.dart';
import 'package:iqfence/service/auth_service.dart';
import 'package:iqfence/service/firestore_service.dart';
import 'package:rxdart/rxdart.dart';

class ProfileProvider with ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  User? _user;
  UserProfile? _userProfile;

  ProfileProvider(this._authService, this._firestoreService) {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      _userProfile = null; // Reset profile on auth state change
      if (user != null) {
        loadUserProfile(); // Load profile when user is signed in
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;

  Stream<UserProfile> getUserData() {
    final user = _authService.currentUser;
    if (user == null) {
      return Stream.error(Exception('No user is currently signed in'));
    }

    return _firestoreService
        .getUserDocStream(user.uid)
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

      return {
        'stream': _firestoreService.getProfileDocStream(collection, docId),
        'collection': collection,
      };
    }).switchMap((result) {
      final stream =
          result['stream'] as Stream<DocumentSnapshot<Map<String, dynamic>>>;
      final collection = result['collection'] as String;
      return stream.map((doc) {
        final data = doc.data() ?? {};
        return UserProfile.fromMap({
          ...data,
          'email': user.email,
          'role':
              data['posisi'] ?? (collection == 'admin' ? 'admin' : 'karyawan'),
          'admin_id': collection == 'admin' ? doc.id : null,
          'karyawan_id': collection == 'karyawan' ? doc.id : null,
        });
      });
    });
  }

  Future<void> loadUserProfile() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final userDoc = await _firestoreService.getUserDoc(user.uid);
      final role = userDoc['role'] as String?;
      final adminId = userDoc['admin_id'] as String?;
      final karyawanId = userDoc['karyawan_id'] as String?;

      if (role == null || (adminId == null && karyawanId == null)) return;

      final collection = role == 'admin' ? 'admin' : 'karyawan';
      final docId = role == 'admin' ? adminId : karyawanId;

      final profileDoc =
          await _firestoreService.getProfileDoc(collection, docId!);
      _userProfile = UserProfile.fromMap({
        ...profileDoc,
        'email': user.email,
        'role': profileDoc['posisi'] ?? role,
        'admin_id': collection == 'admin' ? docId : null,
        'karyawan_id': collection == 'karyawan' ? docId : null,
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> updateUserProfile({
    required String name,
    required String phoneNumber,
    String? password,
    required String address,
    required String gender,
    required String age,
    String? photoUrl,
  }) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      final userDoc = await _firestoreService.getUserDoc(user.uid);
      final role = userDoc['role'] as String?;
      final adminId = userDoc['admin_id'] as String?;
      final karyawanId = userDoc['karyawan_id'] as String?;

      if (role == null) {
        throw Exception('User role not found');
      }

      final collection = role == 'admin' ? 'admin' : 'karyawan';
      final docId = role == 'admin' ? adminId : karyawanId;

      if (docId == null) {
        throw Exception(
            role == 'admin' ? 'Admin ID not found' : 'Karyawan ID not found');
      }

      final updateData = <String, dynamic>{};
      if (name.isNotEmpty) updateData['nama'] = name;
      if (phoneNumber.isNotEmpty) updateData['phoneNumber'] = phoneNumber;
      if (address.isNotEmpty) updateData['alamat'] = address;
      if (gender.isNotEmpty) updateData['gender'] = gender;
      if (age.isNotEmpty) updateData['age'] = age;
      if (photoUrl != null && photoUrl.isNotEmpty)
        updateData['foto'] = photoUrl;

      if (updateData.isNotEmpty) {
        await _firestoreService.updateProfileDoc(collection, docId, updateData);
      }

      if (name.isNotEmpty) {
        await _authService.updateDisplayName(name);
      }
      if (photoUrl != null && photoUrl.isNotEmpty) {
        await _authService.updatePhotoURL(photoUrl);
      }
      if (password != null && password.isNotEmpty) {
        await _authService.updatePassword(password);
      }

      // Update local profile
      _userProfile = UserProfile(
        name: name.isNotEmpty ? name : _userProfile?.name,
        phoneNumber:
            phoneNumber.isNotEmpty ? phoneNumber : _userProfile?.phoneNumber,
        email: user.email,
        address: address.isNotEmpty ? address : _userProfile?.address,
        gender: gender.isNotEmpty ? gender : _userProfile?.gender,
        age: age.isNotEmpty ? age : _userProfile?.age,
        photoUrl: photoUrl != null && photoUrl.isNotEmpty
            ? photoUrl
            : _userProfile?.photoUrl,
        role: role,
        adminId: adminId,
        karyawanId: karyawanId,
        jamKerja: _userProfile?.jamKerja,
        locationIds: _userProfile?.locationIds ?? [],
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}
