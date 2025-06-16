import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iqfence/providers/Auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

class LemburScreen extends StatefulWidget {
  const LemburScreen({super.key});

  @override
  State<LemburScreen> createState() => _LemburScreenState();
}

class _LemburScreenState extends State<LemburScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _lemburDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _jenisLembur;
  final _alasanController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _selectLemburDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _lemburDate) {
      setState(() {
        _lemburDate = picked;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _submitLembur() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final auth = Provider.of<Auth>(context, listen: false);
    final userId = auth.user.uid;

    try {
      // Ambil data pengguna dari koleksi users untuk mendapatkan karyawan_id dan userData
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data pengguna tidak ditemukan')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? karyawanId = userData['karyawan_id'];

      if (karyawanId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Karyawan ID tidak ditemukan')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Ambil data karyawan untuk userData
      DocumentSnapshot karyawanDoc = await FirebaseFirestore.instance
          .collection('karyawan')
          .doc(karyawanId)
          .get();

      if (!karyawanDoc.exists || karyawanDoc.data() == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data karyawan tidak ditemukan')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic> karyawanData =
          karyawanDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> userDataForLembur = {
        'nama': karyawanData['nama'] ?? '',
        'posisi': karyawanData['posisi'] ?? '',
        'alamat': karyawanData['alamat'] ?? '',
        'foto': karyawanData['foto'] ?? '',
      };

      // Gabungkan tanggal dan jam untuk lemburStartDate dan lemburEndDate
      final startDateTime = DateTime(
        _lemburDate!.year,
        _lemburDate!.month,
        _lemburDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      final endDateTime = DateTime(
        _lemburDate!.year,
        _lemburDate!.month,
        _lemburDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      // Simpan data lembur ke Firestore
      await FirebaseFirestore.instance.collection('lembur').add({
        'createdAt': Timestamp.now(),
        'lemburStartDate': startDateTime.toIso8601String(),
        'lemburEndDate': endDateTime.toIso8601String(),
        'lemburType':
            _jenisLembur, // Menambahkan jenis lembur sebagai lemburType
        'lemburReason': _alasanController.text,
        'statusLembur': 'Menunggu', // Status awal
        'userData': userDataForLembur,
        'userId': userId,
        'karyawan_id': karyawanId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan lembur berhasil dikirim')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lembur',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                // Field Tanggal Lembur
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Tanggal Lembur',
                    suffixIcon: const Icon(LucideIcons.calendar),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  controller: TextEditingController(
                    text: _lemburDate == null
                        ? ''
                        : DateFormat('dd MMMM yyyy', 'id_ID')
                            .format(_lemburDate!),
                  ),
                  onTap: () => _selectLemburDate(context),
                  validator: (value) =>
                      _lemburDate == null ? 'Pilih tanggal lembur' : null,
                ),
                const SizedBox(height: 16),

                // Field Jam Mulai
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Jam Mulai',
                    suffixIcon: const Icon(LucideIcons.clock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  controller: TextEditingController(
                    text: _startTime == null ? '' : _startTime!.format(context),
                  ),
                  onTap: () => _selectStartTime(context),
                  validator: (value) =>
                      _startTime == null ? 'Pilih jam mulai' : null,
                ),
                const SizedBox(height: 16),

                // Field Jam Selesai
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Jam Selesai',
                    suffixIcon: const Icon(LucideIcons.clock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  controller: TextEditingController(
                    text: _endTime == null ? '' : _endTime!.format(context),
                  ),
                  onTap: () => _selectEndTime(context),
                  validator: (value) =>
                      _endTime == null ? 'Pilih jam selesai' : null,
                ),
                const SizedBox(height: 16),

                // Field Jenis Lembur
                DropdownButtonFormField<String>(
                  value: _jenisLembur,
                  decoration: InputDecoration(
                    labelText: 'Jenis Lembur',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['Proyek Khusus', 'Tugas Tambahan', 'Lainnya']
                      .map((String jenis) => DropdownMenuItem<String>(
                            value: jenis,
                            child: Text(jenis),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _jenisLembur = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Pilih jenis lembur' : null,
                ),
                const SizedBox(height: 16),

                // Field Alasan
                TextFormField(
                  controller: _alasanController,
                  decoration: InputDecoration(
                    labelText: 'Alasan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 4,
                  validator: (value) =>
                      value!.isEmpty ? 'Masukkan alasan' : null,
                ),
                const SizedBox(height: 24),

                // Tombol Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitLembur,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Submit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                // Tambahkan padding bawah untuk memastikan tombol Submit terlihat saat keyboard muncul
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
