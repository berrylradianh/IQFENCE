import 'package:flutter/material.dart';

class OvertimeScreen extends StatefulWidget {
  final bool isAdmin;

  const OvertimeScreen({super.key, required this.isAdmin});

  @override
  _OvertimeScreenState createState() => _OvertimeScreenState();
}

class _OvertimeScreenState extends State<OvertimeScreen> {
  // Data lembur pengguna
  final List<Map<String, dynamic>> _userOvertimes = [
    {'date': '2023-05-10', 'duration': '2 jam', 'status': 'Disetujui'},
    {'date': '2023-06-05', 'duration': '3 jam', 'status': 'Menunggu'},
    {'date': '2023-07-15', 'duration': '1.5 jam', 'status': 'Ditolak'},
  ];

  // Data lembur seluruh karyawan
  final List<Map<String, dynamic>> _adminOvertimes = [
    {'employee': 'Karyawan 1', 'date': '2023-05-10', 'duration': '2 jam', 'status': 'Disetujui'},
    {'employee': 'Karyawan 2', 'date': '2023-06-05', 'duration': '3 jam', 'status': 'Menunggu'},
    {'employee': 'Karyawan 3', 'date': '2023-07-15', 'duration': '1.5 jam', 'status': 'Ditolak'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Lembur Karyawan' : 'Lembur'),
      ),
      body: widget.isAdmin
          ? _buildAdminOvertimeList()
          : _buildUserOvertimeList(),
      floatingActionButton: !widget.isAdmin
          ? FloatingActionButton(
              onPressed: _showOvertimeRequestDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildUserOvertimeList() {
    return ListView.builder(
      itemCount: _userOvertimes.length,
      itemBuilder: (context, index) {
        final overtime = _userOvertimes[index];
        return ListTile(
          title: Text('Lembur ${overtime['duration']}'),
          subtitle: Text('${overtime['date']} - Status: ${overtime['status']}'),
        );
      },
    );
  }

  Widget _buildAdminOvertimeList() {
    return ListView.builder(
      itemCount: _adminOvertimes.length,
      itemBuilder: (context, index) {
        final overtime = _adminOvertimes[index];
        return ListTile(
          title: Text('${overtime['employee']} - Lembur ${overtime['duration']}'),
          subtitle: Text('${overtime['date']} - Status: ${overtime['status']}'),
          trailing: widget.isAdmin
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _approveOvertime(overtime),
                      icon: const Icon(Icons.check),
                    ),
                    IconButton(
                      onPressed: () => _rejectOvertime(overtime),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  void _showOvertimeRequestDialog() {
    // Tampilkan dialog untuk mengajukan permohonan lembur
  }

  void _approveOvertime(Map<String, dynamic> overtime) {
    // Logika untuk menyetujui permohonan lembur
  }

  void _rejectOvertime(Map<String, dynamic> overtime) {
    // Logika untuk menolak permohonan lembur
  }
}