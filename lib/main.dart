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

  try {
    return await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (error) {
    // On Android, the google-services Gradle plugin auto-registers the
    // "[DEFAULT]" Firebase app natively before Dart runs. On a cold start
    // that can race past the `Firebase.apps.isNotEmpty` check above, so
    // `initializeApp` still gets called and throws `duplicate-app` even
    // though the app is really already initialized — in that case just use
    // the app native side already set up instead of crashing.
    if (error.code == 'duplicate-app') {
      return Firebase.app();
    }
    rethrow;
  }
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
      title: 'ARM ReMotion',
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
