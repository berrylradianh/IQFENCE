import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iqfence/screens/admin/karyawan/edit_karyawan_screen.dart';
import 'package:iqfence/screens/admin/karyawan/tambah_karyawan_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';

class KelolaKaryawanScreen extends StatefulWidget {
  const KelolaKaryawanScreen({super.key});

  @override
  State<KelolaKaryawanScreen> createState() => _KelolaKaryawanScreenState();
}

class _KelolaKaryawanScreenState extends State<KelolaKaryawanScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Listener untuk memperbarui query pencarian saat teks berubah
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  // Fungsi untuk menampilkan dialog konfirmasi hapus
  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Hapus data karyawan yang dipilih?'),
        content: const Text(
          'Anda akan menghapus data karyawan ini secara permanen.',
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
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Ya, Lanjutkan',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk menghapus karyawan dari Firestore
  Future<void> _deleteKaryawan(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('karyawan')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Karyawan berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kelola Data Karyawan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar dan Tombol Tambah
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari Karyawan',
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
                        builder: (context) => const TambahKaryawanScreen(),
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
              'Karyawan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('karyawan')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Tidak ada data karyawan'));
                  }

                  // Filter karyawan berdasarkan query pencarian
                  final karyawanDocs = snapshot.data!.docs.where((doc) {
                    final karyawan = doc.data() as Map<String, dynamic>;
                    final nama = (karyawan['nama'] ?? '').toLowerCase();
                    return nama.contains(_searchQuery);
                  }).toList();

                  if (karyawanDocs.isEmpty && _searchQuery.isNotEmpty) {
                    return const Center(
                        child: Text('Tidak ada karyawan yang cocok'));
                  }

                  return ListView.builder(
                    itemCount: karyawanDocs.length,
                    itemBuilder: (context, index) {
                      final doc = karyawanDocs[index];
                      final karyawan = doc.data() as Map<String, dynamic>;
                      final imagePath = karyawan['foto'] != null
                          ? 'assets/${karyawan['foto']}'
                          : 'assets/placeholder.png';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Foto
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  imagePath,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/placeholder.png',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      karyawan['nama'] ??
                                          'Nama Tidak Diketahui',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        karyawan['alamat'] ??
                                            'Alamat Tidak Diketahui',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Tombol
                              Column(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditKaryawanScreen(
                                            docId: doc.id,
                                            karyawanData: karyawan,
                                          ),
                                        ),
                                      );
                                    },
                                    icon:
                                        const Icon(LucideIcons.edit3, size: 16),
                                    label: const Text('Ubah'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final confirmDelete =
                                          await _showDeleteConfirmationDialog(
                                              context);
                                      if (confirmDelete == true) {
                                        await _deleteKaryawan(context, doc.id);
                                      }
                                    },
                                    icon:
                                        const Icon(LucideIcons.trash, size: 16),
                                    label: const Text('Hapus'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
