import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iqfence/screens/admin/lembur/tambah_lembur_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';

class KelolaLemburScreen extends StatefulWidget {
  const KelolaLemburScreen({super.key});

  @override
  State<KelolaLemburScreen> createState() => _KelolaLemburScreenState();
}

class _KelolaLemburScreenState extends State<KelolaLemburScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<bool?> _showApprovalConfirmationDialog(
      BuildContext context, String action) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Konfirmasi $action Lembur?'),
        content: Text(
          'Anda akan $action lembur karyawan ini.',
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
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateLemburStatus(
      BuildContext context, String docId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('lembur')
          .doc(docId)
          .update({'statusLembur': status});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Diizinkan berhasil $status')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic date) {
    try {
      if (date is Timestamp) {
        return DateFormat('dd MMM yyyy HH:mm').format(date.toDate());
      } else if (date is String) {
        return DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(date));
      }
      return 'No tanggal';
    } catch (e) {
      return 'No tanggal';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Kelola Lembur Karyawan'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Aktif'),
              Tab(text: 'Selesai'),
            ],
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.amber[700],
          ),
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
                          builder: (context) => const TambahLemburScreen(),
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
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Aktif Tab
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('lembur')
                          .where('statusLembur', isEqualTo: 'Aktif')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                              child: Text('Tidak ada lembur aktif'));
                        }

                        final lemburDocs = snapshot.data!.docs.where((doc) {
                          final lembur = doc.data() as Map<String, dynamic>;
                          final nama =
                              (lembur['userData']['nama'] ?? '').toLowerCase();
                          return nama.contains(_searchQuery);
                        }).toList();

                        if (lemburDocs.isEmpty && _searchQuery.isNotEmpty) {
                          return const Center(
                              child: Text('Tidak ada karyawan yang cocok'));
                        }

                        return ListView.builder(
                          itemCount: lemburDocs.length,
                          itemBuilder: (context, index) {
                            final doc = lemburDocs[index];
                            final lembur = doc.data() as Map<String, dynamic>;
                            final userData =
                                lembur['userData'] as Map<String, dynamic>;
                            final alamat = userData['alamat'] ?? 'No alamat';
                            final nama = userData['nama'] ?? 'No nama';
                            final posisi = userData['posisi'] ?? 'No posisi';
                            final fotoPath =
                                userData['foto'] ?? 'assets/placeholder.png';
                            final tanggalMulai =
                                _formatDate(lembur['lemburStartDate']);
                            final tanggalSelesai =
                                _formatDate(lembur['lemburEndDate']);
                            final alasan =
                                lembur['lemburReason'] ?? 'No alasan';

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
                                    // [Symbol Check] [Posisi]
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.user,
                                            color: Colors.green, size: 16),
                                        const SizedBox(width: 8),
                                        Text(posisi,
                                            style:
                                                const TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // [Symbol Location] [Alamat]
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.mapPin,
                                            color: Colors.blue, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(alamat,
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // [Photo User] [Name]
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.asset(
                                            fotoPath,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/' + fotoPath,
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(nama,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // [Tanggal Mulai]
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.clock,
                                            color: Colors.blue, size: 16),
                                        const SizedBox(width: 8),
                                        Text('Mulai: $tanggalMulai',
                                            style:
                                                const TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // [Tanggal Selesai]
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.clock,
                                            color: Colors.blue, size: 16),
                                        const SizedBox(width: 8),
                                        Text('Selesai: $tanggalSelesai',
                                            style:
                                                const TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // [Alasan]
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.fileText,
                                            color: Colors.blue, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text('Alasan: $alasan',
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Straight Line
                                    const Divider(
                                        color: Colors.grey, thickness: 1),
                                    const SizedBox(height: 8),
                                    // [Button Izinkan] [Button Ditolak]
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            final confirm =
                                                await _showApprovalConfirmationDialog(
                                                    context, 'Dizinkan');
                                            if (confirm == true) {
                                              await _updateLemburStatus(
                                                  context, doc.id, 'Diizinkan');
                                            }
                                          },
                                          icon: const Icon(LucideIcons.check,
                                              size: 16),
                                          label: const Text('Izinkan'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[600],
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            textStyle:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            final confirm =
                                                await _showApprovalConfirmationDialog(
                                                    context, 'Ditolak');
                                            if (confirm == true) {
                                              await _updateLemburStatus(
                                                  context, doc.id, 'Ditolak');
                                            }
                                          },
                                          icon: const Icon(LucideIcons.x,
                                              size: 16),
                                          label: const Text('Ditolak'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red[600],
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            textStyle:
                                                const TextStyle(fontSize: 12),
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
                    // Selesai Tab
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('lembur')
                          .where('statusLembur',
                              whereIn: ['Diizinkan', 'Ditolak']).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                              child: Text('Tidak ada lembur selesai'));
                        }

                        final lemburDocs = snapshot.data!.docs.where((doc) {
                          final lembur = doc.data() as Map<String, dynamic>;
                          final nama =
                              (lembur['userData']['nama'] ?? '').toLowerCase();
                          return nama.contains(_searchQuery);
                        }).toList();

                        if (lemburDocs.isEmpty && _searchQuery.isNotEmpty) {
                          return const Center(
                              child: Text('Tidak ada karyawan yang cocok'));
                        }

                        return ListView.builder(
                          itemCount: lemburDocs.length,
                          itemBuilder: (context, index) {
                            final doc = lemburDocs[index];
                            final lembur = doc.data() as Map<String, dynamic>;
                            final userData =
                                lembur['userData'] as Map<String, dynamic>;
                            final alamat = userData['alamat'] ?? 'No alamat';
                            final nama = userData['nama'] ?? 'No nama';
                            final posisi = userData['posisi'] ?? 'No posisi';
                            final fotoPath =
                                userData['foto'] ?? 'assets/placeholder.png';
                            final statusLembur =
                                lembur['statusLembur'] ?? 'Selesai';
                            final tanggalMulai =
                                _formatDate(lembur['lemburStartDate']);
                            final tanggalSelesai =
                                _formatDate(lembur['lemburEndDate']);
                            final alasan =
                                lembur['lemburReason'] ?? 'No alasan';

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
                                    // [Symbol Check] [Posisi]
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.user,
                                            color: Colors.green, size: 16),
                                        const SizedBox(width: 8),
                                        Text(posisi,
                                            style:
                                                const TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // [Symbol Location] [Alamat]
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.mapPin,
                                            color: Colors.blue, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(alamat,
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // [Photo User] [Name]
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.asset(
                                            fotoPath,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/' + fotoPath,
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(nama,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // [Tanggal Mulai]
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.clock,
                                            color: Colors.blue, size: 16),
                                        const SizedBox(width: 8),
                                        Text('Mulai: $tanggalMulai',
                                            style:
                                                const TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // [Tanggal Selesai]
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.clock,
                                            color: Colors.blue, size: 16),
                                        const SizedBox(width: 8),
                                        Text('Selesai: $tanggalSelesai',
                                            style:
                                                const TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // [Alasan]
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.fileText,
                                            color: Colors.blue, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text('Alasan: $alasan',
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Straight Line
                                    const Divider(
                                        color: Colors.grey, thickness: 1),
                                    const SizedBox(height: 8),
                                    // Status Information
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: statusLembur == 'Diizinkan'
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          statusLembur == 'Diizinkan'
                                              ? 'Diizinkan'
                                              : 'Ditolak',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
