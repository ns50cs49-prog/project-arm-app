import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'device_status.dart';
import 'history.dart';
import 'login.dart';
import 'doctor_repository.dart';
import 'profile_photo.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key, this.hideBottomNav = false});

  final bool hideBottomNav;

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    // Refresh the in-memory doctor list from Firestore so doctors the admin
    // just added show up here too, not only after the admin's own screen
    // happens to have loaded them in this app instance.
    DoctorRepository.getDoctorAccountsFuture().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _setTab(int value) => setState(() => _selectedTab = value);

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ออกจากระบบไม่สำเร็จ: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xff10aeb5);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 370;

    // Build only the visible tab — an IndexedStack here would keep every
    // tab's StreamBuilders (Firestore listeners) subscribed at once, even
    // for tabs the user isn't looking at, which piles up watch streams and
    // can trip the local emulator's "too_many_pings" abuse protection.
    final Widget body = switch (_selectedTab) {
      0 => _buildHomeTab(compact),
      1 => _buildQueueTab(compact),
      2 => HistoryPage(patientUserId: FirebaseAuth.instance.currentUser?.uid),
      _ => _buildAccountTab(),
    };

    return Scaffold(
      backgroundColor: const Color(0xfff7fcfd),
      body: body,
      bottomNavigationBar: widget.hideBottomNav
          ? null
          : _BottomNavigation(
              selectedIndex: _selectedTab,
              onTap: _setTab,
              color: teal,
            ),
    );
  }

  Widget _pageShell({required bool compact, required Widget child}) {
    return Stack(
      children: [
        const _HeaderBackground(),
        SafeArea(
          child: Column(
            children: [
              _TopBar(compact: compact, onLogout: _logout),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHomeTab(bool compact) {
    final user = FirebaseAuth.instance.currentUser;
    return _pageShell(
      compact: compact,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const _HomeProfileCard(),
            const SizedBox(height: 14),
            const DeviceStatusCard(),
            if (user == null)
              _NoBookingCard(
                message: 'กรุณาเข้าสู่ระบบ',
                onBookTap: () => _setTab(1),
              )
            else
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: DoctorRepository.watchAppointmentsForPatient(
                  user.uid,
                ),
                builder: (context, snapshot) {
                  final appointments = snapshot.data ?? const [];
                  if (appointments.isEmpty) {
                    return _NoBookingCard(
                      message: 'ยังไม่มีการจองคิววันนี้',
                      onBookTap: () => _setTab(1),
                    );
                  }
                  final appointment = appointments.first;
                  final queueNumber =
                      appointment['queueNumber'] as String? ?? '-';
                  final doctorLoginId =
                      appointment['doctorLoginId'] as String?;
                  final isBeingServed =
                      appointment['called'] as bool? ?? false;
                  if (isBeingServed) {
                    return _QueueStatusCard(
                      queueNumber: queueNumber,
                      aheadCount: 0,
                      inProgress: true,
                    );
                  }
                  if (doctorLoginId == null) {
                    return _QueueStatusCard(
                      queueNumber: queueNumber,
                      aheadCount: 0,
                    );
                  }
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: DoctorRepository.watchAppointmentsForDoctor(
                      doctorLoginId,
                    ),
                    builder: (context, queueSnapshot) {
                      final waitingList = queueSnapshot.data ?? const [];
                      final waitingAhead = waitingList
                          .where(
                            (a) =>
                                ((a['queueNumber'] as String?) ?? '')
                                    .compareTo(queueNumber) <
                                0,
                          )
                          .length;
                      return StreamBuilder<List<Map<String, dynamic>>>(
                        stream:
                            DoctorRepository.watchInProgressAppointmentsForDoctor(
                              doctorLoginId,
                            ),
                        builder: (context, inProgressSnapshot) {
                          final beingTreated =
                              (inProgressSnapshot.data ?? const [])
                                  .isNotEmpty;
                          final aheadCount =
                              waitingAhead + (beingTreated ? 1 : 0);
                          return _QueueStatusCard(
                            queueNumber: queueNumber,
                            aheadCount: aheadCount,
                          );
                        },
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueTab(bool compact) {
    return _pageShell(
      compact: compact,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              if (FirebaseAuth.instance.currentUser != null)
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: DoctorRepository.watchAppointmentsForPatient(
                    FirebaseAuth.instance.currentUser!.uid,
                  ),
                  builder: (context, snapshot) {
                    final appointments = snapshot.data ?? const [];
                    if (appointments.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: [
                        ...appointments.map(
                          (appt) => _MyAppointmentCard(
                            appointment: appt,
                            onCancel: () => _cancelAppointment(appt),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    );
                  },
                ),
              // Show doctors above the booking card; tap a doctor to view status.
              // A single stream covers every doctor's slot instead of one
              // listener each, and doubles as the data used to sort the list:
              // doctors with an open slot float to the top (most recently
              // confirmed first); full/no-slot doctors sink to the bottom.
              StreamBuilder<List<DoctorAvailabilityModel>>(
                stream: DoctorRepository.watchAllAvailabilitiesToday(),
                builder: (context, snapshot) {
                  final slots = snapshot.data ?? const [];
                  final slotByDoctor = <String, DoctorAvailabilityModel>{
                    for (final slot in slots) slot.doctorLoginId: slot,
                  };
                  final originalOrder = <String, int>{
                    for (var i = 0; i < DoctorRepository.doctors.length; i++)
                      DoctorRepository.doctors[i].loginId: i,
                  };
                  final sortedDoctors = [...DoctorRepository.doctors]..sort((
                    a,
                    b,
                  ) {
                    final slotA = slotByDoctor[a.loginId];
                    final slotB = slotByDoctor[b.loginId];
                    final openA =
                        slotA != null && slotA.bookedCount < slotA.maxQueue;
                    final openB =
                        slotB != null && slotB.bookedCount < slotB.maxQueue;
                    if (openA != openB) return openA ? -1 : 1;
                    if (openA && openB) {
                      final updatedA = slotA.updatedAt ?? DateTime(0);
                      final updatedB = slotB.updatedAt ?? DateTime(0);
                      final cmp = updatedB.compareTo(updatedA);
                      if (cmp != 0) return cmp;
                    }
                    return originalOrder[a.loginId]!.compareTo(
                      originalOrder[b.loginId]!,
                    );
                  });

                  return Column(
                    children: sortedDoctors.map((d) {
                      return _DoctorListTile(
                        doctor: d,
                        slot: slotByDoctor[d.loginId],
                        onTap: () async {
                          final booked = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => DoctorTimeSlotPage(
                                    doctor: d,
                                  ),
                                ),
                              );
                          if (booked == true) _setTab(0);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelAppointment(Map<String, dynamic> appt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยกเลิกนัดหมาย'),
        content: const Text('ต้องการยกเลิกนัดหมายนี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ปิด'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ยกเลิกนัดหมาย',
              style: TextStyle(color: Color(0xffe64051)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final appointmentId = appt['id'] as String?;
    final availabilityId = appt['availabilityId'] as String?;
    if (appointmentId == null || availabilityId == null) return;

    try {
      await DoctorRepository.cancelAppointment(
        appointmentId: appointmentId,
        availabilityId: availabilityId,
      ).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ยกเลิกนัดหมายสำเร็จ')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ยกเลิกนัดหมายไม่สำเร็จ: $error')),
      );
    }
  }

  Widget _buildAccountTab() {
    final user = FirebaseAuth.instance.currentUser;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'บัญชีผู้ใช้',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xff114d58),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'จัดการข้อมูลส่วนตัวของคุณ',
              style: TextStyle(fontSize: 13, color: Color(0xff5f8d93)),
            ),
            const SizedBox(height: 18),
            if (user == null)
              _buildAccountFields(name: '-', email: '-', phone: '-')
            else
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data();
                  final storedName = (data?['name'] as String?)?.trim() ?? '';
                  final name = storedName.isNotEmpty
                      ? storedName
                      : (user.displayName?.trim().isNotEmpty ?? false)
                      ? user.displayName!.trim()
                      : 'ผู้ใช้งาน';
                  final storedEmail = (data?['email'] as String?)?.trim() ?? '';
                  final email = storedEmail.isNotEmpty
                      ? storedEmail
                      : (user.email ?? '-');
                  final storedPhone = (data?['phone'] as String?)?.trim() ?? '';
                  final phone = storedPhone.isNotEmpty ? storedPhone : '-';
                  final photoUrl = (data?['photoUrl'] as String?)?.trim() ?? '';
                  return _buildAccountFields(
                    name: name,
                    email: email,
                    phone: phone,
                    photoUrl: photoUrl,
                    uid: user.uid,
                  );
                },
              ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('ออกจากระบบ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffff6b6b),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountFields({
    required String name,
    required String email,
    required String phone,
    String photoUrl = '',
    String? uid,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1b3f7784),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              if (uid == null)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xffe4fbfd),
                  ),
                  child: const CircleAvatar(
                    radius: 38,
                    backgroundColor: Color(0xffdef7f5),
                    child: Icon(
                      Icons.person_rounded,
                      size: 42,
                      color: Color(0xff159ea3),
                    ),
                  ),
                )
              else
                ProfilePhotoAvatar(
                  photoUrl: photoUrl,
                  radius: 38,
                  storagePath: 'profile_photos/patients/$uid.jpg',
                  onUploaded: (url) =>
                      DoctorRepository.updateUserPhoto(uid, url),
                ),
              const SizedBox(height: 14),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff114d58),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'สมาชิกระบบ',
                style: TextStyle(fontSize: 12, color: Color(0xff5b8a8f)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xffd8eef0)),
          ),
          child: Column(
            children: [
              _buildAccountRow('ชื่อ', name),
              const Divider(color: Color(0xffe7f2f3), height: 0),
              _buildAccountRow('อีเมล', email),
              const Divider(color: Color(0xffe7f2f3), height: 0),
              _buildAccountRow('โทรศัพท์', phone),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            Icons.arrow_right_rounded,
            size: 18,
            color: const Color(0xff159ea3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xff114d58),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xff4c7e83),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      width: double.infinity,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffd5f7f8), Color(0xfff7ffff)],
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.elliptical(220, 75),
          ),
        ),
        child: Stack(
          children: const [
            Positioned(right: 24, top: 42, child: _PlusPattern()),
            Positioned(left: 48, top: 118, child: _PlusPattern()),
          ],
        ),
      ),
    );
  }
}

class _PlusPattern extends StatelessWidget {
  const _PlusPattern();

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(
      3,
      (index) => const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.add, size: 13, color: Color(0x4495dadd)),
      ),
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.compact, required this.onLogout});
  final bool compact;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xff54cbd1), width: 1.4),
            ),
            child: const Icon(
              Icons.accessibility_new_rounded,
              color: Color(0xff16adb5),
              size: 23,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ออมรักษาสุขภาพบ้านชุมชน',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff27828b),
                  ),
                ),
                const Text(
                  'ARM PHYSICAL THERAPY',
                  style: TextStyle(
                    fontSize: 7.5,
                    letterSpacing: .2,
                    color: Color(0xff6e9ca1),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 34,
            width: 34,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'ออกจากระบบ',
              padding: EdgeInsets.zero,
              onPressed: onLogout,
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xff159fa8),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _doctorNameFor(String? loginId) {
  for (final doctor in DoctorRepository.doctors) {
    if (doctor.loginId == loginId) return doctor.name;
  }
  return 'แพทย์';
}

class _MyAppointmentCard extends StatelessWidget {
  const _MyAppointmentCard({required this.appointment, required this.onCancel});

  final Map<String, dynamic> appointment;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final doctorName = _doctorNameFor(appointment['doctorLoginId'] as String?);
    final time = (appointment['time'] as String?) ?? 'ไม่ระบุเวลา';
    final queue = (appointment['queueNumber'] as String?) ?? '';
    final isBeingServed = appointment['called'] as bool? ?? false;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffbfe9ea)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_rounded, color: Color(0xff12aeb6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'นัดหมายกับ $doctorName',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff114d58),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isBeingServed
                      ? 'กำลังรักษา • คิว $queue'
                      : 'เวลา $time • คิว $queue',
                  style: const TextStyle(fontSize: 11, color: Color(0xff6b8f94)),
                ),
              ],
            ),
          ),
          if (!isBeingServed)
            TextButton(
              onPressed: onCancel,
              child: const Text(
                'ยกเลิก',
                style: TextStyle(
                  color: Color(0xffe64051),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DoctorListTile extends StatelessWidget {
  const _DoctorListTile({
    required this.doctor,
    required this.slot,
    required this.onTap,
  });

  final DoctorAccount doctor;
  final DoctorAvailabilityModel? slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currentSlot = slot;
    final hasOpenSlot =
        currentSlot != null && currentSlot.bookedCount < currentSlot.maxQueue;
    final String statusLabel;
    final Color statusColor;
    if (currentSlot == null) {
      statusLabel = 'ยังไม่มีเวลาว่าง';
      statusColor = const Color(0xff6b8e91);
    } else if (hasOpenSlot) {
      statusLabel = 'มีเวลาว่าง';
      statusColor = const Color(0xff0d9984);
    } else {
      statusLabel = 'คิวเต็มหมดแล้ว';
      statusColor = const Color(0xffe64051);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xffd8eef0)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xffe8fafa),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
                  size: 21,
                  color: Color(0xff1aaab3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff114d58),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xff139da7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Generates discrete 'HH:mm' appointment times between [startHHmm]
/// (inclusive) and [endHHmm] (exclusive), spaced [intervalMinutes] apart.
class DoctorTimeSlotPage extends StatefulWidget {
  const DoctorTimeSlotPage({super.key, required this.doctor});

  final DoctorAccount doctor;

  @override
  State<DoctorTimeSlotPage> createState() => _DoctorTimeSlotPageState();
}

class _DoctorTimeSlotPageState extends State<DoctorTimeSlotPage> {
  bool _booking = false;

  Future<void> _bookSlot(DoctorAvailabilityModel slot) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ต้องเข้าสู่ระบบ'),
          content: const Text('กรุณาเข้าสู่ระบบก่อนทำการจองคิว'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
      return;
    }
    if (slot.id == null || _booking) return;

    setState(() => _booking = true);

    final doc = {
      'userId': user.uid,
      'displayName': user.displayName ?? '',
      'email': user.email ?? '',
      'phone': user.phoneNumber ?? '',
      'doctorLoginId': widget.doctor.loginId,
      'doctorName': widget.doctor.name,
      'status': 'ยืนยันแล้ว',
      'createdAt': FieldValue.serverTimestamp(),
      'date': slot.dateIso,
    };

    try {
      final queueNumber = await DoctorRepository.bookAvailabilitySlot(
        availabilityId: slot.id!,
        appointmentData: doc,
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (queueNumber == null) {
        setState(() => _booking = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('คิวเต็มแล้ว'),
            content: const Text(
              'ช่วงเวลานี้มีผู้จองเต็มจำนวนแล้ว กรุณาเลือกแพทย์อื่น',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ตกลง'),
              ),
            ],
          ),
        );
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _booking = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ไม่สามารถจองคิวได้'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7fcfd),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xff155f68),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.doctor.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xff114d58),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<List<DoctorAvailabilityModel>>(
                stream: DoctorRepository.watchAvailabilitiesForDoctor(
                  widget.doctor.loginId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'โหลดเวลาว่างไม่สำเร็จ: ${snapshot.error}',
                      style: const TextStyle(color: Color(0xffe64051)),
                    );
                  }
                  final slots = snapshot.data ?? const [];
                  if (slots.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'ยังไม่มีเวลาว่างสำหรับวันนี้',
                          style: TextStyle(color: Color(0xff6b8e91)),
                        ),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: slots.map((slot) {
                      final full = slot.bookedCount >= slot.maxQueue;
                      final date = DateTime.tryParse(slot.dateIso);
                      final dateStr = date != null
                          ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                          : slot.dateIso;

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xffd8eef0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_outlined,
                                  size: 17,
                                  color: Color(0xff0f979f),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff285e65),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 17,
                                  color: Color(0xff0f979f),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${slot.startHHmm} - ${slot.endHHmm} น.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff114d58),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              full
                                  ? 'คิวเต็มแล้วสำหรับวันนี้ (${slot.bookedCount}/${slot.maxQueue} คิว)'
                                  : 'ว่าง ${slot.maxQueue - slot.bookedCount}/${slot.maxQueue} คิว',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: full
                                    ? const Color(0xffe64051)
                                    : const Color(0xff0d9984),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: (full || _booking)
                                    ? null
                                    : () => _bookSlot(slot),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff12aeb6),
                                  disabledBackgroundColor: const Color(
                                    0xfff2f5f6,
                                  ),
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: const Color(
                                    0xffa9bcbf,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  full ? 'คิวเต็มแล้ว' : 'ยืนยันจองคิว',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            if (_booking)
              Container(
                color: const Color(0x33000000),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeProfileCard extends StatelessWidget {
  const _HomeProfileCard();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: Color(0x120d7b82), blurRadius: 12, offset: Offset(0, 6)),
      ],
    ),
    child: Row(
      children: [
        Container(
          height: 52,
          width: 52,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xff42b8bf),
          ),
          child: const Icon(Icons.person_rounded, size: 40, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff173f45),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'ยินดีต้อนรับ',
                style: TextStyle(fontSize: 11, color: Color(0xff82a0a5)),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 12,
                    color: Color(0xff14abb3),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'ข้อมูลปลอดภัย มั่นใจได้',
                    style: TextStyle(fontSize: 9, color: Color(0xff5b8c91)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NoBookingCard extends StatelessWidget {
  const _NoBookingCard({required this.message, required this.onBookTap});

  final String message;
  final VoidCallback onBookTap;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: Color(0x120d7b82), blurRadius: 12, offset: Offset(0, 6)),
      ],
    ),
    child: Column(
      children: [
        const Text(
          'คิวของคุณ',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xff6b8f94),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '-',
          style: TextStyle(
            fontSize: 43,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: Color(0xff087f87),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          message,
          style: const TextStyle(fontSize: 12, color: Color(0xff6e9ca1)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 45,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onBookTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff10aeb5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'ไปยังหน้าจองคิว',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Matches the "your queue status" card design: a teal header bar, the big
/// queue number, a 3-step progress indicator, and rows for how many
/// patients are still ahead / estimated wait / a call-to-wait reminder.
/// [aheadCount] is the number of not-yet-called appointments for the same
/// doctor with a smaller queue number than this patient's own.
class _QueueStatusCard extends StatelessWidget {
  const _QueueStatusCard({
    required this.queueNumber,
    required this.aheadCount,
    this.inProgress = false,
  });

  final String queueNumber;
  final int aheadCount;
  final bool inProgress;

  @override
  Widget build(BuildContext context) {
    final String statusText;
    final int step;
    if (inProgress) {
      statusText = 'กำลังรับการรักษา';
      step = 2;
    } else if (aheadCount <= 0) {
      statusText = 'ถึงคิวคุณแล้ว';
      step = 2;
    } else if (aheadCount <= 2) {
      statusText = 'ใกล้ถึงคิวคุณแล้ว';
      step = 1;
    } else {
      statusText = 'กรุณารอเรียกคิว';
      step = 0;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffbfe9ea)),
        boxShadow: const [
          BoxShadow(color: Color(0x120d7b82), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xff12aeb6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: const Text(
              'สถานะคิวของคุณ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              children: [
                const Text(
                  'คิวของคุณ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xff6b8f94),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  queueNumber,
                  style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: Color(0xff0c7b83),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff114d58),
                  ),
                ),
                const SizedBox(height: 18),
                _QueueProgressSteps(currentStep: step),
                const SizedBox(height: 18),
                if (inProgress)
                  const _QueueStatusRow(
                    icon: Icons.campaign_outlined,
                    label: '',
                    value: 'คุณกำลังเข้ารับการรักษาอยู่',
                  )
                else ...[
                  _QueueStatusRow(
                    icon: Icons.people_alt_outlined,
                    label: 'เหลืออีก',
                    value: '$aheadCount คิว',
                  ),
                  const SizedBox(height: 10),
                  _QueueStatusRow(
                    icon: Icons.campaign_outlined,
                    label: '',
                    value: aheadCount <= 0
                        ? 'ถึงคิวคุณแล้ว กรุณาติดต่อเคาน์เตอร์'
                        : 'กรุณารอเรียกคิว',
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  height: 46,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('อัปเดตสถานะคิวล่าสุดแล้ว'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(
                      'รีเฟรชสถานะคิว',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0c8f96),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueProgressSteps extends StatelessWidget {
  const _QueueProgressSteps({required this.currentStep});

  /// 0 = just booked, 1 = approaching, 2 = your turn.
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    Widget dot(int index) {
      final reached = index <= currentStep;
      return Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: reached ? const Color(0xff12aeb6) : const Color(0xffe3f5f5),
        ),
        child: Icon(
          index < currentStep
              ? Icons.check_rounded
              : index == currentStep
              ? Icons.person_rounded
              : Icons.circle,
          size: index == currentStep ? 16 : (index < currentStep ? 16 : 8),
          color: reached ? Colors.white : const Color(0xffb7d8d9),
        ),
      );
    }

    Widget line(bool active) => Expanded(
      child: Container(
        height: 3,
        color: active ? const Color(0xff12aeb6) : const Color(0xffe3f5f5),
      ),
    );

    return Row(children: [dot(0), line(currentStep >= 1), dot(1), line(currentStep >= 2), dot(2)]);
  }
}

class _QueueStatusRow extends StatelessWidget {
  const _QueueStatusRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xfff3feff),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffd9f0f2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: const Color(0xff12aeb6)),
          const SizedBox(width: 8),
          if (label.isNotEmpty)
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xff507b80)),
            ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xff114d58),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.selectedIndex,
    required this.onTap,
    required this.color,
  });
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'หน้าหลัก'),
      (Icons.calendar_month_outlined, 'จองคิว'),
      (Icons.assignment_outlined, 'ประวัติ'),
      (Icons.person_outline_rounded, 'บัญชีผู้ใช้'),
    ];
    return Container(
      height: 65,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x120d7b82),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = i == selectedIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(i),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    items[i].$1,
                    size: 23,
                    color: active ? color : const Color(0xff72999e),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items[i].$2,
                    style: TextStyle(
                      fontSize: 8,
                      color: active ? color : const Color(0xff72999e),
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
