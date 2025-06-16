import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'presensi_foto_screen.dart'; // Import the new screen

class PresensiDatangScreen extends StatefulWidget {
  const PresensiDatangScreen({super.key});

  @override
  _PresensiDatangScreenState createState() => _PresensiDatangScreenState();
}

class _PresensiDatangScreenState extends State<PresensiDatangScreen> {
  String? _selectedLocationId;
  String? _selectedLocationName;
  Map<String, double>? _selectedLocationCoord;
  List<Map<String, dynamic>> _locations = [];
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
    _getCurrentPosition();
  }

  // Mengambil daftar lokasi dari Firestore berdasarkan location_ids karyawan
  Future<void> _fetchLocations() async {
    try {
      debugPrint('Memulai _fetchLocations');
      final userId = FirebaseAuth.instance.currentUser?.uid;
      debugPrint('userId: $userId');
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengguna tidak terautentikasi'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        debugPrint('Dokumen pengguna tidak ditemukan');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data pengguna tidak ditemukan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final karyawanId = userDoc['karyawan_id'];
      debugPrint('karyawanId: $karyawanId');
      if (karyawanId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID karyawan tidak ditemukan di data pengguna'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final karyawanDoc = await FirebaseFirestore.instance
          .collection('karyawan')
          .doc(karyawanId)
          .get();

      if (!karyawanDoc.exists) {
        debugPrint('Dokumen karyawan tidak ditemukan');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data karyawan tidak ditemukan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final locationIds = List<String>.from(karyawanDoc['location_ids'] ?? []);
      debugPrint('locationIds: $locationIds');

      if (locationIds.isEmpty) {
        debugPrint('Tidak ada lokasi terkait');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada lokasi terkait untuk karyawan ini'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('locations')
          .where(FieldPath.documentId, whereIn: locationIds)
          .get();

      setState(() {
        _locations = snapshot.docs.map((doc) {
          final coordStr = doc['koordinat'] as String;
          final coords = coordStr.split(', ').map(double.parse).toList();
          return {
            'id': doc.id,
            'namaLokasi': doc['namaLokasi'],
            'koordinat': {'latitude': coords[0], 'longitude': coords[1]},
          };
        }).toList();
        debugPrint('Lokasi berhasil dimuat: ${_locations.length} lokasi');

        if (_locations.isNotEmpty) {
          _selectedLocationId = _locations[0]['id'];
          _selectedLocationName = _locations[0]['namaLokasi'];
          _selectedLocationCoord = _locations[0]['koordinat'];
        }
      });
    } catch (e) {
      debugPrint('Error di _fetchLocations: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat lokasi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Mendapatkan posisi pengguna saat ini
  Future<void> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Layanan lokasi dinonaktifkan');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layanan lokasi dinonaktifkan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Izin lokasi ditolak');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin lokasi ditolak'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Izin lokasi ditolak secara permanen');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin lokasi ditolak secara permanen'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        debugPrint(
            'Posisi saat ini: ${position.latitude}, ${position.longitude}');
      });
    } catch (e) {
      debugPrint('Error di _getCurrentPosition: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mendapatkan lokasi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Navigasi ke PresensiFotoScreen
  void _recordPresensi() {
    if (_selectedLocationId == null) {
      debugPrint('Lokasi belum dipilih');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih lokasi terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentPosition == null || _selectedLocationCoord == null) {
      debugPrint('Posisi saat ini atau koordinat lokasi tujuan tidak tersedia');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mendapatkan lokasi saat ini atau lokasi tujuan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Hitung jarak antara posisi saat ini dan lokasi tujuan
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _selectedLocationCoord!['latitude']!,
      _selectedLocationCoord!['longitude']!,
    );
    debugPrint('Jarak ke lokasi: $distance meter');

    // Cek apakah jarak lebih dari 50 meter
    if (distance > 50) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lokasi Tidak Valid'),
          content: const Text(
              'Anda berada di luar radius 50 meter dari lokasi tujuan. Silakan mendekati lokasi yang dipilih.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Navigasi ke PresensiFotoScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresensiFotoScreen(
          locationId: _selectedLocationId!,
          locationName: _selectedLocationName!,
          locationCoord: _selectedLocationCoord!,
        ),
      ),
    ).then((result) {
      if (result != null) {
        // Tangani hasil dari PresensiFotoScreen
        final formattedTime = result['datangTime'];
        final locationName = result['locationName'];
        debugPrint('Presensi dicatat: $locationName pada $formattedTime');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Presensi Datang berhasil dicatat di $locationName'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi Datang'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Dropdown untuk memilih lokasi
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedLocationId,
              decoration: const InputDecoration(
                labelText: 'Pilih Lokasi',
                border: OutlineInputBorder(),
              ),
              items: _locations.isEmpty
                  ? [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Tidak ada lokasi tersedia'),
                      )
                    ]
                  : _locations.map((location) {
                      return DropdownMenuItem<String>(
                        value: location['id'],
                        child: Text(location['namaLokasi']),
                      );
                    }).toList(),
              onChanged: _locations.isEmpty
                  ? null
                  : (value) {
                      if (value != null) {
                        debugPrint('Lokasi dipilih: $value');
                        setState(() {
                          _selectedLocationId = value;
                          final selected = _locations.firstWhere(
                              (loc) => loc['id'] == value,
                              orElse: () => {});
                          if (selected.isNotEmpty) {
                            _selectedLocationName = selected['namaLokasi'];
                            _selectedLocationCoord = selected['koordinat'];
                            debugPrint(
                                'Lokasi ditemukan: ${selected['namaLokasi']}');
                          }
                        });
                      }
                    },
            ),
          ),
          // Card informasi lokasi tujuan
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lokasi Tujuan',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedLocationName ?? 'Belum dipilih',
                                style: const TextStyle(fontSize: 16),
                              ),
                              if (_selectedLocationCoord != null)
                                Text(
                                  '${_selectedLocationCoord!['latitude']}, ${_selectedLocationCoord!['longitude']}',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _recordPresensi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Lakukan Presensi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
