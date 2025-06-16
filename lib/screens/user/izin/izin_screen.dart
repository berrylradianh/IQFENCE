import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iqfence/providers/Auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

class IzinScreen extends StatefulWidget {
  const IzinScreen({super.key});

  @override
  State<IzinScreen> createState() => _IzinScreenState();
}

class _IzinScreenState extends State<IzinScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _jenisIzin;
  final _alasanController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Reset endDate jika lebih awal dari startDate
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _submitIzin() async {
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
      Map<String, dynamic> userDataForIzin = {
        'nama': karyawanData['nama'] ?? '',
        'posisi': karyawanData['posisi'] ?? '',
        'alamat': karyawanData['alamat'] ?? '',
        'foto': karyawanData['foto'] ?? '',
      };

      // Simpan data izin ke Firestore
      await FirebaseFirestore.instance.collection('izin').add({
        'createdAt': Timestamp.now(),
        'izinStartDate': _startDate!.toIso8601String(),
        'izinEndDate': _endDate!.toIso8601String(),
        'izinType': _jenisIzin, // Menambahkan jenis izin sebagai izinType
        'izinReason': _alasanController.text,
        'statusIzin': 'Menunggu', // Status awal
        'userData': userDataForIzin,
        'userId': userId,
        'karyawan_id': karyawanId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan izin berhasil dikirim')),
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
          'Izin',
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
                // Field Tanggal Mulai
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Tanggal Mulai',
                    suffixIcon: const Icon(LucideIcons.calendar),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  controller: TextEditingController(
                    text: _startDate == null
                        ? ''
                        : DateFormat('dd MMMM yyyy', 'id_ID')
                            .format(_startDate!),
                  ),
                  onTap: () => _selectStartDate(context),
                  validator: (value) =>
                      _startDate == null ? 'Pilih tanggal mulai' : null,
                ),
                const SizedBox(height: 16),

                // Field Tanggal Berakhir
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Tanggal Berakhir',
                    suffixIcon: const Icon(LucideIcons.calendar),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  controller: TextEditingController(
                    text: _endDate == null
                        ? ''
                        : DateFormat('dd MMMM yyyy', 'id_ID').format(_endDate!),
                  ),
                  onTap: () => _selectEndDate(context),
                  validator: (value) =>
                      _endDate == null ? 'Pilih tanggal berakhir' : null,
                ),
                const SizedBox(height: 16),

                // Field Jenis Izin
                DropdownButtonFormField<String>(
                  value: _jenisIzin,
                  decoration: InputDecoration(
                    labelText: 'Jenis Izin',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['Sakit', 'Cuti', 'Lainnya']
                      .map((String jenis) => DropdownMenuItem<String>(
                            value: jenis,
                            child: Text(jenis),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _jenisIzin = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Pilih jenis izin' : null,
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
                    onPressed: _isLoading ? null : _submitIzin,
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
