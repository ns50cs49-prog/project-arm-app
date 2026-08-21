import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'admin_home.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'patient_home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Dev-only: point Firestore at the local emulator so testing doesn't need
  // a billing-enabled cloud project. Remove this block once the real
  // Firestore database is set up (Blaze plan enabled).
  if (kDebugMode) {
    // Use the dev machine's LAN IP (not localhost/adb reverse) — the
    // Android Firestore SDK's gRPC channel misbehaves over the adb reverse
    // loopback tunnel (spurious "Channel shutdownNow" errors). Phone and PC
    // must be on the same WiFi network. Update this IP if it changes.
    FirebaseFirestore.instance.useFirestoreEmulator('10.10.0.169', 8080);
  }

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

        // Temporary role routing until Firestore is configured.
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
