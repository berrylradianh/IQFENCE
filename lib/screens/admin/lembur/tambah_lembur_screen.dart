import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TambahLemburScreen extends StatefulWidget {
  const TambahLemburScreen({super.key});

  @override
  State<TambahLemburScreen> createState() => _TambahLemburScreenState();
}

class _TambahLemburScreenState extends State<TambahLemburScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeName;
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _startDateTimeController =
      TextEditingController();
  final TextEditingController _endDateTimeController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _startDateTimeController.dispose();
    _endDateTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartDate) async {
    if (isStartDate) {
      // Select Date for Start Date
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2026),
      );

      if (pickedDate != null) {
        // Select Time for Start Date
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );

        if (pickedTime != null) {
          setState(() {
            final newDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            _startDateTime = newDateTime;
            _startDateTimeController.text =
                DateFormat('dd MMM yyyy HH:mm').format(newDateTime);
          });
        }
      }
    } else {
      // For End Date, use the same date as Start Date if available
      if (_startDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih tanggal mulai terlebih dahulu')),
        );
        return;
      }

      // Select Time for End Date (same date as Start Date)
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          final newDateTime = DateTime(
            _startDateTime!.year,
            _startDateTime!.month,
            _startDateTime!.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _endDateTime = newDateTime;
          _endDateTimeController.text =
              DateFormat('dd MMM yyyy HH:mm').format(newDateTime);
        });
      }
    }
  }

  Future<void> _saveLembur() async {
    if (_formKey.currentState!.validate() &&
        _selectedEmployeeName != null &&
        _startDateTime != null &&
        _endDateTime != null) {
      _formKey.currentState!.save();

      try {
        // Fetch the document ID based on the selected nama
        final userQuery = await FirebaseFirestore.instance
            .collection('karyawan')
            .where('nama', isEqualTo: _selectedEmployeeName)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Karyawan dengan nama tersebut tidak ditemukan')),
          );
          return;
        }

        final userDoc = userQuery.docs.first;
        final userData = userDoc.data();
        final userId = userDoc.id;

        // Create a new document in the 'lembur' collection with userId
        await FirebaseFirestore.instance.collection('lembur').add({
          'userId': userId,
          'userData': userData,
          'statusLembur': 'Aktif',
          'lemburStartDate': _startDateTime!.toIso8601String(),
          'lemburEndDate': _endDateTime!.toIso8601String(),
          'lemburReason': _reasonController.text,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lembur berhasil ditambahkan')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Lembur Karyawan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tambah Lembur Baru',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('karyawan')
                      .where('posisi', isEqualTo: 'Karyawan')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text('Tidak ada karyawan tersedia');
                    }

                    final employees = snapshot.data!.docs;

                    return DropdownButtonFormField<String>(
                      value: _selectedEmployeeName,
                      hint: const Text('Pilih Nama Karyawan'),
                      items: employees.map<DropdownMenuItem<String>>((doc) {
                        final user = doc.data() as Map<String, dynamic>;
                        final nama = user['nama'] ?? 'No nama';
                        return DropdownMenuItem<String>(
                          value: nama,
                          child: Text(nama),
                        );
                      }).toList(),
                      validator: (value) =>
                          value == null ? 'Pilih nama karyawan' : null,
                      onChanged: (value) {
                        setState(() {
                          _selectedEmployeeName = value;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Tanggal dan Jam Mulai',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  readOnly: true,
                  controller: _startDateTimeController,
                  onTap: () => _selectDateTime(context, true),
                  validator: (value) => _startDateTime == null
                      ? 'Pilih tanggal dan jam mulai'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Tanggal dan Jam Selesai',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  readOnly: true,
                  controller: _endDateTimeController,
                  onTap: () => _selectDateTime(context, false),
                  validator: (value) =>
                      _endDateTime == null ? 'Pilih jam selesai' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Alasan Lembur',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Masukkan alasan lembur' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveLembur,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Simpan Lembur'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
