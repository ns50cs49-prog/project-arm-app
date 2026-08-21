import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Retries a Firestore write a few times on transient channel/network
/// errors (e.g. "Channel shutdownNow invoked", or the local emulator's
/// gRPC channel getting killed with "GOAWAY ... too_many_pings" which
/// surfaces as `resource-exhausted`) before giving up.
Future<T> _withRetry<T>(Future<T> Function() action, {int retries = 3}) async {
  const transientCodes = {
    'unavailable',
    'deadline-exceeded',
    'resource-exhausted',
  };
  for (var attempt = 0; ; attempt++) {
    try {
      return await action();
    } on FirebaseException catch (error) {
      final transient = transientCodes.contains(error.code);
      if (!transient || attempt >= retries) rethrow;
      await Future.delayed(Duration(milliseconds: 700 * (attempt + 1)));
    }
  }
}

class DoctorAvailabilityModel {
  const DoctorAvailabilityModel({
    this.id,
    required this.doctorLoginId,
    required this.dateIso,
    required this.startHHmm,
    required this.endHHmm,
    required this.maxQueue,
    this.bookedCount = 0,
    this.updatedAt,
  });

  final String? id; // Firestore document id
  final String doctorLoginId;
  final DateTime? updatedAt; // when the doctor last confirmed this slot
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

  static final CollectionReference<Map<String, dynamic>>
  _treatmentHistoryCollection = FirebaseFirestore.instance.collection(
    'treatmentHistory',
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

  static DoctorAvailabilityModel _availabilityFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return DoctorAvailabilityModel(
      id: doc.id,
      doctorLoginId: doc.data()['doctorLoginId'] as String,
      dateIso: doc.data()['dateIso'] as String,
      startHHmm: doc.data()['startHHmm'] as String,
      endHHmm: doc.data()['endHHmm'] as String,
      maxQueue: (doc.data()['maxQueue'] as num?)?.toInt() ?? 0,
      bookedCount: (doc.data()['bookedCount'] as num?)?.toInt() ?? 0,
      updatedAt: (doc.data()['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static Stream<List<DoctorAvailabilityModel>> watchAvailabilitiesForDoctor(
    String loginId,
  ) {
    final today = _todayKey();
    return _availabilityCollection
        .where('doctorLoginId', isEqualTo: loginId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(_availabilityFromDoc)
              .where((slot) => slot.dateIso.startsWith(today))
              .toList(),
        );
  }

  /// Watches every doctor's availability slot for today in a single
  /// listener — used by the patient's doctor list so it doesn't need one
  /// Firestore stream per doctor (which multiplies watch-stream traffic).
  static Stream<List<DoctorAvailabilityModel>> watchAllAvailabilitiesToday() {
    final today = _todayKey();
    return _availabilityCollection.snapshots().map(
      (snapshot) => snapshot.docs
          .map(_availabilityFromDoc)
          .where((slot) => slot.dateIso.startsWith(today))
          .toList(),
    );
  }

  /// Atomically checks capacity and books a slot. Returns the assigned
  /// zero-padded queue number, or null if the slot is already full.
  /// `selectedTimeHHmm` is the specific appointment time the patient
  /// picked (e.g. '10:00') within the doctor's range.
  static Future<String?> bookAvailabilitySlot({
    required String availabilityId,
    required String selectedTimeHHmm,
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
        transaction.update(availabilityRef, {'bookedCount': bookedCount + 1});
        final newAppointment = {
          ...appointmentData,
          'availabilityId': availabilityId,
          'queueNumber': queueNumber,
          'time': '$selectedTimeHHmm น.',
          'called': false,
          'completed': false,
        };
        // ignore: avoid_print
        print('DEBUG bookAvailabilitySlot writing: $newAppointment');
        transaction.set(appointmentRef, newAppointment);
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

  /// Appointments that have been called and are currently being treated
  /// (not yet marked complete by the doctor).
  static Stream<List<Map<String, dynamic>>> watchInProgressAppointmentsForDoctor(
    String doctorLoginId,
  ) {
    final today = _todayKey();
    return _appointmentsCollection
        .where('doctorLoginId', isEqualTo: doctorLoginId)
        .where('called', isEqualTo: true)
        .where('completed', isEqualTo: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .where((a) => (a['date'] as String? ?? '').startsWith(today))
              .toList(),
        );
  }

  /// Marks a called appointment as fully finished (treatment done). Only
  /// then does it disappear from the patient's active-queue view.
  static Future<void> markAppointmentCompleted(String appointmentId) {
    return _withRetry(
      () => _appointmentsCollection.doc(appointmentId).update({
        'completed': true,
      }),
    );
  }

  /// Persists a treatment record (filled in by the doctor when marking an
  /// appointment complete) so patient treatment history survives restarts.
  static Future<void> addTreatmentRecord({
    required String doctorLoginId,
    required String doctorName,
    required String patientName,
    String? patientUserId,
    required String treatmentType,
    required String bodyPart,
    required int setCount,
    required String dateIso,
    String? note,
  }) {
    return _withRetry(
      () => _treatmentHistoryCollection.add({
        'doctorLoginId': doctorLoginId,
        'doctorName': doctorName,
        'patientName': patientName,
        if (patientUserId != null) 'patientUserId': patientUserId,
        'treatmentType': treatmentType,
        'bodyPart': bodyPart,
        'setCount': setCount,
        'dateIso': dateIso,
        if (note != null && note.isNotEmpty) 'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  static TreatmentHistoryItem _treatmentFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return TreatmentHistoryItem(
      doctorLoginId: data['doctorLoginId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      treatmentType: data['treatmentType'] as String? ?? '',
      bodyPart: data['bodyPart'] as String? ?? '',
      setCount: (data['setCount'] as num?)?.toInt() ?? 0,
      dateIso: data['dateIso'] as String? ?? '',
      note: data['note'] as String?,
    );
  }

  /// Real, persisted treatment records for a doctor (separate from the
  /// static demo `_treatmentHistory` list below).
  static Stream<List<TreatmentHistoryItem>> watchTreatmentsForDoctor(
    String doctorLoginId,
  ) {
    return _treatmentHistoryCollection
        .where('doctorLoginId', isEqualTo: doctorLoginId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(_treatmentFromDoc).toList()
            ..sort((a, b) => b.dateIso.compareTo(a.dateIso)),
        );
  }

  /// Active (not-yet-completed) appointments for a patient — stays visible
  /// through "waiting" and "called/in progress" until the doctor marks it
  /// complete, not just until they're called.
  static Stream<List<Map<String, dynamic>>> watchAppointmentsForPatient(
    String userId,
  ) {
    final today = _todayKey();
    return _appointmentsCollection
        .where('userId', isEqualTo: userId)
        .where('completed', isEqualTo: false)
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
