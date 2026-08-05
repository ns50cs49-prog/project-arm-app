import 'package:flutter/material.dart';

class DocterHomePage extends StatelessWidget {
  const DocterHomePage({super.key, required this.adminName});

  final String adminName;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Center(
      child: Text(
        'สวัสดี, $adminName',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xff186B44),
        ),
      ),
    ),
  );
}
