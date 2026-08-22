import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/admin_home.dart';
import 'package:flutter_application_1/doctor_repository.dart';
import 'package:flutter_application_1/firebase_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });
  testWidgets('admin home shows doctor and patient selection cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminHomePage(
          adminName: 'Admin',
          adminEmail: 'admin@example.com',
        ),
      ),
    );

    expect(find.text('จัดการรายชื่อหมอ'), findsOneWidget);
    expect(find.text('จัดการรายชื่อผู้ป่วย'), findsOneWidget);
  });

  testWidgets('admin can navigate to doctor management after selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminHomePage(
          adminName: 'Admin',
          adminEmail: 'admin@example.com',
        ),
      ),
    );

    await tester.tap(find.text('จัดการรายชื่อหมอ'));
    await tester.pumpAndSettle();

    expect(find.text('จัดการรายชื่อหมอ'), findsOneWidget);
    expect(find.text('ค้นหารายชื่อหมอ'), findsOneWidget);
  });

  testWidgets('admin can open a patient account for editing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminHomePage(
          adminName: 'Admin',
          adminEmail: 'admin@example.com',
        ),
      ),
    );

    await tester.tap(find.text('จัดการรายชื่อผู้ป่วย'));
    await tester.pumpAndSettle();

    expect(find.text('บัญชีผู้เข้ารับการรักษา'), findsOneWidget);

    await tester.tap(find.text('สมศรี คงดี'));
    await tester.pumpAndSettle();

    expect(find.text('จัดการบัญชีผู้เข้ารับการรักษา'), findsOneWidget);
    expect(find.text('เปลี่ยนรหัสผ่าน'), findsOneWidget);
  });

  test('patient list includes identifiers from persisted treatment history', () {
    final records = DoctorRepository.getPatientRecords();

    expect(records.any((record) => record.name == 'สมศรี คงดี' && record.id == 'p-001'), isTrue);
    expect(records.any((record) => record.name == 'อารีย์ มณี' && record.id == 'p-002'), isTrue);
  });
}
