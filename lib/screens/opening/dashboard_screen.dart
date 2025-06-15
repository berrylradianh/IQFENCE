import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final bool isAdmin;

  const DashboardScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE4E1),
        elevation: 0,
        title: Text(isAdmin ? 'Dashboard Admin' : 'Dashboard Karyawan'),
        centerTitle: true,
      ),
      body: isAdmin ? _buildAdminDashboard() : _buildUserDashboard(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'Presensi'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildUserDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _workScheduleCard(),
          const SizedBox(height: 20),
          _rekapCard(),
          const SizedBox(height: 20),
          _menuGrid([
            {'icon': Icons.assignment_late, 'label': 'Izin'},
            {'icon': Icons.access_time, 'label': 'Aktivitas'},
            {'icon': Icons.history, 'label': 'Riwayat'},
            {'icon': Icons.warning, 'label': 'Lembur'},
          ]),
        ],
      ),
    );
  }

  Widget _buildAdminDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            color: Colors.amber,
            child: ListTile(
              title: const Text("Data Presensi Karyawan", style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.people),
              onTap: () {
                // Aksi untuk lihat data presensi
              },
            ),
          ),
          const SizedBox(height: 20),
          _menuGrid([
            {'icon': Icons.map, 'label': 'Atur Lokasi'},
            {'icon': Icons.manage_accounts, 'label': 'Kelola Karyawan'},
            {'icon': Icons.settings, 'label': 'Pengaturan'},
            {'icon': Icons.analytics, 'label': 'Laporan'},
          ]),
        ],
      ),
    );
  }

  Widget _workScheduleCard() {
    return const Card(
      color: Colors.amber,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Jam Kerja", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("08.00 - 16.00", style: TextStyle(fontSize: 24)),
            SizedBox(height: 4),
            Text("Sen, 11 Januari 2024"),
            SizedBox(height: 8),
            Text("Terima kasih sudah mengisi kehadiran, selamat beraktivitas"),
          ],
        ),
      ),
    );
  }

  Widget _rekapCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Rekap Presensi Bulan Ini", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [Text("Hadir"), Text("23 Hari")]),
                Column(children: [Text("Izin"), Text("3 Hari")]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuGrid(List<Map<String, dynamic>> items) {
    return Expanded(
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 3 / 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: items.map((item) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {},
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item['icon'], size: 30, color: Colors.white),
                const SizedBox(height: 10),
                Text(item['label'], style: const TextStyle(color: Colors.white)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
