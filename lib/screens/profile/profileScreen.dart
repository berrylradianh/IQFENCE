import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iqfence/models/user_profile.dart'; // Added import for UserProfile
import 'package:iqfence/providers/Auth.dart';
import 'package:iqfence/providers/profileProvider.dart';
import 'package:iqfence/screens/opening/hello_screen.dart';
import 'package:iqfence/screens/profile/editProfileScreen.dart';
import 'package:iqfence/service/google_drive_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context, Auth auth) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Keluar dari Akun"),
          content: const Text("Apakah Anda yakin ingin keluar dari akun?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                auth.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelloScreen(),
                  ),
                );
              },
              child: const Text("Keluar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final googleDriveService =
        Provider.of<GoogleDriveService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    // Check if user is null (not logged in)
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: StreamBuilder<UserProfile>(
          stream: profile.getUserData(),
          builder: (BuildContext context, AsyncSnapshot<UserProfile> snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('User data not found'));
            }

            final userProfile = snapshot.data!;
            final imageUrl = userProfile.photoUrl != null &&
                    userProfile.photoUrl!.isNotEmpty
                ? googleDriveService.getDirectImageUrl(userProfile.photoUrl!)
                : null;

            return Column(
              children: [
                const SizedBox(height: 20),
                Stack(
                  children: [
                    imageUrl == null
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
                              backgroundImage: NetworkImage(imageUrl),
                              onBackgroundImageError: (error, stackTrace) {
                                print('Error loading image: $error');
                              },
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
                              builder: (context) => const EditProfileScreen(),
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
                const SizedBox(height: 20),
                Text(
                  userProfile.name ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user.email ?? 'No email',
                  style: const TextStyle(
                    fontSize: 18.0,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    leading: const Icon(LucideIcons.clipboardEdit,
                        color: Colors.blue),
                    title: const Text('Ubah Informasi Profil'),
                    trailing:
                        const Icon(Icons.arrow_forward_ios, color: Colors.blue),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    leading: const Icon(LucideIcons.logOut, color: Colors.blue),
                    title: const Text('Keluar dari Akun'),
                    trailing:
                        const Icon(Icons.arrow_forward_ios, color: Colors.blue),
                    onTap: () {
                      _showLogoutDialog(context, auth);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
