import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TambahIzinScreen extends StatefulWidget {
  const TambahIzinScreen({super.key});

  @override
  State<TambahIzinScreen> createState() => _TambahIzinScreenState();
}

class _TambahIzinScreenState extends State<TambahIzinScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeName; // Changed to store nama instead of email
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveIzin() async {
    if (_formKey.currentState!.validate() &&
        _selectedEmployeeName != null &&
        _startDate != null &&
        _endDate != null) {
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
                content: Text('Karyawan dengan ID tersebut tidak ditemukan')),
          );
          return;
        }

        final userDoc = userQuery.docs.first;
        final userData = userDoc.data();
        final userId =
            userDoc.id; // Use the document ID (e.g., "Wz8aRJcSdJLKPpXxKPhJ")

        // Create a new document in the 'izin' collection with userId
        await FirebaseFirestore.instance.collection('izin').add({
          'userId': userId, // Use document ID as identifier
          'userData': userData, // Store full user data
          'statusIzin': 'Aktif',
          'izinStartDate': _startDate!.toIso8601String(),
          'izinEndDate': _endDate!.toIso8601String(),
          'izinReason': _reasonController.text,
          'createdAt': FieldValue.serverTimestamp(), // Optional: Add timestamp
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin berhasil ditambahkan')),
        );
        Navigator.pop(context); // Return to previous screen
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
        title: const Text('Tambah Izin Karyawan'),
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
                  'Tambah Izin Baru',
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
                    labelText: 'Tanggal Mulai',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  readOnly: true,
                  controller: TextEditingController(
                    text: _startDate != null
                        ? _startDate!.toLocal().toString().split(' ')[0]
                        : '',
                  ),
                  onTap: () => _selectDate(context, true),
                  validator: (value) =>
                      _startDate == null ? 'Pilih tanggal mulai' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Tanggal Selesai',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  readOnly: true,
                  controller: TextEditingController(
                    text: _endDate != null
                        ? _endDate!.toLocal().toString().split(' ')[0]
                        : '',
                  ),
                  onTap: () => _selectDate(context, false),
                  validator: (value) =>
                      _endDate == null ? 'Pilih tanggal selesai' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Alasan Izin',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Masukkan alasan izin' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveIzin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Simpan Izin'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
