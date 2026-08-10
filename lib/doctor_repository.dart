class DoctorAvailabilityModel {
  const DoctorAvailabilityModel({
    required this.dateIso,
    required this.startHHmm,
    required this.endHHmm,
  });

  final String dateIso; // ISO date string (yyyy-MM-ddTHH:mm:ss...)
  final String startHHmm; // e.g. '09:00'
  final String endHHmm; // e.g. '12:30'
}

class DoctorAccount {
  const DoctorAccount({
    required this.name,
    required this.email,
    required this.loginId,
    this.availabilities = const [],
  });

  final String name;
  final String email;
  final String loginId;
  final List<DoctorAvailabilityModel> availabilities;
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

  static List<DoctorAccount> get doctors => List.unmodifiable(_doctors);

  static void addDoctor(DoctorAccount doctor) {
    _doctors.add(doctor);
  }

  static void addAvailability(
    String loginId,
    DoctorAvailabilityModel availability,
  ) {
    final idx = _doctors.indexWhere(
      (d) => d.loginId.trim().toLowerCase() == loginId.trim().toLowerCase(),
    );
    if (idx != -1) {
      // mutate the list entry by creating a new DoctorAccount with appended availabilities
      final existing = _doctors[idx];
      final updated = DoctorAccount(
        name: existing.name,
        email: existing.email,
        loginId: existing.loginId,
        availabilities: List.from(existing.availabilities)..add(availability),
      );
      _doctors[idx] = updated;
    }
  }

  static List<DoctorAvailabilityModel> getAvailabilitiesForDoctor(
    String loginId,
  ) {
    final doctor = _doctors.firstWhere(
      (d) => d.loginId.trim().toLowerCase() == loginId.trim().toLowerCase(),
      orElse: () => const DoctorAccount(name: '', email: '', loginId: ''),
    );
    return doctor.availabilities;
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
