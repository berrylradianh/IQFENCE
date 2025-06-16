import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import untuk inisialisasi locale
import 'package:intl/intl.dart';
import 'package:iqfence/providers/Auth.dart';
import 'package:iqfence/screens/user/izin/izin_screen.dart';
import 'package:iqfence/screens/user/lembur/lembur_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  String? _currentDay;
  String? _formattedDate;
  String? _jamKerja;
  bool _isLibur = false;

  @override
  void initState() {
    super.initState();
    _initializeAndFetchData();
  }

  Future<void> _initializeAndFetchData() async {
    // Inisialisasi data locale untuk 'id_ID'
    await initializeDateFormatting('id_ID');
    // Panggil fetch data setelah inisialisasi selesai
    await _fetchJamKerja();
  }

  Future<void> _fetchJamKerja() async {
    final auth = Provider.of<Auth>(context, listen: false);
    final userId = auth.user.uid;

    // Format hari dan tanggal saat ini
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
    final dayFormatter = DateFormat('EEEE', 'id_ID');
    setState(() {
      _formattedDate = formatter.format(now);
      _currentDay = dayFormatter.format(now);
    });

    print('Current Day: $_currentDay');
    print('User ID: $userId');

    try {
      // Ambil karyawan_id dari koleksi users
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      print('User Doc Exists: ${userDoc.exists}');
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String? karyawanId = userData['karyawan_id'];
        print('Karyawan ID: $karyawanId');

        if (karyawanId != null) {
          DocumentSnapshot karyawanDoc = await FirebaseFirestore.instance
              .collection('karyawan')
              .doc(karyawanId)
              .get();

          print('Karyawan Doc Exists: ${karyawanDoc.exists}');
          if (karyawanDoc.exists && karyawanDoc.data() != null) {
            Map<String, dynamic> karyawanData =
                karyawanDoc.data() as Map<String, dynamic>;
            Map<String, dynamic> jamKerja = karyawanData['jam_kerja'] ?? {};
            print('Jam Kerja: $jamKerja');

            if (jamKerja[_currentDay] != null) {
              final hariData = jamKerja[_currentDay];
              print('Hari Data ($_currentDay): $hariData');
              setState(() {
                _isLibur = hariData['libur'] ?? false;
                if (!_isLibur && hariData['jam_mulai'] != '-') {
                  _jamKerja =
                      "${hariData['jam_mulai']} - ${hariData['jam_selesai']}";
                } else {
                  _jamKerja = "Hari Libur";
                }
              });
            } else {
              setState(() {
                _jamKerja = "Data jam kerja tidak tersedia";
              });
            }
          } else {
            setState(() {
              _jamKerja = "Data karyawan tidak ditemukan";
            });
          }
        } else {
          setState(() {
            _jamKerja = "Karyawan ID tidak ditemukan";
          });
        }
      } else {
        setState(() {
          _jamKerja = "Data pengguna tidak ditemukan";
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _jamKerja = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_jamKerja == null || _formattedDate == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.home, color: Colors.white),
            ),
            SizedBox(width: 8),
            Text(
              'IQFace',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'User',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Kotak Jam Kerja
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[700],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Jam Kerja",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                      Text(_formattedDate!,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _jamKerja!,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLibur
                        ? "Nikmati hari libur Anda"
                        : "Selamat beraktivitas",
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Menu Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
                children: [
                  _DashboardMenuItem(
                    icon: LucideIcons.fileClock,
                    title: "Izin",
                    color: Colors.amber[700]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const IzinScreen()),
                      );
                    },
                  ),
                  _DashboardMenuItem(
                    icon: LucideIcons.listTodo,
                    title: "Aktivitas",
                    color: Colors.amber[700]!,
                    onTap: () {},
                  ),
                  _DashboardMenuItem(
                    icon: LucideIcons.clock4,
                    title: "Riwayat",
                    color: Colors.amber[700]!,
                    onTap: () {},
                  ),
                  _DashboardMenuItem(
                    icon: LucideIcons.calendarClock,
                    title: "Lembur",
                    color: Colors.amber[700]!,
                    showNotification: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LemburScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final bool showNotification;

  const _DashboardMenuItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.showNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 36, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(title, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
            if (showNotification)
              const Positioned(
                top: 8,
                right: 12,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.red,
                  child: Text("!",
                      style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
