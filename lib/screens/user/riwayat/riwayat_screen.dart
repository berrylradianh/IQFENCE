import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:iqfence/providers/Auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  @override
  void initState() {
    super.initState();
    // Inisialisasi locale untuk format tanggal Indonesia
    initializeDateFormatting('id_ID');
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final userId = auth.user.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Riwayat',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('presensi')
            .where('user_id', isEqualTo: userId)
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
            return const Center(child: Text('Tidak ada data riwayat presensi'));
          }

          // Kelompokkan data berdasarkan tanggal_presensi
          final presensiDocs = snapshot.data!.docs;
          Map<String, List<Map<String, dynamic>>> groupedPresensi = {};

          for (var doc in presensiDocs) {
            final presensi = doc.data() as Map<String, dynamic>;
            final tanggalPresensi = presensi['tanggal_presensi'] ?? '';
            if (!groupedPresensi.containsKey(tanggalPresensi)) {
              groupedPresensi[tanggalPresensi] = [];
            }
            groupedPresensi[tanggalPresensi]!.add(presensi);
          }

          // Urutkan tanggal secara descending
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
              final presensiList = groupedPresensi[tanggalPresensi]!;

              // Format tanggal ke format Indonesia
              DateTime? parsedDate = _parseDate(tanggalPresensi);
              final formattedDate = parsedDate != null
                  ? DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(parsedDate)
                  : tanggalPresensi;

              // Urutkan presensi berdasarkan jam_presensi (ascending)
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
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...presensiList.map((presensi) {
                        final jamPresensi = presensi['jam_presensi'] ?? '';
                        final locationName =
                            presensi['location_name'] ?? 'Unknown';
                        final type = presensi['type'] ?? '';

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
                                child: Text(
                                  '$jamPresensi di $locationName',
                                  style: const TextStyle(fontSize: 14),
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
            },
          );
        },
      ),
    );
  }

  // Fungsi untuk parsing tanggal
  DateTime? _parseDate(String dateStr) {
    try {
      return DateFormat('d MMM yyyy', 'id_ID').parse(dateStr);
    } catch (e) {
      return null;
    }
  }
}
