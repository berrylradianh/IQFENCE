import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:iqfence/components/custom_text_field.dart';
import 'package:iqfence/providers/profileProvider.dart';


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
    var data = userDoc.data() as Map<String, dynamic>;

    _nameController.text = data['displayName'] ?? '';
    _phoneController.text = data['phoneNumber'] ?? '';
    _emailController.text = data['email'] ?? '';
    _addressController.text = data['address'] ?? '';
    _genderController.text = data['gender'] ?? '';
    _ageController.text = data['age'] ?? '';

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
            color: Colors.black,
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
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No user data available'));
          } else {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ListView(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.blue,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (profile.user.photoURL != null
                                    ? NetworkImage(profile.user.photoURL!)
                                    : null) as ImageProvider?,
                            child: _imageFile == null &&
                                    profile.user.photoURL == null
                                ? const Icon(Icons.person,
                                    size: 100, color: Colors.white)
                                : null,
                          ),
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: IconButton(
                              icon: Image.asset('assets/edit.png'),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => BottomSheet(
                                    onClosing: () {},
                                    builder: (context) => SafeArea(
                                      child: Wrap(
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.camera_alt),
                                            title: const Text('Kamera'),
                                            onTap: () {
                                              _getImage(ImageSource.camera);
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.photo_library),
                                            title: const Text('Galeri'),
                                            onTap: () {
                                              _getImage(ImageSource.gallery);
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
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
                    const SizedBox(
                      height: 10.0,
                    ),
                    TextField(
                      controller: _addressController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan alamat Anda di sini',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Jenis Kelamin',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16.0),
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: ['Male', 'Female', null]
                                .contains(_genderController.text)
                            ? _genderController.text
                            : null,
                        decoration: const InputDecoration(
                          hintText: 'Pilih Jenis Kelamin Anda',
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _genderController.text = value!;
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
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _phoneController,
                      hintText: 'Masukkan nomor telepon Anda',
                      placeholder: 'Nomor Telepon',
                      isPhone: true,
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
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Profile updated successfully'),
                          ));
                          Navigator.pop(context);
                        } catch (e) {
                          _hideLoadingDialog(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Failed to update profile: $e'),
                          ));
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
            );
          }
        },
      ),
    );
  }
}