import 'package:flutter/material.dart';

class ActivityScreen extends StatefulWidget {
  final bool isAdmin;

  const ActivityScreen({super.key, required this.isAdmin});

  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  // Data aktivitas pengguna
  final List<Map<String, dynamic>> _userActivities = [
    {'date': '2023-05-01', 'title': 'Rapat Mingguan', 'time': '09:00 - 11:00'},
    {'date': '2023-05-03', 'title': 'Presentasi Proyek', 'time': '14:00 - 16:00'},
    {'date': '2023-05-10', 'title': 'Pelatihan Pengembangan', 'time': '10:00 - 12:00'},
  ];

  // Data aktivitas seluruh karyawan
  final List<Map<String, dynamic>> _adminActivities = [
    {'employee': 'Karyawan 1', 'date': '2023-05-01', 'title': 'Rapat Mingguan', 'time': '09:00 - 11:00'},
    {'employee': 'Karyawan 2', 'date': '2023-05-03', 'title': 'Presentasi Proyek', 'time': '14:00 - 16:00'},
    {'employee': 'Karyawan 3', 'date': '2023-05-10', 'title': 'Pelatihan Pengembangan', 'time': '10:00 - 12:00'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Aktivitas Karyawan' : 'Aktivitas'),
      ),
      body: widget.isAdmin
          ? _buildAdminActivityList()
          : _buildUserActivityList(),
    );
  }

  Widget _buildUserActivityList() {
    return ListView.builder(
      itemCount: _userActivities.length,
      itemBuilder: (context, index) {
        final activity = _userActivities[index];
        return ListTile(
          title: Text(activity['title']),
          subtitle: Text('${activity['date']} - ${activity['time']}'),
        );
      },
    );
  }

  Widget _buildAdminActivityList() {
    return ListView.builder(
      itemCount: _adminActivities.length,
      itemBuilder: (context, index) {
        final activity = _adminActivities[index];
        return ListTile(
          title: Text('${activity['employee']} - ${activity['title']}'),
          subtitle: Text('${activity['date']} - ${activity['time']}'),
        );
      },
    );
  }
}