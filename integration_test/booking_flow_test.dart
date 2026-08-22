import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_application_1/doctor_repository.dart';
import 'package:flutter_application_1/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
<<<<<<< HEAD
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.useFirestoreEmulator('10.10.0.169', 8080);
=======
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app();
    }
    FirebaseFirestore.instance.useFirestoreEmulator('10.10.0.135', 8080);
>>>>>>> 67c2897 (TEST)
  });

  testWidgets(
    'doctor-added availability reaches the patient stream and can be booked',
    (tester) async {
      final doctor = DoctorRepository.doctors.first;

      await DoctorRepository.addAvailability(
        doctor.loginId,
        date: DateTime.now(),
        start: const TimeOfDay(hour: 9, minute: 0),
        end: const TimeOfDay(hour: 17, minute: 0),
        maxQueue: 3,
      );

      final slots = await DoctorRepository.watchAvailabilitiesForDoctor(
        doctor.loginId,
      ).first;
      expect(slots, isNotEmpty, reason: 'availability should appear on the patient stream');
      final slot = slots.last;
      expect(slot.maxQueue, 3);
      expect(slot.bookedCount, 0);

      final queueNumber = await DoctorRepository.bookAvailabilitySlot(
        availabilityId: slot.id!,
        appointmentData: {
          'userId': 'test-uid',
          'displayName': 'Test Patient',
          'email': 'test@example.com',
          'phone': '',
          'doctorLoginId': doctor.loginId,
          'status': 'ยืนยันแล้ว',
          'date': slot.dateIso,
        },
      );
      expect(queueNumber, isNotNull, reason: 'booking should succeed and return a queue number');

      final appointments = await DoctorRepository.watchAppointmentsForDoctor(
        doctor.loginId,
      ).first;
      expect(
        appointments.any((a) => a['queueNumber'] == queueNumber),
        isTrue,
        reason: 'the booked appointment should show up in the doctor\'s waiting list',
      );

      await DoctorRepository.markAppointmentCalled(
        appointments.firstWhere((a) => a['queueNumber'] == queueNumber)['id'] as String,
      );

      final afterCall = await DoctorRepository.watchAppointmentsForDoctor(
        doctor.loginId,
      ).first;
      expect(
        afterCall.any((a) => a['queueNumber'] == queueNumber),
        isFalse,
        reason: 'called appointments should drop off the waiting list',
      );
    },
  );
}
