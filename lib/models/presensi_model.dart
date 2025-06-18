import 'package:cloud_firestore/cloud_firestore.dart';

class PresensiModel {
  final String id;
  final String userId;
  final String userName;
  final String tanggalPresensi;
  final String jamPresensi;
  final String locationName;
  final String type;

  PresensiModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.tanggalPresensi,
    required this.jamPresensi,
    required this.locationName,
    required this.type,
  });

  factory PresensiModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PresensiModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? 'Unknown',
      tanggalPresensi: data['tanggal_presensi'] ?? '',
      jamPresensi: data['jam_presensi'] ?? '',
      locationName: data['location_name'] ?? 'Unknown',
      type: data['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'tanggal_presensi': tanggalPresensi,
      'jam_presensi': jamPresensi,
      'location_name': locationName,
      'type': type,
    };
  }

  factory PresensiModel.empty() {
    return PresensiModel(
      id: '',
      userId: '',
      userName: '',
      tanggalPresensi: '',
      jamPresensi: '',
      locationName: '',
      type: '',
    );
  }
}
