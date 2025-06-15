import 'package:flutter/material.dart';
import 'package:iqfence/screens/auth/register_screen.dart';
import 'package:iqfence/screens/auth/login_screen.dart';

class HelloScreen extends StatelessWidget {
  const HelloScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4E1), // pink soft
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Image.asset('assets/logo.png', width: 60),
            const SizedBox(height: 20),
            Image.asset(
              'assets/construction_worker.png',
              width: 200,
            ),
            const SizedBox(height: 30),
            const Text(
              '"Bangun Disiplin, Hasil Nyata, Proyek Hebat"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () {
                      // Navigasi ke halaman register
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text('Daftar'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.amber),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () {
                      // Navigasi ke halaman login
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                      );
                    },
                    child: const Text('Masuk'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
