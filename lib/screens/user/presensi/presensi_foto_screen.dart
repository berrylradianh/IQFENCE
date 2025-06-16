import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class PresensiFotoScreen extends StatefulWidget {
  final String locationId;
  final String locationName;
  final Map<String, double> locationCoord;
  final bool isDatang; // Parameter baru untuk menentukan tipe presensi

  const PresensiFotoScreen({
    super.key,
    required this.locationId,
    required this.locationName,
    required this.locationCoord,
    this.isDatang = true, // Default ke presensi datang
  });

  @override
  _PresensiFotoScreenState createState() => _PresensiFotoScreenState();
}

class _PresensiFotoScreenState extends State<PresensiFotoScreen> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  XFile? _imageFile;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    debugPrint('PresensiFotoScreen initState: locationId=${widget.locationId}, '
        'locationName=${widget.locationName}, locationCoord=${widget.locationCoord}, '
        'isDatang=${widget.isDatang}');
    _initializeCamera();
    _getCurrentPosition();
  }

  // Inisialisasi kamera depan
  Future<void> _initializeCamera() async {
    try {
      debugPrint('Menginisialisasi kamera...');
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
      );

      _initializeControllerFuture = _cameraController!.initialize();
      await _initializeControllerFuture;
      debugPrint('Kamera berhasil diinisialisasi');
      setState(() {});
    } catch (e) {
      debugPrint('Error inisialisasi kamera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal inisialisasi kamera: $e'),
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

  // Mengambil foto
  Future<void> _takePicture() async {
    try {
      debugPrint('Mengambil foto...');
      await _initializeControllerFuture;
      final image = await _cameraController!.takePicture();
      setState(() {
        _imageFile = image;
        debugPrint('Foto berhasil diambil: ${image.path}');
      });

      _showConfirmationDialog();
    } catch (e) {
      debugPrint('Error mengambil foto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Menampilkan dialog konfirmasi
  void _showConfirmationDialog() {
    debugPrint('Menampilkan dialog konfirmasi');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Apakah anda yakin foto sudah sesuai?'),
            if (_imageFile != null)
              Image.file(
                File(_imageFile!.path),
                height: 200,
                fit: BoxFit.cover,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('Foto diulang');
              Navigator.pop(context);
              setState(() {
                _imageFile = null;
              });
            },
            child: const Text('Foto Ulang'),
          ),
          TextButton(
            onPressed: () {
              debugPrint('Foto dikonfirmasi');
              Navigator.pop(context);
              _savePresensi();
            },
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }

  // Menyimpan data presensi ke Firestore
  void _savePresensi() async {
    debugPrint('Memulai _savePresensi');
    if (_currentPosition == null) {
      debugPrint('Current Position is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mendapatkan lokasi saat ini'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    debugPrint(
        'Current Position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget.locationCoord['latitude']!,
      widget.locationCoord['longitude']!,
    );
    debugPrint('Jarak ke lokasi: $distance meter');

    if (distance > 50) {
      debugPrint('Jarak lebih dari 50 meter');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Anda berada di luar radius 50 meter dari lokasi tujuan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final timeFormat = DateFormat('HH:mm:ss');
    final dateFormat = DateFormat('dd MMM yyyy');
    final jamPresensi = timeFormat.format(now);
    final tanggalPresensi = dateFormat.format(now);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    debugPrint(
        'Jam Presensi: $jamPresensi, Tanggal Presensi: $tanggalPresensi');
    debugPrint('User ID: $userId');

    if (userId == null) {
      debugPrint('Pengguna tidak terautentikasi');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengguna tidak terautentikasi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Ambil data pengguna dari koleksi users untuk mendapatkan karyawan_id
      debugPrint('Mengambil data pengguna dari koleksi users...');
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        debugPrint('Data pengguna tidak ditemukan');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data pengguna tidak ditemukan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? karyawanId = userData['karyawan_id'];

      if (karyawanId == null) {
        debugPrint('Karyawan ID tidak ditemukan');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Karyawan ID tidak ditemukan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      debugPrint('Karyawan ID: $karyawanId');
      debugPrint('Menulis ke Firestore');
      await FirebaseFirestore.instance.collection('presensi').add({
        'user_id': userId, // Mengganti karyawan_id menjadi user_id
        'karyawan_id': karyawanId, // Menambahkan karyawan_id dari koleksi users
        'type': widget.isDatang ? 'Presensi Datang' : 'Presensi Pulang',
        'jam_presensi': jamPresensi,
        'tanggal_presensi': tanggalPresensi,
        'lokasi_presensi': {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
        },
        'location_id': widget.locationId,
        'location_name': widget.locationName,
      });
      debugPrint('Data berhasil ditulis ke Firestore');
    } catch (e) {
      debugPrint('Error menyimpan presensi: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan presensi: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${widget.isDatang ? 'Presensi Datang' : 'Presensi Pulang'} berhasil dicatat di ${widget.locationName}'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, {
      widget.isDatang ? 'datangTime' : 'pulangTime':
          '$jamPresensi - $tanggalPresensi',
      'locationName': widget.locationName,
      'locationId': widget.locationId,
    });
  }

  @override
  void dispose() {
    debugPrint('Dispose PresensiFotoScreen');
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Ambil Foto Presensi ${widget.isDatang ? 'Datang' : 'Pulang'}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_cameraController!),
                Positioned(
                  bottom: 20,
                  left: MediaQuery.of(context).size.width / 2 - 30,
                  child: FloatingActionButton(
                    onPressed: _takePicture,
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.camera_alt, color: Colors.white),
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            debugPrint('Snapshot error: ${snapshot.error}');
            return const Center(
              child: Text('Error inisialisasi kamera'),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
