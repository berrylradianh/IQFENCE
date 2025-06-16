import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminRiwayatScreen extends StatefulWidget {
  const AdminRiwayatScreen({super.key});

  @override
  State<AdminRiwayatScreen> createState() => _AdminRiwayatScreenState();
}

class _AdminRiwayatScreenState extends State<AdminRiwayatScreen> {
  String? _selectedUserId;
  List<Map<String, dynamic>> _users = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID');
    _fetchUsers();
  }

  // Ambil data semua user dan nama dari karyawan jika nama di users null
  Future<void> _fetchUsers() async {
    try {
      final userSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      List<Map<String, dynamic>> users = [];

      for (var doc in userSnapshot.docs) {
        final userData = doc.data();
        String name = userData['nama'] ?? '';
        final karyawanId = userData['karyawan_id'] ?? '';

        // Jika nama null dan ada karyawan_id, ambil nama dari koleksi karyawan
        if (name.isEmpty && karyawanId.isNotEmpty) {
          final karyawanDoc = await FirebaseFirestore.instance
              .collection('karyawan')
              .doc(karyawanId)
              .get();
          if (karyawanDoc.exists) {
            name = karyawanDoc.data()?['nama'] ?? 'Unknown';
          }
        }

        // Jika masih kosong, set default 'Unknown'
        name = name.isEmpty ? 'Unknown' : name;

        users.add({
          'id': doc.id,
          'name': name,
          'email': userData['email'] ?? '',
        });
      }

      setState(() {
        _users = users;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Riwayat Presensi Admin',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Filter dan Search
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Pilih User',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedUserId,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Semua User'),
                    ),
                    ..._users.map((user) => DropdownMenuItem<String>(
                          value: user['id'],
                          child: Text(user['name']),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedUserId = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Cari berdasarkan nama user',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ],
            ),
          ),
          // List Riwayat
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedUserId != null
                  ? FirebaseFirestore.instance
                      .collection('presensi')
                      .where('user_id', isEqualTo: _selectedUserId)
                      .orderBy('tanggal_presensi', descending: true)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('presensi')
                      .orderBy('tanggal_presensi', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('Tidak ada data riwayat presensi'));
                }

                // Kelompokkan data
                final presensiDocs = snapshot.data!.docs;
                Map<String, Map<String, List<Map<String, dynamic>>>>
                    groupedPresensi = {};

                for (var doc in presensiDocs) {
                  final presensi = doc.data() as Map<String, dynamic>;
                  final tanggalPresensi = presensi['tanggal_presensi'] ?? '';
                  final userId = presensi['user_id'] ?? '';
                  final user = _users.firstWhere(
                    (u) => u['id'] == userId,
                    orElse: () => {
                      'name': 'Unknown',
                      'email': '',
                      'id': userId,
                    },
                  );

                  // Filter berdasarkan search
                  if (_searchController.text.isNotEmpty &&
                      !user['name']
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase())) {
                    continue;
                  }

                  if (!groupedPresensi.containsKey(tanggalPresensi)) {
                    groupedPresensi[tanggalPresensi] = {};
                  }
                  if (!groupedPresensi[tanggalPresensi]!.containsKey(userId)) {
                    groupedPresensi[tanggalPresensi]![userId] = [];
                  }
                  presensi['user_name'] = user['name'];
                  groupedPresensi[tanggalPresensi]![userId]!.add(presensi);
                }

                final sortedDates = groupedPresensi.keys.toList()
                  ..sort((a, b) {
                    DateTime? dateA = _parseDate(a);
                    DateTime? dateB = _parseDate(b);
                    return dateB?.compareTo(dateA ?? DateTime.now()) ?? 0;
                  });

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final tanggalPresensi = sortedDates[index];
                    final userPresensi = groupedPresensi[tanggalPresensi]!;

                    DateTime? parsedDate = _parseDate(tanggalPresensi);
                    final formattedDate = parsedDate != null
                        ? DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                            .format(parsedDate)
                        : tanggalPresensi;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: userPresensi.keys.map((userId) {
                        final presensiList = userPresensi[userId]!;
                        final user = _users.firstWhere(
                          (u) => u['id'] == userId,
                          orElse: () => {
                            'name': 'Unknown',
                            'email': '',
                            'id': userId,
                          },
                        );

                        presensiList.sort((a, b) {
                          final timeA = a['jam_presensi'] ?? '00:00:00';
                          final timeB = b['jam_presensi'] ?? '00:00:00';
                          return timeA.compareTo(timeB);
                        });

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$formattedDate - ${user['name']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...presensiList.map((presensi) {
                                  final jamPresensi =
                                      presensi['jam_presensi'] ?? '';
                                  final locationName =
                                      presensi['location_name'] ?? 'Unknown';
                                  final type = presensi['type'] ?? '';
                                  final userName =
                                      presensi['user_name'] ?? 'Unknown';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          type == 'Presensi Pulang'
                                              ? LucideIcons.logOut
                                              : LucideIcons.logIn,
                                          color: type == 'Presensi Pulang'
                                              ? Colors.red
                                              : Colors.blue,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '$jamPresensi di $locationName',
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                              Text(
                                                'User: $userName',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _parseDate(String dateStr) {
    try {
      return DateFormat('d MMM yyyy', 'id_ID').parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
