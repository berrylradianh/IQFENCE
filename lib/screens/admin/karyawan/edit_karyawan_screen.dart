import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class EditKaryawanScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> karyawanData;

  const EditKaryawanScreen({
    super.key,
    required this.docId,
    required this.karyawanData,
  });

  @override
  State<EditKaryawanScreen> createState() => _EditKaryawanScreenState();
}

class _EditKaryawanScreenState extends State<EditKaryawanScreen> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  File? _selectedImage;
  String? _imagePath;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Inisialisasi field dengan data karyawan yang ada
    _namaController.text = widget.karyawanData['nama'] ?? '';
    _alamatController.text = widget.karyawanData['alamat'] ?? '';
    _imagePath = widget.karyawanData['foto'];
    if (_imagePath != null) {
      // Muat gambar dari direktori dokumen aplikasi jika ada
      _loadExistingImage();
    }
  }

  Future<void> _loadExistingImage() async {
    final appDir = await getApplicationDocumentsDirectory();
    final fullPath = '${appDir.path}/$_imagePath';
    if (File(fullPath).existsSync()) {
      setState(() {
        _selectedImage = File(fullPath);
      });
    }
  }

  Future<bool> _requestGalleryPermission() async {
    final status = await Permission.photos.request();
    if (status.isGranted) {
      return true;
    } else if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) {
        return true;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Izin galeri diperlukan untuk memilih gambar')),
    );
    return false;
  }

  Future<void> _pickImage() async {
    try {
      final hasPermission = await _requestGalleryPermission();
      if (!hasPermission) return;

      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        // Mendapatkan direktori dokumen aplikasi
        final appDir = await getApplicationDocumentsDirectory();
        final karyawanDir = Directory('${appDir.path}/karyawan');

        // Membuat folder karyawan jika belum ada
        if (!await karyawanDir.exists()) {
          await karyawanDir.create(recursive: true);
        }

        // Membuat nama file unik
        final fileName =
            'karyawan_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage =
            await _selectedImage!.copy('${karyawanDir.path}/$fileName');

        setState(() {
          // Simpan path relatif untuk Firestore
          _imagePath = 'karyawan/$fileName';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gambar disimpan di: ${savedImage.path}. '
              'Silakan salin file ke folder proyek assets/karyawan/ '
              'dan pastikan assets/karyawan/ dideklarasikan di pubspec.yaml',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error memilih gambar: $e')),
      );
    }
  }

  Future<void> _updateKaryawan() async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    final nama = _namaController.text.trim();
    final alamat = _alamatController.text.trim();

    if (nama.isEmpty || alamat.isEmpty || _imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('karyawan')
          .doc(widget.docId)
          .update({
        'nama': nama,
        'alamat': alamat,
        'foto': _imagePath,
        'posisi': widget.karyawanData['posisi'] ?? 'Karyawan',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Karyawan berhasil diperbarui')),
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
        title: const Text('Edit Karyawan'),
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
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: 'Nama',
                  hintText: 'Masukkan nama karyawan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _alamatController,
                decoration: InputDecoration(
                  labelText: 'Alamat',
                  hintText: 'Masukkan alamat karyawan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        )
                      : _imagePath != null
                          ? Image.asset(
                              'assets/$_imagePath',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.add_a_photo,
                                      size: 40, color: Colors.grey),
                            )
                          : const Icon(Icons.add_a_photo,
                              size: 40, color: Colors.grey),
                ),
              ),
              if (_selectedImage != null || _imagePath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Gambar dipilih: ${_imagePath?.split('/').last}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateKaryawan,
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
    _namaController.dispose();
    _alamatController.dispose();
    super.dispose();
  }
}
