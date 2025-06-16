import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:iqfence/providers/Auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

class AktivitasScreen extends StatefulWidget {
  const AktivitasScreen({super.key});

  @override
  State<AktivitasScreen> createState() => _AktivitasScreenState();
}

class _AktivitasScreenState extends State<AktivitasScreen> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID');
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.amber[700]!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      return DateFormat('d MMM yyyy', 'id_ID').parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final userId = auth.user.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Aktivitas',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Picker Button
            ElevatedButton.icon(
              onPressed: () => _selectDateRange(context),
              icon: const Icon(LucideIcons.calendar),
              label: Text(
                _selectedDateRange == null
                    ? 'Pilih Rentang Tanggal'
                    : '${DateFormat('d MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('d MMM yyyy').format(_selectedDateRange!.end)}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // StreamBuilder for real-time data
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
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
                    return const Center(child: Text('Tidak ada data presensi'));
                  }

                  // Group data by tanggal_presensi
                  final presensiDocs = snapshot.data!.docs;
                  Map<String, List<Map<String, dynamic>>> groupedPresensi = {};

                  for (var doc in presensiDocs) {
                    final presensi = doc.data() as Map<String, dynamic>;
                    final tanggalPresensi = presensi['tanggal_presensi'] ?? '';
                    // Apply date range filter
                    if (_selectedDateRange != null) {
                      final date = _parseDate(tanggalPresensi);
                      if (date == null ||
                          date.isBefore(_selectedDateRange!.start) ||
                          date.isAfter(_selectedDateRange!.end)) {
                        continue;
                      }
                    }
                    if (!groupedPresensi.containsKey(tanggalPresensi)) {
                      groupedPresensi[tanggalPresensi] = [];
                    }
                    groupedPresensi[tanggalPresensi]!.add(presensi);
                  }

                  // Sort dates descending
                  final sortedDates = groupedPresensi.keys.toList()
                    ..sort((a, b) {
                      DateTime? dateA = _parseDate(a);
                      DateTime? dateB = _parseDate(b);
                      return dateB?.compareTo(dateA ?? DateTime.now()) ?? 0;
                    });

                  return ListView(
                    children: [
                      for (var tanggalPresensi in sortedDates)
                        Builder(
                          builder: (context) {
                            final presensiList =
                                groupedPresensi[tanggalPresensi]!;
                            // Format date to Indonesian
                            DateTime? parsedDate = _parseDate(tanggalPresensi);
                            final formattedDate = parsedDate != null
                                ? DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                                    .format(parsedDate)
                                : tanggalPresensi;

                            // Sort presensi by jam_presensi (ascending)
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
                                      final jamPresensi =
                                          presensi['jam_presensi'] ?? '';
                                      final locationName =
                                          presensi['location_name'] ??
                                              'Unknown';
                                      final type = presensi['type'] ?? '';

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
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
                                                style: const TextStyle(
                                                    fontSize: 14),
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
                        ),
                    ],
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
