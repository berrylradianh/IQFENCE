import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class PresensiScreen extends StatefulWidget {
  final bool isAdmin;

  const PresensiScreen({super.key, required this.isAdmin});

  @override
  _PresensiScreenState createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen> {
  Position? _currentPosition;
  XFile? _capturedImage;

  // Data lokasi presensi (dapat diatur oleh admin)
  List<Map<String, dynamic>> locations = [
    {
      'name': 'Kantor Pusat',
      'latitude': -6.200000,
      'longitude': 106.816666,
      'radius': 100.0, // Radius dalam meter
    },
  ];

  @override
  void initState() {
    super.initState();
    if (!widget.isAdmin) {
      _getCurrentLocation(); // Dapatkan lokasi untuk user
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Periksa apakah layanan lokasi diaktifkan
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Layanan lokasi tidak diaktifkan.');
    }

    // Periksa izin lokasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Izin lokasi ditolak secara permanen.');
    }

    // Dapatkan lokasi saat ini
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });
  }

  double _calculateDistance(double targetLatitude, double targetLongitude) {
    if (_currentPosition == null) return double.infinity;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      targetLatitude,
      targetLongitude,
    );
  }

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _capturedImage = image;
      });
    }
  }

  void _confirmPresence(double targetLatitude, double targetLongitude, double radius) {
    final distance = _calculateDistance(targetLatitude, targetLongitude);

    if (distance > radius) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Di Luar Area'),
          content: const Text('Anda berada di luar area yang ditentukan.'),
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

    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan ambil gambar terlebih dahulu.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Presensi Berhasil'),
        content: const Text(
            'Anda berhasil melakukan presensi. Terima kasih sudah hadir tepat waktu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addNewLocation() {
    // Contoh logika untuk menambahkan lokasi baru oleh admin
    setState(() {
      locations.add({
        'name': 'Lokasi Baru',
        'latitude': -6.210000,
        'longitude': 106.820000,
        'radius': 5.0,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Admin Dashboard' : 'Presensi'),
        centerTitle: true,
      ),
      body: widget.isAdmin ? _buildAdminView() : _buildUserView(),
    );
  }

  Widget _buildAdminView() {
    // Tampilan untuk admin
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Lokasi Presensi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final location = locations[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.amber),
                    title: Text(location['name']),
                    subtitle: Text(
                        'Lat: ${location['latitude']}, Lng: ${location['longitude']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // Aksi untuk mengedit lokasi
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _addNewLocation,
            child: const Text('Tambah Lokasi'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserView() {
    // Tampilan untuk user
    if (locations.isEmpty) {
      return const Center(child: Text('Tidak ada lokasi presensi yang tersedia.'));
    }

    final location = locations.first; // Lokasi pertama sebagai contoh
    final distance = _calculateDistance(location['latitude'], location['longitude']);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on, color: Colors.amber),
              title: const Text('Lokasi Tujuan'),
              subtitle: Text('Lat: ${location['latitude']}, Lng: ${location['longitude']}'),
              trailing: distance > location['radius']
                  ? const Text(
                      'Di Luar Area',
                      style: TextStyle(color: Colors.red),
                    )
                  : const Text(
                      'Di Dalam Area',
                      style: TextStyle(color: Colors.green),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: distance <= location['radius'] ? _captureImage : null,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Ambil Gambar'),
          ),
          if (_capturedImage != null)
            Column(
              children: [
                Image.file(
                  File(_capturedImage!.path),
                  height: 200,
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => _confirmPresence(
                    location['latitude'],
                    location['longitude'],
                    location['radius'],
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Konfirmasi'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}