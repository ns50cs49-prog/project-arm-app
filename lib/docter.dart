import 'package:flutter/material.dart';

import 'doctor_repository.dart';

class DocterPage extends StatelessWidget {
  const DocterPage({super.key, required this.doctor});

  final DoctorAccount doctor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('หมอ'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'สวัสดีคุณ ${doctor.name}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xff114d58),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Text(
              'อีเมล: ${doctor.email}',
              style: const TextStyle(fontSize: 16, color: Color(0xff3b6b70)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'รหัสล็อกอิน: ${doctor.loginId}',
              style: const TextStyle(fontSize: 16, color: Color(0xff3b6b70)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
