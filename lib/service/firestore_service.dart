import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
