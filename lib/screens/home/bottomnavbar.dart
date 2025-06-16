import 'package:flutter/material.dart';
import 'package:iqfence/screens/admin/admin_dashboard_screen.dart';
import 'package:iqfence/screens/admin/karyawan/kelola_karyawan_screen.dart';
import 'package:iqfence/screens/profile/profileScreen.dart';
import 'package:iqfence/screens/user/presensi/presensi_screen.dart';
import 'package:iqfence/screens/user/user_dashboard_screen.dart';

class BottomnavbarScreen extends StatefulWidget {
  final bool isAdmin;

  const BottomnavbarScreen({super.key, this.isAdmin = false});

  @override
  _BottomnavbarScreenState createState() => _BottomnavbarScreenState();
}

class _BottomnavbarScreenState extends State<BottomnavbarScreen> {
  int _currentIndex = 0;

  Widget _getPage(int index) {
    if (widget.isAdmin) {
      switch (index) {
        case 0:
          return const AdminDashboardScreen();
        case 1:
          return const KelolaKaryawanScreen();
        case 2:
          return const ProfileScreen();
        default:
          return const Center(child: Text('Halaman Tidak Ditemukan'));
      }
    } else {
      switch (index) {
        case 0:
          return const UserDashboardScreen();
        case 1:
          return const PresensiScreen();
        case 2:
          return const ProfileScreen();
        default:
          return const Center(child: Text('Halaman Tidak Ditemukan'));
      }
    }
  }

  List<BottomNavigationBarItem> _getNavBarItems() {
    if (widget.isAdmin) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.groups),
          label: 'Karyawan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera_alt),
          label: 'Presensi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getPage(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _getNavBarItems(),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
