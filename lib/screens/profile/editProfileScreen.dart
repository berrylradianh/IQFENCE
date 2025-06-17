import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iqfence/components/custom_text_field.dart';
import 'package:iqfence/config/drive_config.dart';
import 'package:iqfence/providers/profileProvider.dart';
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
  late Future<Map<String, dynamic>> _userDataFuture;

  // Function to convert Google Drive URL to direct image URL
  String _getDirectImageUrl(String url) {
    final RegExp regExp = RegExp(r'file/d/([a-zA-Z0-9_-]+)/');
    final match = regExp.firstMatch(url);
    if (match != null) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }
    return url;
  }

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
    _userDataFuture = _loadUserData();
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {};
    }

    // Get user role and ID from users collection
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final role = userDoc.data()?['role'] as String?;
    final adminId = userDoc.data()?['admin_id'] as String?;
    final karyawanId = userDoc.data()?['karyawan_id'] as String?;

    if (role == null) {
      return {};
    }

    final collection = role == 'admin' ? 'admin' : 'karyawan';
    final docId = role == 'admin' ? adminId : karyawanId;

    if (docId == null) {
      return {};
    }

    // Check if user document exists in admin or karyawan collection
    final profileDoc = await FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        .get();

    if (!profileDoc.exists) {
      // Create a default document if it doesn't exist
      await FirebaseFirestore.instance.collection(collection).doc(docId).set({
        'nama': user.displayName ?? '',
        'phoneNumber': '',
        'alamat': '',
        'gender': '',
        'age': '',
        'foto': user.photoURL ?? '',
        'jam_kerja': '',
        'location_ids': [],
        'posisi': role,
      });
    }

    final data = profileDoc.exists
        ? (profileDoc.data() ?? {})
        : {
            'nama': user.displayName ?? '',
            'phoneNumber': '',
            'alamat': '',
            'gender': '',
            'age': '',
            'foto': user.photoURL ?? '',
            'jam_kerja': '',
            'location_ids': [],
            'posisi': role,
          };

    _nameController.text = data['nama']?.toString() ?? '';
    // Remove leading '62', '+62', or '0' for display
    final phoneNumber = data['phoneNumber']?.toString() ?? '';
    _phoneController.text = phoneNumber.startsWith('62')
        ? phoneNumber.substring(2)
        : phoneNumber.startsWith('+62')
            ? phoneNumber.substring(3)
            : phoneNumber.startsWith('0')
                ? phoneNumber.substring(1)
                : phoneNumber;
    _emailController.text = user.email ?? '';
    _addressController.text = data['alamat']?.toString() ?? '';
    _genderController.text = data['gender']?.toString() ?? '';
    _ageController.text = data['age']?.toString() ?? '';
    _imageUrl = data['foto']?.toString();

    return data;
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

  Future<void> _getImage(ImageSource source) async {
    try {
      final hasPermission = await _requestGalleryPermission();
      if (!hasPermission) return;

      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });

        // Mengunggah ke Google Drive
        final authClient = await clientViaServiceAccount(credentials, scopes);
        final driveApi = drive.DriveApi(authClient);

        final fileName =
            'profile_${FirebaseAuth.instance.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final driveFile = drive.File()
          ..name = fileName
          ..parents = [dotenv.env['GOOGLE_DRIVE_FOLDER_ID']!];

        final fileContent = _imageFile!.openRead();
        final media = drive.Media(fileContent, _imageFile!.lengthSync());

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
      print('Error uploading image: $e');
    }
  }

  Future<bool> _reauthenticateUser(BuildContext context) async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) return false;

    bool reauthenticated = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
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
              onPressed: () {
                passwordController.dispose();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: passwordController.text,
                  );
                  await user.reauthenticateWithCredential(credential);
                  reauthenticated = true;
                  passwordController.dispose();
                  Navigator.of(dialogContext).pop();
                } catch (e) {
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

  String _normalizePhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');

    if (cleaned.startsWith('62')) {
      return cleaned;
    } else if (cleaned.startsWith('0')) {
      return '62${cleaned.substring(1)}';
    } else {
      return '62$cleaned';
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Updating...'),
              ],
            ),
          ),
        );
      },
    );
  }

  void _hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
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
    final profile = Provider.of<ProfileProvider>(context);

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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error loading user data: ${snapshot.error}'));
          } else {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height - 100,
                  ),
                  child: ListView(
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            _imageFile != null
                                ? Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.blue,
                                        width: 3,
                                      ),
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
                                            color: Colors.blue,
                                            width: 3,
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          radius: 70,
                                          backgroundImage: NetworkImage(
                                            _getDirectImageUrl(_imageUrl!),
                                          ),
                                          onBackgroundImageError:
                                              (error, stackTrace) {
                                            print(
                                                'Error loading image: $error');
                                          },
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.blue,
                                            width: 3,
                                          ),
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
                                onTap: () async {
                                  await _getImage(ImageSource.gallery);
                                },
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
                      if (_imageUrl != null)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
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
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.0,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      SizedBox(
                        height: 100,
                        child: TextField(
                          controller: _addressController,
                          minLines: 1,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Masukkan alamat Anda di sini',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Jenis Kelamin',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.0,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: ['Male', 'Female']
                                  .contains(_genderController.text)
                              ? _genderController.text
                              : null,
                          decoration: const InputDecoration(
                            hintText: 'Pilih Jenis Kelamin Anda',
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _genderController.text = value ?? '';
                            });
                          },
                          items: ['Male', 'Female']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                  value == 'Male' ? 'Laki-laki' : 'Perempuan'),
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
                            if (_passwordController.text.isNotEmpty ||
                                _imageUrl != null) {
                              if (!await _reauthenticateUser(context)) {
                                return;
                              }
                            }
                            _showLoadingDialog(context);
                            // Normalize phone number before updating
                            final normalizedPhone =
                                _normalizePhoneNumber(_phoneController.text);
                            await profile.updateUserProfile(
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
                            _hideLoadingDialog(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated successfully'),
                              ),
                            );
                            Navigator.pop(context);
                          } catch (e) {
                            _hideLoadingDialog(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update profile: $e'),
                              ),
                            );
                            print('Failed to update profile: $e');
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
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
