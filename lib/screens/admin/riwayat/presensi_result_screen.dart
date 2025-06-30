import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:iqfence/models/presensi_model.dart';
import 'package:iqfence/models/userModel.dart';
import 'package:iqfence/service/firestore_service.dart';
import 'package:iqfence/utils/date_utils.dart' as CustomDateUtils;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

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
  String? _selectedExportFormat = 'PDF'; // Default export format

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

  // Function to export to PDF
  Future<void> _exportToPDF(List<Map<String, dynamic>> tableData) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Hasil Riwayat Presensi - ${widget.user.displayName ?? 'Unknown'}',
            ),
          ),
          pw.Text(
            'Periode: ${CustomDateUtils.DateUtils.formatDate(widget.dateRange.start, format: 'd MMM yyyy')} - '
            '${CustomDateUtils.DateUtils.formatDate(widget.dateRange.end, format: 'd MMM yyyy')}',
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Tanggal', 'Status', 'Lokasi'],
            data: tableData
                .map(
                    (data) => [data['tanggal'], data['status'], data['lokasi']])
                .toList(),
          ),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final fileName =
        'Presensi_${widget.user.displayName?.replaceAll(' ', '_') ?? 'Unknown'}_${CustomDateUtils.DateUtils.formatDate(widget.dateRange.start, format: 'd_MMM_yyyy')}_to_${CustomDateUtils.DateUtils.formatDate(widget.dateRange.end, format: 'd_MMM_yyyy')}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    if (!kIsWeb) {
      await OpenFile.open(file.path);
    } else {
      // Handle web export (e.g., download the file)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF generated, please check downloads')),
      );
    }
  }

  // Function to export to Excel
  Future<void> _exportToExcel(List<Map<String, dynamic>> tableData) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    // Add headers
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Tanggal');
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Status');
    sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Lokasi');

    // Add data
    for (var i = 0; i < tableData.length; i++) {
      sheet.cell(CellIndex.indexByString('A${i + 2}')).value =
          TextCellValue(tableData[i]['tanggal']);
      sheet.cell(CellIndex.indexByString('B${i + 2}')).value =
          TextCellValue(tableData[i]['status']);
      sheet.cell(CellIndex.indexByString('C${i + 2}')).value =
          TextCellValue(tableData[i]['lokasi']);
    }

    final directory = await getTemporaryDirectory();
    final fileName =
        'Presensi_${widget.user.displayName?.replaceAll(' ', '_') ?? 'Unknown'}_${CustomDateUtils.DateUtils.formatDate(widget.dateRange.start, format: 'd_MMM_yyyy')}_to_${CustomDateUtils.DateUtils.formatDate(widget.dateRange.end, format: 'd_MMM_yyyy')}.xlsx';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(excel.encode()!);

    if (!kIsWeb) {
      await OpenFile.open(file.path);
    } else {
      // Handle web export
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Excel generated, please check downloads')),
      );
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
            const SizedBox(height: 8),
            // Export format selection and button
            Row(
              children: [
                DropdownButton<String>(
                  value: _selectedExportFormat,
                  items: <String>['PDF', 'Excel']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedExportFormat = newValue;
                    });
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.file_download, color: Colors.black),
                  onPressed: () async {
                    // Fetch tableData for export
                    final snapshot = await _firestoreService
                        .getPresensiStream(userId: widget.user.id!)
                        .first;
                    final presensiList = snapshot.where((presensi) {
                      final date = CustomDateUtils.DateUtils.parseDate(
                          presensi.tanggalPresensi);
                      if (date == null) return false;
                      return date.isAfter(widget.dateRange.start
                              .subtract(const Duration(days: 1))) &&
                          date.isBefore(widget.dateRange.end
                              .add(const Duration(days: 1)));
                    }).toList();

                    final List<Map<String, dynamic>> tableData = [];
                    var currentDate = widget.dateRange.start;
                    while (currentDate.isBefore(
                        widget.dateRange.end.add(const Duration(days: 1)))) {
                      final formattedDate =
                          CustomDateUtils.DateUtils.formatDate(currentDate,
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

                    // Export based on selected format
                    if (_selectedExportFormat == 'PDF') {
                      await _exportToPDF(tableData);
                    } else if (_selectedExportFormat == 'Excel') {
                      await _exportToExcel(tableData);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

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
