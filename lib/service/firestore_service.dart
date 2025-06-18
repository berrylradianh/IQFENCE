import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iqfence/models/presensi_model.dart';
import 'package:iqfence/models/userModel.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserModel>> getAllUsers() async {
    try {
      final userSnapshot = await _firestore.collection('users').get();
      print('Fetched ${userSnapshot.docs.length} users from Firestore');
      if (userSnapshot.docs.isEmpty) {
        print('Warning: No users found in users collection');
      }

      List<UserModel> users = [];

      for (var doc in userSnapshot.docs) {
        final userData = doc.data();
        print('Processing user document ID: ${doc.id}');
        String name = userData['nama'] ?? '';
        final karyawanId = userData['karyawan_id'] ?? '';

        // Fetch name from karyawan if nama is empty
        if (name.isEmpty && karyawanId.isNotEmpty) {
          final karyawanDoc =
              await _firestore.collection('karyawan').doc(karyawanId).get();
          if (karyawanDoc.exists) {
            name = karyawanDoc.data()?['nama'] ?? 'Unknown';
            print('Fetched name from karyawan: $name');
          }
        }

        name = name.isEmpty ? 'Unknown' : name;

        final user = UserModel(
          id: doc.id,
          email: userData['email'] ?? '',
          role: userData['role'] ?? '',
          displayName: name,
          photoURL: userData['photoURL'],
          phoneNumber: userData['phoneNumber'],
          address: userData['address'],
        );
        users.add(user);
        print('Added user: {id: ${user.id}, displayName: ${user.displayName}}');
      }

      print('Returning ${users.length} users');
      return users;
    } catch (e) {
      print('Error fetching users: $e');
      throw Exception('Error fetching users: $e');
    }
  }

  // Stream presensi data
  Stream<List<PresensiModel>> getPresensiStream({String? userId}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('presensi')
        .orderBy('tanggal_presensi', descending: true);

    if (userId != null) {
      query = query.where('user_id', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => PresensiModel.fromFirestore(doc)).toList());
  }

  Future<Map<String, dynamic>> getUserDoc(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserDocStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<Map<String, dynamic>> getProfileDoc(
      String collection, String docId) async {
    final doc = await _firestore.collection(collection).doc(docId).get();
    if (!doc.exists) {
      await _firestore.collection(collection).doc(docId).set({
        'nama': '',
        'phoneNumber': '',
        'alamat': '',
        'gender': '',
        'age': '',
        'foto': '',
        'jam_kerja': '',
        'location_ids': [],
        'posisi': collection,
      });
      return {
        'nama': '',
        'phoneNumber': '',
        'alamat': '',
        'gender': '',
        'age': '',
        'foto': '',
        'jam_kerja': '',
        'location_ids': [],
        'posisi': collection,
      };
    }
    return doc.data() ?? {};
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getProfileDocStream(
      String collection, String docId) {
    return _firestore.collection(collection).doc(docId).snapshots();
  }

  Future<void> updateProfileDoc(
      String collection, String docId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(docId).update(data);
  }
}
