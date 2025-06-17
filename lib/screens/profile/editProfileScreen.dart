import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iqfence/components/custom_text_field.dart';
import 'package:iqfence/providers/profileProvider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _imageFile;
  final _picker = ImagePicker();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _addressController;
  late TextEditingController _genderController;
  late TextEditingController _ageController;
  late Future<Map<String, dynamic>> _userDataFuture;

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
    final userDoc = await profile.getUserData().first;
    if (!userDoc.exists) {
      return {};
    }
    var data = userDoc.data() as Map<String, dynamic>? ?? {};

    _nameController.text = data['displayName']?.toString() ?? '';
    _phoneController.text = data['phoneNumber']?.toString() ?? '';
    _emailController.text = data['email']?.toString() ?? '';
    _addressController.text = data['address']?.toString() ?? '';
    _genderController.text = data['gender']?.toString() ?? '';
    _ageController.text = data['age']?.toString() ?? '';

    return data;
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
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
        final passwordController =
            TextEditingController(); // Create controller here
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
                passwordController.dispose(); // Dispose on cancel
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
                  passwordController.dispose(); // Dispose on success
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
            return const Center(child: Text('Error loading user data'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No user data available'));
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
                            profile.user.photoURL == null
                                ? Container(
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
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.blue,
                                        width: 3,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 70,
                                      backgroundImage:
                                          NetworkImage(profile.user.photoURL!),
                                    ),
                                  ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const EditProfileScreen(),
                                    ),
                                  );
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
                            fontWeight: FontWeight.w600, fontSize: 16.0),
                      ),
                      const SizedBox(height: 10.0),
                      SizedBox(
                        height: 100, // Limit address field height
                        child: TextField(
                          controller: _addressController,
                          maxLines: 3, // Limit lines to prevent overflow
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
                            fontWeight: FontWeight.w600, fontSize: 16.0),
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
                                _imageFile != null) {
                              if (!await _reauthenticateUser(context)) {
                                return;
                              }
                            }
                            _showLoadingDialog(context);
                            if (_imageFile != null) {
                              await profile
                                  .updateProfilePicture(_imageFile!.path);
                            }
                            await profile.updateUserProfile(
                              name: _nameController.text,
                              phoneNumber: _phoneController.text,
                              password: _passwordController.text.isNotEmpty
                                  ? _passwordController.text
                                  : null,
                              address: _addressController.text,
                              gender: _genderController.text,
                              age: _ageController.text,
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
