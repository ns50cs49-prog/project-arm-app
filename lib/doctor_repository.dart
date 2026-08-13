import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Retries a Firestore write a few times on transient channel/network
/// errors (e.g. "Channel shutdownNow invoked") before giving up.
Future<T> _withRetry<T>(Future<T> Function() action, {int retries = 2}) async {
  for (var attempt = 0; ; attempt++) {
    try {
      return await action();
    } on FirebaseException catch (error) {
      final transient = error.code == 'unavailable' || error.code == 'deadline-exceeded';
      if (!transient || attempt >= retries) rethrow;
      await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
    }
  }
}

class DoctorAvailabilityModel {
  const DoctorAvailabilityModel({
    this.id,
    required this.dateIso,
    required this.startHHmm,
    required this.endHHmm,
    required this.maxQueue,
    this.bookedCount = 0,
  });

  final String? id; // Firestore document id
  final String dateIso; // ISO date string (yyyy-MM-ddTHH:mm:ss...)
  final String startHHmm; // e.g. '09:00'
  final String endHHmm; // e.g. '12:30'
  final int maxQueue;
  final int bookedCount;
}

class DoctorAccount {
  const DoctorAccount({
    required this.name,
    required this.email,
    required this.loginId,
  });

  final String name;
  final String email;
  final String loginId;
}

class TreatmentHistoryItem {
  const TreatmentHistoryItem({
    required this.doctorLoginId,
    required this.patientName,
    required this.treatmentType,
    required this.bodyPart,
    required this.setCount,
    required this.dateIso,
    this.note,
  });

  final String doctorLoginId;
  final String patientName;
  final String treatmentType;
  final String bodyPart;
  final int setCount;
  final String dateIso;
  final String? note;
}

class DoctorRepository {
  static final List<DoctorAccount> _doctors = [
    const DoctorAccount(
      name: 'นพ. สมชาย นาคมศักดิ์',
      email: 'somchai@example.com',
      loginId: 'doc1001',
    ),
    const DoctorAccount(
      name: 'พญ. น้ำฝน อ่อนน้อม',
      email: 'namfon@example.com',
      loginId: 'doc1002',
    ),
    const DoctorAccount(
      name: 'น.สพ. ทรงพล ใจดี',
      email: 'songpol@example.com',
      loginId: 'doc1003',
    ),
  ];

  static final List<TreatmentHistoryItem> _treatmentHistory = [
    const TreatmentHistoryItem(
      doctorLoginId: 'doc1001',
      patientName: 'สมศรี คงดี',
      treatmentType: 'กายภาพบำบัดหลังผ่าตัด',
      bodyPart: 'ข้อเข่า',
      setCount: 3,
      dateIso: '2026-08-01',
      note: 'ท่าบริหารข้อเข่า',
    ),
    const TreatmentHistoryItem(
      doctorLoginId: 'doc1001',
      patientName: 'อารีย์ มณี',
      treatmentType: 'กายภาพบำบัดหลังเกิดอุบัติเหตุ',
      bodyPart: 'สะโพกและขา',
      setCount: 4,
      dateIso: '2026-07-24',
      note: 'เพิ่มความแข็งแรงของกล้ามเนื้อ',
    ),
    const TreatmentHistoryItem(
      doctorLoginId: 'doc1002',
      patientName: 'สมศรี คงดี',
      treatmentType: 'กายภาพบำบัดหลังผ่าตัด',
      bodyPart: 'ข้อเข่า',
      setCount: 2,
      dateIso: '2026-07-10',
      note: 'ฝึกเดินและยืน',
    ),
    const TreatmentHistoryItem(
      doctorLoginId: 'doc1002',
      patientName: 'พงศ์พัฒน์ วงศ์ศรี',
      treatmentType: 'ฟื้นฟูหลังให้กำลัง',
      bodyPart: 'หลังส่วนล่าง',
      setCount: 3,
      dateIso: '2026-06-18',
      note: 'กายภาพเพื่อความคล่องตัว',
    ),
    const TreatmentHistoryItem(
      doctorLoginId: 'doc1003',
      patientName: 'อารีย์ มณี',
      treatmentType: 'กายภาพบำบัดไหล่',
      bodyPart: 'ไหล่และต้นแขน',
      setCount: 3,
      dateIso: '2026-06-01',
      note: 'บริหารกล้ามเนื้อไหล่และหลัง',
    ),
  ];

  static final CollectionReference<Map<String, dynamic>>
  _availabilityCollection = FirebaseFirestore.instance.collection(
    'doctorAvailability',
  );

  static final CollectionReference<Map<String, dynamic>>
  _appointmentsCollection = FirebaseFirestore.instance.collection(
    'appointments',
  );

  static List<DoctorAccount> get doctors => List.unmodifiable(_doctors);

  static void addDoctor(DoctorAccount doctor) {
    _doctors.add(doctor);
  }

  static void removeDoctor(String loginId) {
    _doctors.removeWhere(
      (doctor) =>
          doctor.loginId.trim().toLowerCase() == loginId.trim().toLowerCase(),
    );
  }

  /// Each doctor has exactly one availability slot at a time — confirming
  /// again overwrites date/time/maxQueue in place (same doc, keyed by
  /// loginId) instead of adding a new entry. `bookedCount` is deliberately
  /// left out of the merge so already-booked patients aren't dropped.
  static Future<void> addAvailability(
    String loginId, {
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
    required int maxQueue,
  }) {
    String fmt(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return _withRetry(
      () => _availabilityCollection.doc(loginId).set({
        'doctorLoginId': loginId,
        'dateIso': date.toIso8601String(),
        'startHHmm': fmt(start),
        'endHHmm': fmt(end),
        'maxQueue': maxQueue,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }

  /// Deletes the doctor's currently set availability slot (the "free time"
  /// they entered). Appointments already booked against it are untouched —
  /// this only removes the bookable slot itself.
  static Future<void> deleteAvailability(String loginId) {
    return _withRetry(() => _availabilityCollection.doc(loginId).delete());
  }

  /// yyyy-MM-dd for the current day, used to scope slots/queues to "today".
  static String _todayKey() => DateTime.now().toIso8601String().substring(0, 10);

  static Stream<List<DoctorAvailabilityModel>> watchAvailabilitiesForDoctor(
    String loginId,
  ) {
    final today = _todayKey();
    return _availabilityCollection
        .where('doctorLoginId', isEqualTo: loginId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => DoctorAvailabilityModel(
                  id: doc.id,
                  dateIso: doc.data()['dateIso'] as String,
                  startHHmm: doc.data()['startHHmm'] as String,
                  endHHmm: doc.data()['endHHmm'] as String,
                  maxQueue: (doc.data()['maxQueue'] as num?)?.toInt() ?? 0,
                  bookedCount:
                      (doc.data()['bookedCount'] as num?)?.toInt() ?? 0,
                ),
              )
              .where((slot) => slot.dateIso.startsWith(today))
              .toList(),
        );
  }

  /// Atomically checks capacity and books a slot. Returns the assigned
  /// zero-padded queue number, or null if the slot is already full. The
  /// patient no longer picks a specific time — booking is into the
  /// doctor's whole-day range, ordered by booking order.
  static Future<String?> bookAvailabilitySlot({
    required String availabilityId,
    required Map<String, dynamic> appointmentData,
  }) {
    final availabilityRef = _availabilityCollection.doc(availabilityId);

    return _withRetry(() {
      final appointmentRef = _appointmentsCollection.doc();
      return FirebaseFirestore.instance.runTransaction<String?>((
        transaction,
      ) async {
        final snapshot = await transaction.get(availabilityRef);
        if (!snapshot.exists) return null;
        final data = snapshot.data()!;
        final maxQueue = (data['maxQueue'] as num?)?.toInt() ?? 0;
        final bookedCount = (data['bookedCount'] as num?)?.toInt() ?? 0;
        if (bookedCount >= maxQueue) return null;

        final queueNumber = (bookedCount + 1).toString().padLeft(3, '0');
        final startHHmm = data['startHHmm'] as String? ?? '';
        final endHHmm = data['endHHmm'] as String? ?? '';
        transaction.update(availabilityRef, {'bookedCount': bookedCount + 1});
        transaction.set(appointmentRef, {
          ...appointmentData,
          'availabilityId': availabilityId,
          'queueNumber': queueNumber,
          'time': '$startHHmm - $endHHmm น.',
          'called': false,
        });
        return queueNumber;
      });
    });
  }

  static Stream<List<Map<String, dynamic>>> watchAppointmentsForDoctor(
    String doctorLoginId,
  ) {
    final today = _todayKey();
    return _appointmentsCollection
        .where('doctorLoginId', isEqualTo: doctorLoginId)
        .where('called', isEqualTo: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .where((a) => (a['date'] as String? ?? '').startsWith(today))
              .toList()
            ..sort(
              (a, b) => (a['queueNumber'] as String? ?? '').compareTo(
                b['queueNumber'] as String? ?? '',
              ),
            ),
        );
  }

  static Future<void> markAppointmentCalled(String appointmentId) {
    return _withRetry(
      () => _appointmentsCollection.doc(appointmentId).update({
        'called': true,
      }),
    );
  }

  static Stream<List<Map<String, dynamic>>> watchAppointmentsForPatient(
    String userId,
  ) {
    final today = _todayKey();
    return _appointmentsCollection
        .where('userId', isEqualTo: userId)
        .where('called', isEqualTo: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .where((a) => (a['date'] as String? ?? '').startsWith(today))
              .toList()
            ..sort(
              (a, b) => (a['queueNumber'] as String? ?? '').compareTo(
                b['queueNumber'] as String? ?? '',
              ),
            ),
        );
  }

  /// Cancels a booked appointment and frees up its slot on the matching
  /// availability doc (so the seat can be booked again).
  static Future<void> cancelAppointment({
    required String appointmentId,
    required String availabilityId,
  }) {
    final appointmentRef = _appointmentsCollection.doc(appointmentId);
    final availabilityRef = _availabilityCollection.doc(availabilityId);
    return _withRetry(() {
      return FirebaseFirestore.instance.runTransaction<void>((
        transaction,
      ) async {
        final availabilitySnapshot = await transaction.get(availabilityRef);
        transaction.delete(appointmentRef);
        if (availabilitySnapshot.exists) {
          final bookedCount =
              (availabilitySnapshot.data()?['bookedCount'] as num?)
                  ?.toInt() ??
              0;
          if (bookedCount > 0) {
            transaction.update(availabilityRef, {
              'bookedCount': bookedCount - 1,
            });
          }
        }
      });
    });
  }

  static List<TreatmentHistoryItem> getTreatmentsForDoctor(String loginId) {
    final normalizedLoginId = loginId.trim().toLowerCase();
    return _treatmentHistory
        .where(
          (entry) =>
              entry.doctorLoginId.trim().toLowerCase() == normalizedLoginId,
        )
        .toList();
  }

  static List<TreatmentHistoryItem> getTreatmentsForPatient(
    String patientName,
  ) {
    final normalizedPatientName = patientName.trim().toLowerCase();
    return _treatmentHistory
        .where(
          (entry) =>
              entry.patientName.trim().toLowerCase() == normalizedPatientName,
        )
        .toList();
  }

  static List<TreatmentHistoryItem> getTreatmentsForPatientAndDoctor(
    String patientName,
    String doctorLoginId,
  ) {
    final normalizedPatientName = patientName.trim().toLowerCase();
    final normalizedDoctorLoginId = doctorLoginId.trim().toLowerCase();
    return _treatmentHistory.where((entry) {
      return entry.patientName.trim().toLowerCase() == normalizedPatientName &&
          entry.doctorLoginId.trim().toLowerCase() == normalizedDoctorLoginId;
    }).toList();
  }

  static List<String> getPatientNames() {
    return _treatmentHistory.map((entry) => entry.patientName).toSet().toList();
  }

  static DoctorAccount? findByEmailAndLoginId(String email, String loginId) {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedLoginId = loginId.trim().toLowerCase();

    for (final doctor in _doctors) {
      if (doctor.email.trim().toLowerCase() == normalizedEmail &&
          doctor.loginId.trim().toLowerCase() == normalizedLoginId) {
        return doctor;
      }
    }
    return null;
  }
}
