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

  static DoctorAccount? findByEmailAndLoginId(String email, String loginId) {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedLoginId = loginId.trim();

    for (final doctor in _doctors) {
      if (doctor.email.trim().toLowerCase() == normalizedEmail &&
          doctor.loginId == normalizedLoginId) {
        return doctor;
      }
    }
    return null;
  }
}
