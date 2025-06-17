class UserProfile {
  final String? name;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final String? gender;
  final String? age;
  final String? photoUrl;
  final String? role;
  final String? adminId;
  final String? karyawanId;
  final String? jamKerja;
  final List<String> locationIds;

  UserProfile({
    this.name,
    this.phoneNumber,
    this.email,
    this.address,
    this.gender,
    this.age,
    this.photoUrl,
    this.role,
    this.adminId,
    this.karyawanId,
    this.jamKerja,
    this.locationIds = const [],
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      name: data['nama'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      email: data['email'] as String?,
      address: data['alamat'] as String?,
      gender: data['gender'] as String?,
      age: data['age'] as String?,
      photoUrl: data['foto'] as String?,
      role: data['posisi'] as String?,
      adminId: data['admin_id'] as String?,
      karyawanId: data['karyawan_id'] as String?,
      jamKerja: data['jam_kerja'] as String?,
      locationIds: List<String>.from(data['location_ids'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'alamat': address,
      'gender': gender,
      'age': age,
      'foto': photoUrl,
      'posisi': role,
      'admin_id': adminId,
      'karyawan_id': karyawanId,
      'jam_kerja': jamKerja,
      'location_ids': locationIds,
    };
  }
}
