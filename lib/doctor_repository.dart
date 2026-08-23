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
    this.phoneNumber = '',
    this.photoUrl = '',
  });

  final String name;
  final String email;
  final String loginId;
  final String phoneNumber;
  final String photoUrl;
}

class TreatmentHistoryItem {
  const TreatmentHistoryItem({
    required this.doctorLoginId,
    required this.patientName,
    required this.treatmentType,
    required this.bodyPart,
    required this.setCount,
    required this.dateIso,
    this.patientUserId,
    this.note,
  });

  final String doctorLoginId;
  final String patientName;
  final String treatmentType;
  final String bodyPart;
  final int setCount;
  final String dateIso;
  final String? patientUserId;
  final String? note;
}

class PatientRecord {
  const PatientRecord({
    required this.id,
    required this.name,
    this.email = '',
    this.phone = '',
    this.photoUrl = '',
    this.adminSetPassword = '',
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;

  /// The password the admin most recently set for this account via
  /// `adminSetPatientPassword`, if any — see that Cloud Function for why
  /// this can never reflect a password the patient set themselves.
  final String adminSetPassword;
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
      doctorLoginId: 'doc1001', patientName: 'สมศรี คงดี',
      treatmentType: 'กายภาพบำบัดหลังผ่าตัด', bodyPart: 'ข้อเข่า',
      setCount: 3, dateIso: '2026-08-01', note: 'ท่าบริหารข้อเข่า',
    ),
    const TreatmentHistoryItem(
      doctorLoginId: 'doc1001', patientName: 'อารีย์ มณี',
      treatmentType: 'กายภาพบำบัดหลังเกิดอุบัติเหตุ', bodyPart: 'สะโพกและขา',
      setCount: 4, dateIso: '2026-07-24', note: 'เพิ่มความแข็งแรงของกล้ามเนื้อ',
    ),
    const TreatmentHistoryItem(
      doctorLoginId: 'doc1002', patientName: 'สมศรี คงดี',
      treatmentType: 'กายภาพบำบัดหลังผ่าตัด', bodyPart: 'ข้อเข่า',
      setCount: 2, dateIso: '2026-07-10', note: 'ฝึกเดินและยืน',
    ),
    const TreatmentHistoryItem(
      doctorLoginId: 'doc1002', patientName: 'พงศ์พัฒน์ วงศ์ศรี',
      treatmentType: 'ฟื้นฟูหลังให้กำลัง', bodyPart: 'หลังส่วนล่าง',
      setCount: 3, dateIso: '2026-06-18', note: 'กายภาพเพื่อความคล่องตัว',
    ),
    const TreatmentHistoryItem(
      doctorLoginId: 'doc1003', patientName: 'อารีย์ มณี',
      treatmentType: 'กายภาพบำบัดไหล่', bodyPart: 'ไหล่และต้นแขน',
      setCount: 3, dateIso: '2026-06-01', note: 'บริหารกล้ามเนื้อไหล่และหลัง',
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

  static final CollectionReference<Map<String, dynamic>> _doctorCollection =
      FirebaseFirestore.instance.collection('doctors');

  static List<DoctorAccount> get doctors => List.unmodifiable(_doctors);

  static Future<List<DoctorAccount>> getDoctorAccountsFuture() async {
    var snapshot = await _doctorCollection.get();
    if (snapshot.docs.isEmpty) {
      final settingsRef = FirebaseFirestore.instance
          .collection('settings')
          .doc('doctorAccounts');
      final seeded = await settingsRef.get();
      // Old installs created only `seededAt`; upgrade them once so the
      // original doctor accounts are actually stored in Firestore.
      if ((seeded.data()?['doctorSeedVersion'] as num?)?.toInt() != 1) {
        final batch = FirebaseFirestore.instance.batch();
        for (final doctor in _doctors) {
          batch.set(_doctorCollection.doc(doctor.loginId), {
            'name': doctor.name,
            'email': doctor.email,
            'loginId': doctor.loginId,
            'phoneNumber': doctor.phoneNumber,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        batch.set(settingsRef, {
          'seededAt': FieldValue.serverTimestamp(),
          'doctorSeedVersion': 1,
        }, SetOptions(merge: true));
        await batch.commit();
        snapshot = await _doctorCollection.get();
      }
    }

    final accounts = snapshot.docs.map((doc) {
      final data = doc.data();
      return DoctorAccount(
        name: data['name'] as String? ?? 'หมอ',
        email: data['email'] as String? ?? '',
        loginId: data['loginId'] as String? ?? doc.id,
        phoneNumber: data['phoneNumber'] as String? ?? '',
        photoUrl: data['photoUrl'] as String? ?? '',
      );
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
    _doctors
      ..clear()
      ..addAll(accounts);
    return accounts;
  }

  static void addDoctor(DoctorAccount doctor) {
    _doctors.add(doctor);
  }

  static Future<void> createDoctorAccount(DoctorAccount doctor) async {
    final id = doctor.loginId.trim();
    final existing = await _doctorCollection.doc(id).get();
    if (existing.exists) {
      throw StateError('รหัสหมอ "$id" ถูกใช้งานแล้ว');
    }
    await _doctorCollection.doc(id).set({
      'name': doctor.name,
      'email': doctor.email,
      'loginId': doctor.loginId,
      'phoneNumber': doctor.phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (!_doctors.any((item) => item.loginId == doctor.loginId)) {
      addDoctor(doctor);
    }
  }

  /// Checks Firestore first (the source of truth admin edits write to), not
  /// the in-memory `_doctors` cache — a fresh app session starts that cache
  /// out as the 3 hardcoded seed doctors with their *original* loginId, so
  /// checking it first let a doctor's old loginId keep working forever
  /// after the admin changed it, since this would match and return before
  /// ever consulting Firestore. Firestore is only skipped if unreachable.
  static Future<DoctorAccount?> findDoctorAccount(
    String email,
    String loginId,
  ) async {
    final normalizedEmail = email.trim();
    final normalizedLoginId = loginId.trim();

    try {
      final snapshot = await _doctorCollection
          .where('email', isEqualTo: normalizedEmail)
          .get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if ((data['loginId'] as String? ?? doc.id).trim() !=
            normalizedLoginId) {
          continue;
        }
        final doctor = DoctorAccount(
          name: data['name'] as String? ?? 'หมอ',
          email: data['email'] as String? ?? '',
          loginId: data['loginId'] as String? ?? doc.id,
          phoneNumber: data['phoneNumber'] as String? ?? '',
          photoUrl: data['photoUrl'] as String? ?? '',
        );
        final index = _doctors.indexWhere(
          (item) =>
              item.email.trim().toLowerCase() ==
              normalizedEmail.toLowerCase(),
        );
        if (index != -1) {
          _doctors[index] = doctor;
        } else {
          addDoctor(doctor);
        }
        return doctor;
      }
      return null;
    } on FirebaseException {
      // Firestore unreachable — fall back to whatever's cached locally
      // rather than locking every doctor out on a network hiccup.
      return findByEmailAndLoginId(email, loginId);
    }
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
  static String _todayKey() =>
      DateTime.now().toIso8601String().substring(0, 10);

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
  /// zero-padded queue number, or null if the slot is already full. Books
  /// into the doctor's whole-day range — the patient no longer picks a
  /// specific time.
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
          'completed': false,
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
          (snapshot) =>
              snapshot.docs
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
      () => _appointmentsCollection.doc(appointmentId).update({'called': true}),
    );
  }

  /// Appointments that have been called and are currently being treated
  /// (not yet marked complete by the doctor).
  static Stream<List<Map<String, dynamic>>>
  watchInProgressAppointmentsForDoctor(String doctorLoginId) {
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
        if (patientUserId != null && patientUserId.isNotEmpty)
          'patientUserId': patientUserId,
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
      patientUserId: data['patientUserId'] as String?,
      note: data['note'] as String?,
    );
  }

  /// Real, persisted treatment records for a doctor.
  static Stream<List<TreatmentHistoryItem>> watchTreatmentsForDoctor(
    String doctorLoginId,
  ) {
    return _treatmentHistoryCollection
        .where('doctorLoginId', isEqualTo: doctorLoginId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(_treatmentFromDoc).toList()
                ..sort((a, b) => b.dateIso.compareTo(a.dateIso)),
        );
  }

  /// Every persisted treatment record — used by the admin history views.
  static Stream<List<TreatmentHistoryItem>> watchAllTreatments() {
    return _treatmentHistoryCollection.snapshots().map(
      (snapshot) =>
          snapshot.docs.map(_treatmentFromDoc).toList()
            ..sort((a, b) => b.dateIso.compareTo(a.dateIso)),
    );
  }

  /// A patient's own treatment history, matched by their Firebase Auth uid.
  static Stream<List<TreatmentHistoryItem>> watchTreatmentsForPatientUserId(
    String userId,
  ) {
    return _treatmentHistoryCollection
        .where('patientUserId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(_treatmentFromDoc).toList()
                ..sort((a, b) => b.dateIso.compareTo(a.dateIso)),
        );
  }

  /// A patient's treatment history matched by name — used by the admin
  /// patient-management screen, which only has the patient's name to go on.
  static Stream<List<TreatmentHistoryItem>> watchTreatmentsForPatientName(
    String patientName,
  ) {
    return _treatmentHistoryCollection
        .where('patientName', isEqualTo: patientName)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(_treatmentFromDoc).toList()
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
          (snapshot) =>
              snapshot.docs
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
              (availabilitySnapshot.data()?['bookedCount'] as num?)?.toInt() ??
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

  static String _patientIdForName(String patientName, int index) {
    final code = (index + 1).toString().padLeft(3, '0');
    return 'p-$code';
  }

  static List<PatientRecord> getPatientRecords() {
    final ordered = <String, PatientRecord>{};

    for (final entry in _treatmentHistory) {
      final patientName = entry.patientName.trim();
      final patientId = (entry.patientUserId ?? '').trim();
      if (patientId.isNotEmpty) {
        ordered.putIfAbsent(
          patientId,
          () => PatientRecord(id: patientId, name: patientName),
        );
        continue;
      }
      if (patientName.isEmpty) continue;
      final key = patientName.toLowerCase();
      ordered.putIfAbsent(
        key,
        () => PatientRecord(
          id: _patientIdForName(patientName, ordered.length),
          name: patientName,
        ),
      );
    }

    return ordered.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static Future<List<PatientRecord>> getPatientRecordsFuture() async {
    final recordsById = <String, PatientRecord>{};
    final deletedUserIds = <String>{};

    void addRecord(
      String? patientId,
      String? patientName, {
      String? email,
      String? phone,
      String? photoUrl,
      String? adminSetPassword,
    }) {
      final id = (patientId ?? '').trim();
      final name = (patientName ?? '').trim();
      if (id.isEmpty && name.isEmpty) return;
      if (id.isNotEmpty && deletedUserIds.contains(id)) return;

      if (id.isNotEmpty) {
        recordsById.putIfAbsent(
          id,
          () => PatientRecord(
            id: id,
            name: name.isNotEmpty ? name : 'ผู้ป่วย',
            email: (email ?? '').trim(),
            phone: (phone ?? '').trim(),
            photoUrl: (photoUrl ?? '').trim(),
            adminSetPassword: (adminSetPassword ?? '').trim(),
          ),
        );
        return;
      }

      final fallbackKey = name.isEmpty ? 'unknown' : name.toLowerCase();
      recordsById.putIfAbsent(
        fallbackKey,
        () => PatientRecord(
          id: 'p-${recordsById.length + 1}'.padRight(10, '0').replaceAll(' ', ''),
          name: name,
          email: (email ?? '').trim(),
          phone: (phone ?? '').trim(),
        ),
      );
    }

    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      if (data['deletedAt'] != null) {
        deletedUserIds.add(doc.id);
        continue;
      }
      addRecord(
        doc.id,
        data['name'] as String?,
        email: data['email'] as String?,
        phone: data['phone'] as String?,
        photoUrl: data['photoUrl'] as String?,
        adminSetPassword: data['adminSetPassword'] as String?,
      );
    }

    final treatmentSnapshot = await _treatmentHistoryCollection.get();
    for (final doc in treatmentSnapshot.docs) {
      final data = doc.data();
      addRecord(
        data['patientUserId'] as String?,
        data['patientName'] as String?,
      );
    }

    final appointmentsSnapshot = await _appointmentsCollection.get();
    for (final doc in appointmentsSnapshot.docs) {
      final data = doc.data();
      addRecord(
        data['userId'] as String?,
        (data['displayName'] as String?) ??
            (data['email'] as String?) ??
            (data['patientName'] as String?),
        email: data['email'] as String?,
        phone: data['phone'] as String?,
      );
    }

    if (recordsById.isEmpty) {
      return getPatientRecords();
    }

    final records = recordsById.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return records;
  }

  /// Lets a patient (or the admin, who also has a `users/{uid}` doc) set
  /// their own profile photo.
  static Future<void> updateUserPhoto(String uid, String photoUrl) {
    return _withRetry(
      () => FirebaseFirestore.instance.collection('users').doc(uid).set({
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }

  static Future<void> updateDoctorAccount({
    required String previousLoginId,
    required DoctorAccount doctor,
  }) async {
    final oldId = previousLoginId.trim();
    final newId = doctor.loginId.trim();
    final snapshots = await Future.wait([
      _appointmentsCollection.where('doctorLoginId', isEqualTo: oldId).get(),
      _treatmentHistoryCollection.where('doctorLoginId', isEqualTo: oldId).get(),
    ]);
    final batch = FirebaseFirestore.instance.batch();
    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'doctorLoginId': newId,
          'doctorName': doctor.name,
        });
      }
    }
    if (oldId != newId) {
      final oldAvailability = await _availabilityCollection.doc(oldId).get();
      if (oldAvailability.exists) {
        batch.set(_availabilityCollection.doc(newId), {
          ...oldAvailability.data()!,
          'doctorLoginId': newId,
        });
        batch.delete(oldAvailability.reference);
      }
    }
    await batch.commit();
    await _doctorCollection.doc(oldId).delete();
    await _doctorCollection.doc(newId).set({
      'name': doctor.name,
      'email': doctor.email,
      'loginId': newId,
      'phoneNumber': doctor.phoneNumber,
      'photoUrl': doctor.photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final index = _doctors.indexWhere((item) => item.loginId == oldId);
    if (index != -1) _doctors[index] = doctor;
  }

  /// Lets a doctor set their own profile photo without going through the
  /// full account-edit flow (which would also require re-typing every other
  /// field). Firestore doc id doesn't change here, so a plain merge is safe.
  static Future<void> updateDoctorPhoto(String loginId, String photoUrl) {
    final id = loginId.trim();
    final index = _doctors.indexWhere((item) => item.loginId == id);
    if (index != -1) {
      _doctors[index] = DoctorAccount(
        name: _doctors[index].name,
        email: _doctors[index].email,
        loginId: _doctors[index].loginId,
        phoneNumber: _doctors[index].phoneNumber,
        photoUrl: photoUrl,
      );
    }
    return _withRetry(
      () => _doctorCollection.doc(id).set({
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }

  static Future<void> deleteDoctorAccount(String loginId) async {
    final id = loginId.trim();
    final snapshots = await Future.wait([
      _appointmentsCollection.where('doctorLoginId', isEqualTo: id).get(),
      _treatmentHistoryCollection.where('doctorLoginId', isEqualTo: id).get(),
    ]);
    final refs = <DocumentReference<Map<String, dynamic>>>[
      _availabilityCollection.doc(id),
    ];
    for (final snapshot in snapshots) {
      refs.addAll(snapshot.docs.map((doc) => doc.reference));
    }
    final uniqueRefs = refs.toSet().toList();
    for (var start = 0; start < uniqueRefs.length; start += 500) {
      final batch = FirebaseFirestore.instance.batch();
      final end = start + 500 < uniqueRefs.length
          ? start + 500
          : uniqueRefs.length;
      for (final ref in uniqueRefs.sublist(start, end)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
    await _doctorCollection.doc(id).delete();
    removeDoctor(id);
  }

  /// Deletes the patient's Firestore profile and all appointment/treatment
  /// documents linked to that account. Firebase Authentication accounts must
  /// be deleted through the Admin SDK on a trusted server.
  static Future<void> deletePatientAccount({
    required String patientId,
  }) async {
    final userId = patientId.trim();
    final refs = <DocumentReference<Map<String, dynamic>>>[
      FirebaseFirestore.instance.collection('users').doc(userId),
    ];

    final snapshots = await Future.wait([
      _appointmentsCollection.where('userId', isEqualTo: userId).get(),
      _treatmentHistoryCollection.where('patientUserId', isEqualTo: userId).get(),
    ]);
    for (final snapshot in snapshots) {
      refs.addAll(snapshot.docs.map((doc) => doc.reference));
    }

    final uniqueRefs = refs.toSet().toList();
    for (var start = 0; start < uniqueRefs.length; start += 500) {
      final batch = FirebaseFirestore.instance.batch();
      final end = start + 500 < uniqueRefs.length
          ? start + 500
          : uniqueRefs.length;
      for (final ref in uniqueRefs.sublist(start, end)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  static List<String> getPatientNames() {
    return getPatientRecords().map((record) => record.name).toList();
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
