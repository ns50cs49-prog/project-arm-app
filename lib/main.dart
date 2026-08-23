import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'admin_home.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'patient_home.dart';

Future<FirebaseApp> initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) {
    return Firebase.app();
  }

  return Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeFirebase();

  runApp(const QueueApp());
}

class QueueApp extends StatelessWidget {
  const QueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARM Physical Therapy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff12aeb6)),
        fontFamily: 'Tahoma',
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginPage();
        }

        final email = user.email?.trim().toLowerCase();
        if (email == 'raddawan3079@gmail.com') {
          return AdminHomePage(
            adminName: 'Admin',
            adminEmail: user.email ?? 'admin@armcare.com',
          );
        }

        return const PatientHomePage();
      },
    );
  }
}
