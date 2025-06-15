import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditLokasiScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> lokasiData;

  const EditLokasiScreen({
    super.key,
    required this.docId,
    required this.lokasiData,
  });

  @override
  State<EditLokasiScreen> createState() => _EditLokasiScreenState();
}

class _EditLokasiScreenState extends State<EditLokasiScreen> {
  final TextEditingController _namaLokasiController = TextEditingController();
  final TextEditingController _koordinatController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi field dengan data lokasi yang ada
    _namaLokasiController.text = widget.lokasiData['namaLokasi'] ?? '';
    _koordinatController.text = widget.lokasiData['koordinat'] ?? '';
  }

  Future<void> _updateLokasi() async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    final namaLokasi = _namaLokasiController.text.trim();
    final koordinat = _koordinatController.text.trim();

    if (namaLokasi.isEmpty || koordinat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    // Validasi format koordinat (sederhana: latitude, longitude)
    final coords = koordinat.split(',');
    if (coords.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Format koordinat salah, gunakan: latitude, longitude')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('locations')
          .doc(widget.docId)
          .update({
        'namaLokasi': namaLokasi,
        'koordinat': koordinat,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi berhasil diperbarui')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Lokasi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _namaLokasiController,
                decoration: InputDecoration(
                  labelText: 'Nama Lokasi',
                  hintText: 'Masukkan nama lokasi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _koordinatController,
                enabled: false, // Membuat field ini tidak bisa diedit
                decoration: InputDecoration(
                  labelText: 'Koordinat',
                  hintText: 'Koordinat tidak dapat diubah',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateLokasi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Simpan', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaLokasiController.dispose();
    _koordinatController.dispose();
    super.dispose();
  }
}
