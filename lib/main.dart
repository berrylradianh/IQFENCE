import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:iqfence/providers/Auth.dart';
import 'package:iqfence/providers/profileProvider.dart';
import 'package:iqfence/screens/opening/hello_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Auth()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        // Tambahkan provider lain jika perlu
      ],
      child: MaterialApp(
        title: 'IQFence',
        theme: ThemeData(useMaterial3: false),
        home: const HelloScreen(),
      ),
    );
  }
}
