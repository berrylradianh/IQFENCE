import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iqfence/config/drive_config.dart';
import 'package:permission_handler/permission_handler.dart';

class TambahKaryawanScreen extends StatefulWidget {
  const TambahKaryawanScreen({super.key});

  @override
  State<TambahKaryawanScreen> createState() => _TambahKaryawanScreenState();
}

class _TambahKaryawanScreenState extends State<TambahKaryawanScreen> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final Map<String, TimeOfDay?> _jamMulai = {
    'Senin': null,
    'Selasa': null,
    'Rabu': null,
    'Kamis': null,
    'Jumat': null,
    'Sabtu': null,
    'Minggu': null,
  };
  final Map<String, TimeOfDay?> _jamSelesai = {
    'Senin': null,
    'Selasa': null,
    'Rabu': null,
    'Kamis': null,
    'Jumat': null,
    'Sabtu': null,
    'Minggu': null,
  };
  final Map<String, bool> _hariLibur = {
    'Senin': false,
    'Selasa': false,
    'Rabu': false,
    'Kamis': false,
    'Jumat': false,
    'Sabtu': false,
    'Minggu': false,
  };
  File? _selectedImage;
  String? _imageUrl;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _locations = [];
  final List<String> _selectedLocationIds = [];

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('locations').get();
      setState(() {
        _locations = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'namaLokasi': doc.data()['namaLokasi'],
                  'koordinat': doc.data()['koordinat'],
                })
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengambil data lokasi: $e')),
      );
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

        // Mengunggah ke Google Drive
        final authClient = await clientViaServiceAccount(credentials, scopes);
        final driveApi = drive.DriveApi(authClient);

        final fileName =
            'karyawan_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final driveFile = drive.File()
          ..name = fileName
          ..parents = [dotenv.env['GOOGLE_DRIVE_FOLDER_ID']!];

        final fileContent = _selectedImage!.openRead();
        final media = drive.Media(fileContent, _selectedImage!.lengthSync());

        final uploadedFile = await driveApi.files.create(
          driveFile,
          uploadMedia: media,
        );

        // Mengatur izin publik
        await driveApi.permissions.create(
          drive.Permission()
            ..type = 'anyone'
            ..role = 'reader',
          uploadedFile.id!,
        );

        // Mendapatkan URL publik
        final fileInfo =
            await driveApi.files.get(uploadedFile.id!, $fields: 'webViewLink');
        final webViewLink = (fileInfo as drive.File).webViewLink;

        setState(() {
          _imageUrl = webViewLink;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Gambar berhasil diunggah ke Google Drive: $webViewLink'),
            duration: const Duration(seconds: 5),
          ),
        );
        print('Gambar diunggah ke Google Drive: $webViewLink');

        authClient.close();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengunggah gambar: $e')),
      );
    }
  }

  Future<void> _pickTime(String hari, bool isJamMulai) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isJamMulai) {
          _jamMulai[hari] = picked;
        } else {
          _jamSelesai[hari] = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _tambahKaryawan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    // Periksa apakah pengguna adalah admin
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!userDoc.exists || userDoc.data()?['role'] != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Hanya admin yang dapat menambah karyawan')),
      );
      return;
    }

    final nama = _namaController.text.trim();
    final alamat = _alamatController.text.trim();
    final email = _emailController.text.trim();

    if (nama.isEmpty ||
        alamat.isEmpty ||
        email.isEmpty ||
        _imageUrl == null ||
        _selectedLocationIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Nama, alamat, email, foto, dan minimal satu lokasi harus diisi')),
      );
      return;
    }

    // Minta kata sandi admin
    final adminPassword = await _showPasswordDialog(context);
    if (adminPassword == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Kata sandi diperlukan untuk melanjutkan')),
      );
      return;
    }

    if (!mounted) return; // Cek apakah widget masih mounted sebelum setState
    setState(() {
      _isLoading = true;
    });

    try {
      // Simpan email admin
      final adminEmail = user.email;

      // Tambahkan data karyawan ke Firestore
      final jamKerja = _jamMulai.keys.map((hari) => MapEntry(
            hari,
            {
              'jam_mulai':
                  _hariLibur[hari] == true ? '-' : _formatTime(_jamMulai[hari]),
              'jam_selesai': _hariLibur[hari] == true
                  ? '-'
                  : _formatTime(_jamSelesai[hari]),
              'libur': _hariLibur[hari] ?? false,
            },
          ));

      final karyawanDoc =
          await FirebaseFirestore.instance.collection('karyawan').add({
        'nama': nama,
        'alamat': alamat,
        'foto': _imageUrl,
        'posisi': 'Karyawan',
        'jam_kerja': Map.fromEntries(jamKerja),
        'location_ids': _selectedLocationIds,
      });

      // Buat akun karyawan
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: 'password');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'karyawan_id': karyawanDoc.id,
        'nama': nama,
        'role': 'karyawan',
      });

      // Logout dari akun karyawan
      await FirebaseAuth.instance.signOut();

      // Login kembali ke akun admin
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: adminEmail!,
          password: adminPassword,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal login kembali sebagai admin: $e')),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Karyawan dan user berhasil ditambahkan')),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

// Fungsi untuk menampilkan dialog kata sandi
  Future<String?> _showPasswordDialog(BuildContext context) async {
    final TextEditingController passwordController = TextEditingController();
    String? password;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Masukkan Kata Sandi Admin'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Kata Sandi',
              hintText: 'Masukkan kata sandi admin',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                password = passwordController.text.trim();
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    passwordController.dispose();
    return password;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tambah Karyawan'),
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
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Masukkan email karyawan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Lokasi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _locations.isEmpty
                  ? const Text('Tidak ada lokasi tersedia')
                  : Wrap(
                      spacing: 8.0,
                      children: _locations.map((location) {
                        return FilterChip(
                          label: Text(location['namaLokasi']),
                          selected:
                              _selectedLocationIds.contains(location['id']),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedLocationIds.add(location['id']);
                              } else {
                                _selectedLocationIds.remove(location['id']);
                              }
                            });
                          },
                        );
                      }).toList(),
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
                      : const Icon(Icons.add_a_photo,
                          size: 40, color: Colors.grey),
                ),
              ),
              if (_imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Gambar diunggah: $_imageUrl',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'Jadwal Kerja',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._jamMulai.keys.map((hari) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          hari,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _hariLibur[hari] == true
                                    ? null
                                    : () => _pickTime(hari, true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatTime(_jamMulai[hari]),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _hariLibur[hari] == true
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: _hariLibur[hari] == true
                                    ? null
                                    : () => _pickTime(hari, false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatTime(_jamSelesai[hari]),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _hariLibur[hari] == true
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Checkbox(
                        value: _hariLibur[hari],
                        onChanged: (value) {
                          setState(() {
                            _hariLibur[hari] = value ?? false;
                            if (value == true) {
                              _jamMulai[hari] = null;
                              _jamSelesai[hari] = null;
                            }
                          });
                        },
                      ),
                      const Text('Libur'),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _tambahKaryawan,
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
    _emailController.dispose();
    super.dispose();
  }
}
