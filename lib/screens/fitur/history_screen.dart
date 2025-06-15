import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  final bool isAdmin;

  const HistoryScreen({super.key, required this.isAdmin});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Data riwayat pengguna
  final List<Map<String, dynamic>> _userHistory = [
    {'date': '2023-05-01', 'type': 'Hadir', 'duration': '8 jam'},
    {'date': '2023-05-02', 'type': 'Izin', 'duration': '1 hari'},
    {'date': '2023-05-15', 'type': 'Lembur', 'duration': '2 jam'},
  ];

  // Data riwayat seluruh karyawan
  final List<Map<String, dynamic>> _adminHistory = [
    {'employee': 'Karyawan 1', 'date': '2023-05-01', 'type': 'Hadir', 'duration': '8 jam'},
    {'employee': 'Karyawan 2', 'date': '2023-05-02', 'type': 'Izin', 'duration': '1 hari'},
    {'employee': 'Karyawan 3', 'date': '2023-05-15', 'type': 'Lembur', 'duration': '2 jam'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Riwayat Karyawan' : 'Riwayat'),
        actions: widget.isAdmin
            ? [
                IconButton(
                  onPressed: _downloadHistory,
                  icon: const Icon(Icons.download),
                ),
              ]
            : [],
      ),
      body: widget.isAdmin
          ? _buildAdminHistoryList()
          : _buildUserHistoryList(),
    );
  }

  Widget _buildUserHistoryList() {
    return ListView.builder(
      itemCount: _userHistory.length,
      itemBuilder: (context, index) {
        final record = _userHistory[index];
        return ListTile(
          title: Text('${record['type']}'),
          subtitle: Text('${record['date']} - ${record['duration']}'),
        );
      },
    );
  }

  Widget _buildAdminHistoryList() {
    return ListView.builder(
      itemCount: _adminHistory.length,
      itemBuilder: (context, index) {
        final record = _adminHistory[index];
        return ListTile(
          title: Text('${record['employee']} - ${record['type']}'),
          subtitle: Text('${record['date']} - ${record['duration']}'),
        );
      },
    );
  }

  void _downloadHistory() {
    // Logika untuk mengunduh riwayat dalam format PDF atau Excel
  }
}