import 'package:flutter/material.dart';

class LeaveScreen extends StatefulWidget {
  final bool isAdmin;

  const LeaveScreen({super.key, required this.isAdmin});

  @override
  _LeaveScreenState createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  // Data izin pengguna
  final List<Map<String, dynamic>> _userLeaves = [
    {'date': '2023-05-15', 'type': 'Cuti', 'status': 'Disetujui'},
    {'date': '2023-06-01', 'type': 'Sakit', 'status': 'Menunggu'},
    {'date': '2023-07-20', 'type': 'Keperluan', 'status': 'Ditolak'},
  ];

  // Data izin seluruh karyawan
  final List<Map<String, dynamic>> _adminLeaves = [
    {'employee': 'Karyawan 1', 'date': '2023-05-15', 'type': 'Cuti', 'status': 'Disetujui'},
    {'employee': 'Karyawan 2', 'date': '2023-06-01', 'type': 'Sakit', 'status': 'Menunggu'},
    {'employee': 'Karyawan 3', 'date': '2023-07-20', 'type': 'Keperluan', 'status': 'Ditolak'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Izin Karyawan' : 'Izin'),
      ),
      body: widget.isAdmin
          ? _buildAdminLeaveList()
          : _buildUserLeaveList(),
      floatingActionButton: !widget.isAdmin
          ? FloatingActionButton(
              onPressed: _showLeaveRequestDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildUserLeaveList() {
    return ListView.builder(
      itemCount: _userLeaves.length,
      itemBuilder: (context, index) {
        final leave = _userLeaves[index];
        return ListTile(
          title: Text(leave['type']),
          subtitle: Text('${leave['date']} - Status: ${leave['status']}'),
        );
      },
    );
  }

  Widget _buildAdminLeaveList() {
    return ListView.builder(
      itemCount: _adminLeaves.length,
      itemBuilder: (context, index) {
        final leave = _adminLeaves[index];
        return ListTile(
          title: Text('${leave['employee']} - ${leave['type']}'),
          subtitle: Text('${leave['date']} - Status: ${leave['status']}'),
          trailing: widget.isAdmin
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _approveLeave(leave),
                      icon: const Icon(Icons.check),
                    ),
                    IconButton(
                      onPressed: () => _rejectLeave(leave),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  void _showLeaveRequestDialog() {
    // Tampilkan dialog untuk mengajukan permohonan izin
  }

  void _approveLeave(Map<String, dynamic> leave) {
    // Logika untuk menyetujui permohonan izin
  }

  void _rejectLeave(Map<String, dynamic> leave) {
    // Logika untuk menolak permohonan izin
  }
}