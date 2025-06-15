import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iqfence/screens/admin/lokasi/edit_lokasi_screen.dart';
import 'package:iqfence/screens/admin/lokasi/tambah_lokasi_screen.dart';

class KelolaLokasiScreen extends StatefulWidget {
  const KelolaLokasiScreen({super.key});

  @override
  State<KelolaLokasiScreen> createState() => _KelolaLokasiScreenState();
}

class _KelolaLokasiScreenState extends State<KelolaLokasiScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = position;
    });
  }

  String _getRadiusString(String koordinat) {
    if (_currentPosition == null) return 'Loading...';
    List<String> coords = koordinat.split(',');
    double lat2 = double.parse(coords[0].trim());
    double lon2 = double.parse(coords[1].trim());
    double radius = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat2,
      lon2,
    );
    return '${radius.toStringAsFixed(2)} meter';
  }

  Future<void> _deleteLokasi(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('locations')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error menghapus lokasi: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kelola Lokasi Karyawan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari Lokasi',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TambahLokasiScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Lokasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('locations')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Tidak ada data lokasi'));
                  }

                  final lokasiDocs = snapshot.data!.docs.where((doc) {
                    final lokasi = doc.data() as Map<String, dynamic>;
                    final nama = (lokasi['namaLokasi'] ?? '').toLowerCase();
                    return nama.contains(_searchQuery);
                  }).toList();

                  if (lokasiDocs.isEmpty && _searchQuery.isNotEmpty) {
                    return const Center(
                        child: Text('Tidak ada lokasi yang cocok'));
                  }

                  return ListView.builder(
                    itemCount: lokasiDocs.length,
                    itemBuilder: (context, index) {
                      final doc = lokasiDocs[index];
                      final lokasi = doc.data() as Map<String, dynamic>;
                      final namaLokasi =
                          lokasi['namaLokasi'] ?? 'Nama Tidak Diketahui';
                      final koordinat = lokasi['koordinat'] ?? '0.0, 0.0';

                      return _LokasiCard(
                        namaLokasi: namaLokasi,
                        koordinat: koordinat,
                        radius: _getRadiusString(koordinat),
                        doc: doc,
                        lokasi: lokasi,
                        onDelete: _deleteLokasi,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LokasiCard extends StatelessWidget {
  final String namaLokasi;
  final String koordinat;
  final String radius;
  final QueryDocumentSnapshot<Object?> doc;
  final Map<String, dynamic> lokasi;
  final Future<void> Function(String) onDelete;

  const _LokasiCard({
    required this.namaLokasi,
    required this.koordinat,
    required this.radius,
    required this.doc,
    required this.lokasi,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(namaLokasi,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Koordinat: $koordinat'),
            const SizedBox(height: 4),
            Text('Radius: $radius'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditLokasiScreen(
                          docId: doc.id,
                          lokasiData: lokasi,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700]),
                  child:
                      const Text('Edit', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Hapus Lokasi'),
                        content: const Text(
                          'Hapus lokasi data yang dipilih?\n'
                          'Anda akan menghapus data lokasi ini secara permanen.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'Tidak, Batalkan',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context, true);
                              await onDelete(doc.id);
                            },
                            child: const Text(
                              'Ya, Lanjutkan',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ).then((value) {
                      if (value == true) {
                        // No additional action needed here as onDelete is called directly
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Hapus',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
