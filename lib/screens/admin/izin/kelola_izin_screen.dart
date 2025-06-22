import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iqfence/service/google_drive_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class KelolaIzinScreen extends StatefulWidget {
  const KelolaIzinScreen({super.key});

  @override
  State<KelolaIzinScreen> createState() => _KelolaIzinScreenState();
}

class _KelolaIzinScreenState extends State<KelolaIzinScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GoogleDriveService _googleDriveService = GoogleDriveService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<bool?> _showApprovalConfirmationDialog(
      BuildContext context, String action) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Konfirmasi $action Izin?'),
        content: Text(
          'Anda akan $action izin karyawan ini.',
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

  Future<void> _updateIzinStatus(
      BuildContext context, String docId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('izin')
          .doc(docId)
          .update({'statusIzin': status});
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
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic date) {
    try {
      if (date is Timestamp) {
        return DateFormat('dd MMM yyyy').format(date.toDate());
      } else if (date is String) {
        return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
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
          title: const Text('Kelola Izin Karyawan'),
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
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Aktif Tab
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('izin')
                          .where('statusIzin', isEqualTo: 'Menunggu')
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
                              child: Text('Tidak ada izin aktif'));
                        }

                        final izinDocs = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: izinDocs.length,
                          itemBuilder: (context, index) {
                            final doc = izinDocs[index];
                            final izin = doc.data() as Map<String, dynamic>;
                            final userData =
                                izin['userData'] as Map<String, dynamic>;
                            final alamat = userData['alamat'] ?? 'No alamat';
                            final nama = userData['nama'] ?? 'No nama';
                            final posisi = userData['posisi'] ?? 'No posisi';
                            final fotoPath =
                                userData['foto'] ?? 'assets/placeholder.png';
                            final tanggalMulai =
                                _formatDate(izin['izinStartDate']);
                            final tanggalSelesai =
                                _formatDate(izin['izinEndDate']);
                            final alasan = izin['izinReason'] ?? 'No alasan';

                            final directImageUrl =
                                _googleDriveService.getDirectImageUrl(fotoPath);

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
                                          child: Image.network(
                                            directImageUrl,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
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
                                        const Icon(LucideIcons.calendar,
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
                                        const Icon(LucideIcons.calendar,
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
                                              await _updateIzinStatus(
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
                                              await _updateIzinStatus(
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
                          .collection('izin')
                          .where('statusIzin',
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
                              child: Text('Tidak ada izin selesai'));
                        }

                        final izinDocs = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: izinDocs.length,
                          itemBuilder: (context, index) {
                            final doc = izinDocs[index];
                            final izin = doc.data() as Map<String, dynamic>;
                            final userData =
                                izin['userData'] as Map<String, dynamic>;
                            final alamat = userData['alamat'] ?? 'No alamat';
                            final nama = userData['nama'] ?? 'No nama';
                            final posisi = userData['posisi'] ?? 'No posisi';
                            final fotoPath =
                                userData['foto'] ?? 'assets/placeholder.png';
                            final statusIzin = izin['statusIzin'] ?? 'Selesai';
                            final tanggalMulai =
                                _formatDate(izin['izinStartDate']);
                            final tanggalSelesai =
                                _formatDate(izin['izinEndDate']);
                            final alasan = izin['izinReason'] ?? 'No alasan';

                            final directImageUrl =
                                _googleDriveService.getDirectImageUrl(fotoPath);

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
                                          child: Image.network(
                                            directImageUrl,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
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
                                        const Icon(LucideIcons.calendar,
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
                                        const Icon(LucideIcons.calendar,
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
                                            color: statusIzin == 'Diizinkan'
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          statusIzin == 'Diizinkan'
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
