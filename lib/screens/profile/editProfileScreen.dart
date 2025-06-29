import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:iqfence/components/custom_text_field.dart';
import 'package:iqfence/providers/profileProvider.dart';
import 'package:iqfence/service/auth_service.dart';
import 'package:iqfence/utils/phone_normalizer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _imageFile;
  String? _imageUrl;
  final _picker = ImagePicker();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _addressController;
  late TextEditingController _genderController;
  late TextEditingController _ageController;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _addressController = TextEditingController();
    _genderController = TextEditingController();
    _ageController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    await profileProvider.loadUserProfile();
    if (!mounted) return;
    final userProfile = profileProvider.userProfile;
    if (userProfile != null) {
      setState(() {
        _nameController.text = userProfile.name ?? '';
        _phoneController.text =
            PhoneNormalizer.normalize(userProfile.phoneNumber ?? '');
        _emailController.text = userProfile.email ?? '';
        _addressController.text = userProfile.address ?? '';
        _genderController.text = userProfile.gender ?? '';
        _ageController.text = userProfile.age ?? '';
        _imageUrl = userProfile.photoUrl;
      });
    }
  }

  Future<bool> _requestGalleryPermission() async {
    final status = await Permission.photos.request();
    if (status.isGranted) return true;
    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) return true;
    }
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Izin galeri diperlukan untuk memilih gambar')),
    );
    return false;
  }

  Future<void> _uploadImage() async {
    try {
      // Check user role first
      final userId = _authService.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User ID tidak ditemukan')),
          );
        }
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists || !mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data pengguna tidak ditemukan')),
        );
        return;
      }

      final userRole = userDoc.data()?['role'] as String?;
      if (userRole == 'admin') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Admin tidak diizinkan mengganti foto profil')),
          );
        }
        return;
      }

      if (!await _requestGalleryPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin galeri ditolak')),
          );
        }
        return;
      }

      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null || !mounted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pemilihan gambar dibatalkan')),
          );
        }
        return;
      }

      setState(() {
        _imageFile = File(pickedFile.path);
      });

      _showLoadingDialog();

      final karyawanId = userDoc.data()?['karyawan_id'] as String?;
      if (karyawanId == null || karyawanId.isEmpty) {
        _hideLoadingDialog();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Karyawan ID tidak ditemukan')),
          );
        }
        return;
      }

      final uri = Uri.parse(
          '${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/upload');
      var request = http.MultipartRequest('POST', uri)
        ..fields['karyawan_id'] = karyawanId
        ..files.add(await http.MultipartFile.fromPath('file', pickedFile.path));

      final response = await request.send();
      if (!mounted) {
        _hideLoadingDialog();
        return;
      }

      final responseData = await http.Response.fromStream(response);
      final responseBody =
          jsonDecode(responseData.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && !responseBody.containsKey('error')) {
        setState(() {
          _imageUrl = responseBody['url'] ?? responseData.body;
        });
        _hideLoadingDialog();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diunggah')),
        );
      } else {
        _hideLoadingDialog();
        final errorMessage = responseBody['error'] ??
            'Gagal mengunggah foto: ${response.statusCode}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (!mounted) {
        _hideLoadingDialog();
        return;
      }
      _hideLoadingDialog();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengunggah foto: $e')),
      );
    }
  }

  Future<bool> _reauthenticateUser() async {
    final user = _authService.currentUser;
    if (user == null) return false;

    bool reauthenticated = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final passwordController = TextEditingController();
        return AlertDialog(
          title: const Text('Re-authentication Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter your password to proceed.'),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  reauthenticated = await _authService.reauthenticateUser(
                    user.email!,
                    passwordController.text,
                  );
                  Navigator.of(dialogContext).pop();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Re-authentication failed: $e')),
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    return reauthenticated;
  }

  void _showLoadingDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Processing...'),
            ],
          ),
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _genderController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Ubah Informasi Profil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.userProfile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      _imageFile != null
                          ? Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.blue, width: 3),
                              ),
                              child: CircleAvatar(
                                radius: 70,
                                backgroundImage: FileImage(_imageFile!),
                              ),
                            )
                          : _imageUrl != null && _imageUrl!.isNotEmpty
                              ? Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.blue, width: 3),
                                  ),
                                  child: CircleAvatar(
                                    radius: 70,
                                    backgroundImage: NetworkImage(_imageUrl!),
                                    onBackgroundImageError:
                                        (error, stackTrace) {
                                      debugPrint('Error loading image: $error');
                                    },
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.blue, width: 3),
                                  ),
                                  child: const CircleAvatar(
                                    radius: 70,
                                    backgroundColor: Colors.blue,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 100,
                                    ),
                                  ),
                                ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _uploadImage,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              LucideIcons.pencil,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _nameController,
                  hintText: 'Masukkan nama lengkap Anda',
                  placeholder: 'Nama Lengkap',
                ),
                const SizedBox(height: 20),
                const Text(
                  'Alamat',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.0),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _addressController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan alamat Anda di sini',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Jenis Kelamin',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.0),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: ['Male', 'Female'].contains(_genderController.text)
                        ? _genderController.text
                        : null,
                    decoration: const InputDecoration(
                      hintText: 'Pilih Jenis Kelamin Anda',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      if (!mounted) return;
                      setState(() {
                        _genderController.text = value ?? '';
                      });
                    },
                    items: ['Male', 'Female']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child:
                            Text(value == 'Male' ? 'Laki-laki' : 'Perempuan'),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _ageController,
                  hintText: 'Masukkan umur Anda',
                  placeholder: 'Umur Anda',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _phoneController,
                  hintText: 'Masukkan nomor telepon Anda',
                  placeholder: 'Nomor Telepon',
                  isPhone: true,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  enabled: false,
                  controller: _emailController,
                  hintText: 'Input your email here',
                  placeholder: 'Email',
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _passwordController,
                  hintText: '*******',
                  placeholder: 'Ganti Password Anda',
                  isPassword: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: const Color(0xff0E82FD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      if (_passwordController.text.isNotEmpty) {
                        if (!mounted) return;
                        if (!await _reauthenticateUser()) return;
                      }
                      if (!mounted) return;
                      _showLoadingDialog();
                      final normalizedPhone =
                          PhoneNormalizer.normalize(_phoneController.text);
                      await Provider.of<ProfileProvider>(context, listen: false)
                          .updateUserProfile(
                        name: _nameController.text,
                        phoneNumber: normalizedPhone,
                        password: _passwordController.text.isNotEmpty
                            ? _passwordController.text
                            : null,
                        address: _addressController.text,
                        gender: _genderController.text,
                        age: _ageController.text,
                        photoUrl: _imageUrl,
                      );
                      if (!mounted) return;
                      _hideLoadingDialog();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Profile updated successfully')),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      if (!mounted) return;
                      _hideLoadingDialog();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update profile: $e')),
                      );
                    }
                  },
                  child: const Text(
                    'Update',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
