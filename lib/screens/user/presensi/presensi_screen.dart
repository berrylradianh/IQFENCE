import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import 'presensi_datang_screen.dart';
import 'presensi_pulang_screen.dart'; // Tambahkan import

class PresensiScreen extends StatefulWidget {
  const PresensiScreen({super.key});

  @override
  _PresensiScreenState createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen> {
  String? _datangTime;
  String? _pulangTime;
  String? _selectedLocationId;
  String? _selectedLocationName;
  LatLng? _selectedLocationCoord;
  List<Map<String, dynamic>> _locations = [];
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _hasPresensiDatang = false;
  bool _hasPresensiPulang = false;
  String? _datangStatus; // Menyimpan status telat/lebih cepat untuk datang
  String? _pulangStatus; // Menyimpan status telat/lebih cepat untuk pulang

  @override
  void initState() {
    super.initState();
    debugPrint('PresensiScreen initState');
    _fetchLocations();
    _getCurrentPosition();
    _checkTodayPresensi();
  }

  // Mengambil daftar lokasi dari Firestore
  Future<void> _fetchLocations() async {
    try {
      debugPrint('Mengambil lokasi dari Firestore');
      final snapshot =
          await FirebaseFirestore.instance.collection('locations').get();
      setState(() {
        _locations = snapshot.docs.map((doc) {
          final coordStr = doc['koordinat'] as String;
          final coords = coordStr.split(', ').map(double.parse).toList();
          return {
            'id': doc.id,
            'namaLokasi': doc['namaLokasi'],
            'koordinat': LatLng(coords[0], coords[1]),
          };
        }).toList();
        debugPrint('Lokasi berhasil dimuat: ${_locations.length} lokasi');
      });
    } catch (e) {
      debugPrint('Error memuat lokasi: $e');
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
      debugPrint('Memeriksa layanan lokasi...');
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

      debugPrint('Memeriksa izin lokasi...');
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

      debugPrint('Mengambil posisi saat ini...');
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

  // Menghitung status telat atau lebih cepat
  String _calculateStatus(String jamPresensi, bool isDatang) {
    final timeFormat = DateFormat('HH:mm:ss');
    final today = DateFormat('dd MMM yyyy').format(DateTime.now());
    final presensiTime = timeFormat.parse(jamPresensi);
    final referenceTime = timeFormat.parse(isDatang
        ? '08:00:00'
        : '17:00:00'); // Waktu acuan (08:00 untuk datang, 17:00 untuk pulang)

    // Buat DateTime untuk perbandingan
    final presensiDateTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      presensiTime.hour,
      presensiTime.minute,
      presensiTime.second,
    );
    final referenceDateTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      referenceTime.hour,
      referenceTime.minute,
      referenceTime.second,
    );

    // Hitung selisih waktu dalam menit
    final difference = presensiDateTime.difference(referenceDateTime).inMinutes;
    final absDifference = difference.abs();

    // Jika selisih waktu nol, tidak telat dan tidak lebih cepat
    if (difference == 0) {
      return 'Tepat waktu';
    }

    // Untuk presensi datang: telat jika lebih dari waktu acuan, lebih cepat jika kurang
    // Untuk presensi pulang: lebih cepat jika kurang dari waktu acuan, telat jika lebih
    bool isLate = isDatang ? difference > 0 : difference > 0;
    String statusPrefix = isLate ? 'Telat' : 'Lebih cepat';

    if (absDifference < 60) {
      return '$statusPrefix $absDifference menit';
    } else {
      final hours = absDifference ~/ 60;
      final minutes = absDifference % 60;
      if (minutes == 0) {
        return '$statusPrefix $hours jam';
      } else {
        return '$statusPrefix $hours jam $minutes menit';
      }
    }
  }

  // Memeriksa apakah sudah ada presensi hari ini
  Future<void> _checkTodayPresensi() async {
    try {
      debugPrint('Memeriksa presensi hari ini...');
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        debugPrint('Pengguna tidak terautentikasi');
        return;
      }

      final today = DateFormat('dd MMM yyyy').format(DateTime.now());
      final snapshot = await FirebaseFirestore.instance
          .collection('presensi')
          .where('karyawan_id', isEqualTo: userId)
          .where('tanggal_presensi', isEqualTo: today)
          .get();

      bool hasDatang = false;
      bool hasPulang = false;
      String? datangTime;
      String? pulangTime;
      String? locationName;
      String? locationId;
      LatLng? locationCoord;
      String? datangStatus;
      String? pulangStatus;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['type'] == 'Presensi Datang') {
          hasDatang = true;
          datangTime = '${data['jam_presensi']} - ${data['tanggal_presensi']}';
          locationName = data['location_name'];
          locationId = data['location_id'];
          datangStatus = _calculateStatus(data['jam_presensi'], true);
          final location = _locations.firstWhere(
            (loc) => loc['id'] == locationId,
            orElse: () => {'koordinat': const LatLng(0, 0)},
          );
          locationCoord = location['koordinat'] as LatLng?;
        } else if (data['type'] == 'Presensi Pulang') {
          hasPulang = true;
          pulangTime = '${data['jam_presensi']} - ${data['tanggal_presensi']}';
          pulangStatus = _calculateStatus(data['jam_presensi'], false);
        }
      }

      setState(() {
        _hasPresensiDatang = hasDatang;
        _hasPresensiPulang = hasPulang;
        _datangTime = datangTime;
        _pulangTime = pulangTime;
        _selectedLocationName = locationName;
        _selectedLocationId = locationId;
        _selectedLocationCoord = locationCoord;
        _datangStatus = datangStatus;
        _pulangStatus = pulangStatus;
        debugPrint('Presensi hari ini: Datang=$hasDatang, Pulang=$hasPulang, '
            'LocationName=$locationName, LocationId=$locationId, '
            'DatangStatus=$datangStatus, PulangStatus=$pulangStatus');
      });
    } catch (e) {
      debugPrint('Error memeriksa presensi: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memeriksa presensi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _recordPresensi(bool isDatang) {
    if (isDatang) {
      // Navigasi ke PresensiDatangScreen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PresensiDatangScreen()),
      ).then((result) {
        if (result != null) {
          setState(() {
            _datangTime = result['datangTime'];
            _selectedLocationName = result['locationName'];
            _selectedLocationId = result['locationId'];
            _hasPresensiDatang = true;
            // Hitung status telat/lebih cepat
            final jamPresensi = result['datangTime'].split(' - ')[0];
            _datangStatus = _calculateStatus(jamPresensi, true);
            // Update koordinat lokasi dari daftar lokasi
            final selectedLocation = _locations.firstWhere(
              (loc) => loc['id'] == _selectedLocationId,
              orElse: () => {'koordinat': const LatLng(0, 0)},
            );
            _selectedLocationCoord = selectedLocation['koordinat'] as LatLng?;
            debugPrint(
                'Presensi datang selesai: LocationName=$_selectedLocationName, '
                'LocationId=$_selectedLocationId, Status=$_datangStatus');
          });
        }
      });
    } else {
      // Validasi presensi datang sebelum presensi pulang
      if (!_hasPresensiDatang) {
        debugPrint('Presensi datang belum dilakukan');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lakukan presensi datang terlebih dahulu'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // Navigasi ke PresensiPulangScreen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PresensiPulangScreen()),
      ).then((result) {
        if (result != null) {
          setState(() {
            _pulangTime = result['pulangTime'];
            _selectedLocationName = result['locationName'];
            _selectedLocationId = result['locationId'];
            _hasPresensiPulang = true;
            // Hitung status telat/lebih cepat
            final jamPresensi = result['pulangTime'].split(' - ')[0];
            _pulangStatus = _calculateStatus(jamPresensi, false);
            // Update koordinat lokasi dari daftar lokasi
            final selectedLocation = _locations.firstWhere(
              (loc) => loc['id'] == _selectedLocationId,
              orElse: () => {'koordinat': const LatLng(0, 0)},
            );
            _selectedLocationCoord = selectedLocation['koordinat'] as LatLng?;
            debugPrint(
                'Presensi pulang selesai: LocationName=$_selectedLocationName, '
                'LocationId=$_selectedLocationId, Status=$_pulangStatus');
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Presensi Datang',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _datangTime ?? 'Belum melakukan presensi datang',
                      style: TextStyle(
                        fontSize: 16,
                        color: _datangTime != null ? Colors.black : Colors.grey,
                      ),
                    ),
                    if (_datangTime != null && _selectedLocationName != null)
                      Text(
                        'Lokasi: $_selectedLocationName',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54),
                      ),
                    if (_datangTime != null && _datangStatus != null)
                      Text(
                        'Status: $_datangStatus',
                        style: TextStyle(
                          fontSize: 14,
                          color: _datangStatus!.contains('Telat')
                              ? Colors.red
                              : _datangStatus == 'Tepat waktu'
                                  ? Colors.green
                                  : Colors.blue,
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _hasPresensiDatang
                          ? null
                          : () => _recordPresensi(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Presensi Datang'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Presensi Pulang',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _pulangTime ?? 'Belum melakukan presensi pulang',
                      style: TextStyle(
                        fontSize: 16,
                        color: _pulangTime != null ? Colors.black : Colors.grey,
                      ),
                    ),
                    if (_pulangTime != null && _selectedLocationName != null)
                      Text(
                        'Lokasi: $_selectedLocationName',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54),
                      ),
                    if (_pulangTime != null && _pulangStatus != null)
                      Text(
                        'Status: $_pulangStatus',
                        style: TextStyle(
                          fontSize: 14,
                          color: _pulangStatus!.contains('Telat')
                              ? Colors.red
                              : _pulangStatus == 'Tepat waktu'
                                  ? Colors.green
                                  : Colors.blue,
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _hasPresensiPulang
                          ? null
                          : () => _recordPresensi(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Presensi Pulang'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
