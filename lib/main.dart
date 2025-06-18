import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:iqfence/providers/Auth.dart';
import 'package:iqfence/providers/profileProvider.dart';
import 'package:iqfence/screens/opening/hello_screen.dart';
import 'package:iqfence/service/auth_service.dart';
import 'package:iqfence/service/firestore_service.dart';
import 'package:iqfence/service/google_drive_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await dotenv.load(fileName: ".env");
    runApp(const MyApp());
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Initialization failed: $e')),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Auth()),
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => FirestoreService()),
        Provider(create: (_) => GoogleDriveService()),
        ChangeNotifierProvider(
          create: (context) => ProfileProvider(
            context.read<AuthService>(),
            context.read<FirestoreService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'IQFence',
        theme: ThemeData(useMaterial3: false),
        home: const HelloScreen(),
        // Add localization support
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'), // English
          Locale('id', 'ID'), // Indonesian
        ],
        locale: const Locale('id', 'ID'), // Set default locale to Indonesian
      ),
    );
  }
}
