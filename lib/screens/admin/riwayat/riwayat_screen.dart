import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:iqfence/models/userModel.dart';
import 'package:iqfence/screens/admin/riwayat/presensi_result_screen.dart';
import 'package:iqfence/service/firestore_service.dart';
import 'package:iqfence/utils/date_utils.dart' as CustomDateUtils;

class AdminRiwayatScreen extends StatefulWidget {
  const AdminRiwayatScreen({super.key});

  @override
  State<AdminRiwayatScreen> createState() => _AdminRiwayatScreenState();
}

class _AdminRiwayatScreenState extends State<AdminRiwayatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  List<UserModel> _users = [];
  UserModel? _selectedUser;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID');
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await _firestoreService.getAllUsers();
      print('AdminRiwayatScreen fetched users: ${users.map((u) => {
            'id': u.id,
            'displayName': u.displayName
          }).toList()}');
      setState(() {
        _users = users;
      });
    } catch (e) {
      print('Error in _fetchUsers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e')),
      );
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      locale: const Locale('id', 'ID'),
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _onSubmit() {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih karyawan terlebih dahulu')),
      );
      return;
    }
    if (_selectedUser!.id == null) {
      print('Error: Selected user has null ID: $_selectedUser');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: ID karyawan tidak tersedia')),
      );
      return;
    }
    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih rentang tanggal terlebih dahulu')),
      );
      return;
    }
    print(
        'Navigating to PresensiResultScreen with user ID: ${_selectedUser!.id}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresensiResultScreen(
          user: _selectedUser!,
          dateRange: _selectedDateRange!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Riwayat Presensi',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Karyawan
            Autocomplete<UserModel>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<UserModel>.empty();
                }
                return _users.where((user) {
                  return (user.displayName ?? '')
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                });
              },
              displayStringForOption: (UserModel user) =>
                  user.displayName ?? 'Unknown',
              onSelected: (UserModel user) {
                print(
                    'Selected user: {id: ${user.id}, displayName: ${user.displayName}}');
                setState(() {
                  _selectedUser = user;
                  _searchController.text = user.displayName ?? '';
                });
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Cari Nama Karyawan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Date Range Picker
            InkWell(
              onTap: () => _selectDateRange(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Rentang Tanggal',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _selectedDateRange == null
                      ? 'Pilih rentang tanggal'
                      : '${CustomDateUtils.DateUtils.formatDate(_selectedDateRange!.start, format: 'd MMM yyyy')} - '
                          '${CustomDateUtils.DateUtils.formatDate(_selectedDateRange!.end, format: 'd MMM yyyy')}',
                  style: TextStyle(
                    color:
                        _selectedDateRange == null ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
