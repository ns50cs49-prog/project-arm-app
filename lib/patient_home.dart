import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'appointment.dart';
import 'history.dart';
import 'login.dart';
import 'doctor_repository.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key, this.hideBottomNav = false});

  final bool hideBottomNav;

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  int _selectedTab = 0;
  final String _queue = '0001';
  DoctorAccount? _selectedDoctor;
  DoctorAvailabilityModel? _selectedAvailability;

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

    return Scaffold(
      backgroundColor: const Color(0xfff7fcfd),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildHomeTab(compact),
          _buildQueueTab(compact),
          const HistoryPage(showBottomNav: false),
          _buildAccountTab(),
        ],
      ),
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
    return _pageShell(
      compact: compact,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x120d7b82),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'หน้าหลัก',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff114d58),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'สรุปการใช้งานและนัดหมายล่าสุด',
                    style: TextStyle(fontSize: 12, color: Color(0xff6e9ca1)),
                  ),
                  const SizedBox(height: 16),
                  _QueueNumber(queue: _queue),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 45,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _setTab(1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff10aeb5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'ไปยังหน้าจองคิว',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
              // Show doctors above the booking card; tap a doctor to view status
              ...DoctorRepository.doctors.map(
                (d) => _DoctorListTile(
                  doctor: d,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DoctorTimeSlotPage(
                        doctor: d,
                        selectedAvailabilityId:
                            _selectedDoctor?.loginId == d.loginId
                            ? _selectedAvailability?.id
                            : null,
                        onSelect: (availability) => setState(() {
                          _selectedDoctor = d;
                          _selectedAvailability = availability;
                        }),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _QueueCard(
                queue: _queue,
                selectedDoctor: _selectedDoctor,
                selectedAvailability: _selectedAvailability,
                onConfirm: () => _bookAppointment(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _bookAppointment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // if not logged in, prompt
      if (!mounted) return;
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

    final doctor = _selectedDoctor;
    final availability = _selectedAvailability;
    if (doctor == null || availability?.id == null) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('กรุณาเลือกแพทย์และช่วงเวลา'),
          content: const Text('กรุณาเลือกแพทย์และช่วงเวลาที่ต้องการก่อนจองคิว'),
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

    final doc = {
      'userId': user.uid,
      'displayName': user.displayName ?? '',
      'email': user.email ?? '',
      'phone': user.phoneNumber ?? '',
      'doctorLoginId': doctor.loginId,
      'status': 'ยืนยันแล้ว',
      'createdAt': FieldValue.serverTimestamp(),
      'date': availability!.dateIso,
    };

    try {
      final queueNumber = await DoctorRepository.bookAvailabilitySlot(
        availabilityId: availability.id!,
        appointmentData: doc,
      ).timeout(const Duration(seconds: 10));
      if (queueNumber == null) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('คิวเต็มแล้ว'),
            content: const Text('ช่วงเวลานี้มีผู้จองเต็มจำนวนแล้ว กรุณาเลือกแพทย์อื่น'),
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

      if (!mounted) return;
      setState(() {
        _selectedDoctor = null;
        _selectedAvailability = null;
      });
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AppointmentPage.fromMap(
            id: availability.id!,
            data: {
              ...doc,
              'queue': queueNumber,
              'time': '${availability.startHHmm} - ${availability.endHHmm} น.',
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
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
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ผู้ใช้งานทั่วไป',
                    style: TextStyle(
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
                  _buildAccountRow('ชื่อ', 'User'),
                  const Divider(color: Color(0xffe7f2f3), height: 0),
                  _buildAccountRow('อีเมล', 'user@example.com'),
                  const Divider(color: Color(0xffe7f2f3), height: 0),
                  _buildAccountRow('โทรศัพท์', '081-234-5678'),
                ],
              ),
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
                  'เวลา $time • คิว $queue',
                  style: const TextStyle(fontSize: 11, color: Color(0xff6b8f94)),
                ),
              ],
            ),
          ),
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
  const _DoctorListTile({required this.doctor, required this.onTap});

  final DoctorAccount doctor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                    StreamBuilder<List<DoctorAvailabilityModel>>(
                      stream: DoctorRepository.watchAvailabilitiesForDoctor(
                        doctor.loginId,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text(
                            'โหลดเวลาว่างไม่สำเร็จ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xffe64051),
                            ),
                          );
                        }
                        final slots = snapshot.data ?? const [];
                        final hasOpenSlot = slots.any(
                          (slot) => slot.bookedCount < slot.maxQueue,
                        );
                        final String label;
                        final Color color;
                        if (slots.isEmpty) {
                          label = 'ยังไม่มีเวลาว่าง';
                          color = const Color(0xff6b8e91);
                        } else if (hasOpenSlot) {
                          label = 'มีเวลาว่าง';
                          color = const Color(0xff0d9984);
                        } else {
                          label = 'คิวเต็มหมดแล้ว';
                          color = const Color(0xffe64051);
                        }
                        return Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        );
                      },
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

class DoctorTimeSlotPage extends StatelessWidget {
  const DoctorTimeSlotPage({
    super.key,
    required this.doctor,
    required this.selectedAvailabilityId,
    required this.onSelect,
  });

  final DoctorAccount doctor;
  final String? selectedAvailabilityId;
  final void Function(DoctorAvailabilityModel availability) onSelect;

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
          doctor.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xff114d58),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<List<DoctorAvailabilityModel>>(
            stream: DoctorRepository.watchAvailabilitiesForDoctor(
              doctor.loginId,
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
                  final isSelected =
                      slot.id != null && slot.id == selectedAvailabilityId;
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
                          height: 44,
                          child: ElevatedButton(
                            onPressed: full
                                ? null
                                : () {
                                    onSelect(slot);
                                    Navigator.of(context).pop();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? const Color(0xff0d8c93)
                                  : const Color(0xff12aeb6),
                              disabledBackgroundColor: const Color(0xfff2f5f6),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: const Color(
                                0xffa9bcbf,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              full
                                  ? 'คิวเต็มแล้ว'
                                  : isSelected
                                  ? 'เลือกช่วงเวลานี้แล้ว'
                                  : 'เลือกช่วงเวลานี้',
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
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.queue,
    required this.selectedDoctor,
    required this.selectedAvailability,
    required this.onConfirm,
  });
  final String queue;
  final DoctorAccount? selectedDoctor;
  final DoctorAvailabilityModel? selectedAvailability;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final availability = selectedAvailability;
    final date = DateTime.tryParse(availability?.dateIso ?? '');
    final dateText = availability == null
        ? 'เลือกวันที่จากรายชื่อแพทย์ด้านบน'
        : date != null
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
        : availability.dateIso;
    final timeText = availability == null
        ? 'เลือกช่วงเวลาที่ต้องการ'
        : '${availability.startHHmm} - ${availability.endHHmm} น.';
    final doctorText = selectedDoctor == null
        ? 'เลือกแพทย์ที่ต้องการ'
        : selectedDoctor!.name;

    return Card(
      elevation: 5,
      shadowColor: const Color(0x1a61aeb1),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 13),
        child: Column(
          children: [
            const _ProfileHeader(),
            const SizedBox(height: 14),
            _QueueNumber(queue: queue),
            const SizedBox(height: 10),
            _DetailsTile(
              icon: Icons.medical_services_outlined,
              title: 'แพทย์',
              subtitle: doctorText,
              hasArrow: false,
            ),
            const SizedBox(height: 6),
            _DetailsTile(
              icon: Icons.calendar_month_outlined,
              title: 'วันที่',
              subtitle: dateText,
              hasArrow: false,
            ),
            const SizedBox(height: 6),
            _DetailsTile(
              icon: Icons.access_time_rounded,
              title: 'เวลา',
              subtitle: timeText,
              hasArrow: false,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 47,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: availability != null ? onConfirm : null,
                icon: const Icon(Icons.verified_user_outlined, size: 22),
                label: const Text(
                  'ยืนยันการจองคิว',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xff11b1b7),
                  elevation: 4,
                  shadowColor: const Color(0x664ebbc0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'กรุณามาก่อนเวลานัดหมาย 15 นาที',
                style: TextStyle(fontSize: 8.5, color: Color(0xff557d82)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        height: 52,
        width: 52,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xff42b8bf),
        ),
        child: const Icon(Icons.person_rounded, size: 43, color: Colors.white),
      ),
      const SizedBox(width: 10),
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
            Text(
              'ยินดีต้อนรับ',
              style: TextStyle(fontSize: 10, color: Color(0xff82a0a5)),
            ),
            SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 11,
                  color: Color(0xff14abb3),
                ),
                SizedBox(width: 3),
                Text(
                  'ข้อมูลผู้ใช้งานเป็นปัจจุบัน',
                  style: TextStyle(fontSize: 8, color: Color(0xff5b8c91)),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

class _QueueNumber extends StatelessWidget {
  const _QueueNumber({required this.queue});
  final String queue;

  @override
  Widget build(BuildContext context) => Container(
    height: 88,
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xffe5f9fa),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: const Color(0xff91d9dd)),
    ),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'คิว',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xff146c74),
            ),
          ),
        ),
        Container(height: 45, width: 1, color: const Color(0xffb7e5e7)),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                queue,
                style: const TextStyle(
                  fontSize: 43,
                  height: .95,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: Color(0xff087f87),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'กรุณามาตามเวลานัด',
                style: TextStyle(fontSize: 7.5, color: Color(0xff57848a)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DetailsTile extends StatelessWidget {
  const _DetailsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.hasArrow = true,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool hasArrow;

  @override
  Widget build(BuildContext context) => Container(
    height: 49,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xffd8eef0)),
    ),
    child: Row(
      children: [
        Container(
          height: 29,
          width: 29,
          decoration: const BoxDecoration(
            color: Color(0xffe8fafa),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xff1aaab3), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff386d73),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 7.5, color: Color(0xff82a2a6)),
              ),
            ],
          ),
        ),
        if (hasArrow)
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xff139da7),
          ),
      ],
    ),
  );
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
