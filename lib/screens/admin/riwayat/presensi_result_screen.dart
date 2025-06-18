import 'package:flutter/material.dart';
import 'package:iqfence/models/presensi_model.dart';
import 'package:iqfence/models/userModel.dart';
import 'package:iqfence/service/firestore_service.dart';
import 'package:iqfence/utils/date_utils.dart' as CustomDateUtils;

class PresensiResultScreen extends StatefulWidget {
  final UserModel user;
  final DateTimeRange dateRange;

  const PresensiResultScreen({
    super.key,
    required this.user,
    required this.dateRange,
  });

  @override
  State<PresensiResultScreen> createState() => _PresensiResultScreenState();
}

class _PresensiResultScreenState extends State<PresensiResultScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Check for null ID and show error
    if (widget.user.id == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User ID tidak tersedia')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user.id == null) {
      return const Scaffold(
        body: Center(child: Text('Error: User ID tidak tersedia')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Hasil Riwayat Presensi',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display User and Date Range
            Text(
              'Karyawan: ${widget.user.displayName ?? 'Unknown'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Periode: ${CustomDateUtils.DateUtils.formatDate(widget.dateRange.start, format: 'd MMM yyyy')} - '
              '${CustomDateUtils.DateUtils.formatDate(widget.dateRange.end, format: 'd MMM yyyy')}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Fixed Header
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Tanggal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                      'Lokasi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ListView as scrollable table
            Expanded(
              child: StreamBuilder<List<PresensiModel>>(
                stream: _firestoreService.getPresensiStream(
                    userId: widget.user.id!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Tidak ada data presensi'));
                  }

                  // Filter presensi by date range
                  final presensiList = snapshot.data!.where((presensi) {
                    final date = CustomDateUtils.DateUtils.parseDate(
                        presensi.tanggalPresensi);
                    if (date == null) return false;
                    return date.isAfter(widget.dateRange.start
                            .subtract(const Duration(days: 1))) &&
                        date.isBefore(
                            widget.dateRange.end.add(const Duration(days: 1)));
                  }).toList();

                  // Generate table data
                  final List<Map<String, dynamic>> tableData = [];
                  var currentDate = widget.dateRange.start;
                  while (currentDate.isBefore(
                      widget.dateRange.end.add(const Duration(days: 1)))) {
                    final formattedDate = CustomDateUtils.DateUtils.formatDate(
                        currentDate,
                        format: 'EEE, d MMMM yyyy');
                    final presensiForDate = presensiList
                        .where((p) =>
                            p.tanggalPresensi ==
                            CustomDateUtils.DateUtils.formatDate(currentDate,
                                format: 'd MMM yyyy'))
                        .toList();

                    String status = '-';
                    String lokasi = '-';
                    if (presensiForDate.isNotEmpty) {
                      status = 'Hadir';
                      final datang = presensiForDate.firstWhere(
                        (p) => p.type == 'Presensi Datang',
                        orElse: () => PresensiModel.empty(),
                      );
                      final pulang = presensiForDate.firstWhere(
                        (p) => p.type == 'Presensi Pulang',
                        orElse: () => PresensiModel.empty(),
                      );

                      List<String> lokasiParts = [];
                      if (datang.locationName.isNotEmpty) {
                        lokasiParts.add('Datang: ${datang.locationName}');
                      }
                      if (pulang.locationName.isNotEmpty) {
                        lokasiParts.add('Pulang: ${pulang.locationName}');
                      }
                      lokasi = lokasiParts.join('\n');
                    } else {
                      if (currentDate.weekday == DateTime.saturday ||
                          currentDate.weekday == DateTime.sunday) {
                        status = 'Libur';
                      }
                    }

                    tableData.add({
                      'tanggal': formattedDate,
                      'status': status,
                      'lokasi': lokasi,
                    });

                    currentDate = currentDate.add(const Duration(days: 1));
                  }

                  return ListView.builder(
                    itemCount: tableData.length,
                    itemBuilder: (context, index) {
                      final data = tableData[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: Text(data['tanggal'])),
                            Expanded(flex: 2, child: Text(data['status'])),
                            Expanded(flex: 5, child: Text(data['lokasi'])),
                          ],
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
}
