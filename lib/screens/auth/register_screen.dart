import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> register() async {
    setState(() {
      isLoading = true;
    });

    try {
      final email = emailController.text.trim();
      final password = passwordController.text;

      // Register ke Firebase Authentication
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Simpan role ke Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'role': 'user', // default role
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pendaftaran berhasil")),
      );

      Navigator.pop(context); // kembali ke halaman login
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const pinkBackground = Color(0xFFFFE4E1);

    return Scaffold(
      backgroundColor: pinkBackground,
      appBar: AppBar(
        backgroundColor: pinkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Daftar",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                hintText: "Masukkan email Anda",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Kata Sandi",
                hintText: "Masukkan kata sandi Anda",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: isLoading ? null : register,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Daftar"),
            ),
          ],
        ),
      ),
    );
  }
}
