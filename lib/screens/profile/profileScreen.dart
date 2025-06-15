import 'package:flutter/material.dart';
import 'package:iqfence/screens/opening/hello_screen.dart';
import 'package:iqfence/screens/profile/editProfileScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/Auth.dart';
import 'package:iqfence/providers/profileProvider.dart';
import 'package:iqfence/components/custom_appbar.dart';
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
    final user = FirebaseAuth.instance.currentUser;
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Text('Something went wrong');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            Map<String, dynamic> data =
                snapshot.data!.data() as Map<String, dynamic>;
            return Column(
              children: [
                const SizedBox(height: 20),
                Stack(
                  children: [
                    profile.user.photoURL == null
                        ? const CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.blue,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 100,
                            ),
                          )
                        : CircleAvatar(
                            radius: 70,
                            backgroundImage:
                                NetworkImage(profile.user.photoURL!),
                          ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: IconButton(
                        icon: Image.asset('assets/edit.png'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  data['displayName'],
                  style: const TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user?.email ?? 'No email',
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
                    leading: Image.asset('assets/people.png'),
                    title: const Text('Ubah Informasi Profil'),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(),
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
                    leading: Image.asset('assets/logout.png'),
                    title: const Text('Keluar dari Akun'),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
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