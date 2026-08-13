import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/admin_home.dart';

void main() {
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

  testWidgets('admin can navigate to patient history for selected patient', (
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

    expect(find.text('ประวัติการรักษา'), findsOneWidget);

    await tester.tap(find.text('สมศรี คงดี'));
    await tester.pumpAndSettle();

    expect(find.text('ประวัติผู้ป่วย'), findsOneWidget);
    expect(find.text('ค้นหาชื่อผู้ป่วยหรือหมอที่รักษา'), findsOneWidget);
  });
}
