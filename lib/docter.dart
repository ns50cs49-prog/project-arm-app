import 'package:flutter/material.dart';

import 'doctor_repository.dart';
import 'login.dart';

class DocterPage extends StatefulWidget {
  const DocterPage({super.key, required this.doctor});

  final DoctorAccount doctor;

  @override
  State<DocterPage> createState() => _DocterPageState();
}

class _DocterPageState extends State<DocterPage> {
  int _selectedTab = 0;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final List<DoctorAvailability> _availabilities = [];

  final List<DoctorPatientBooking> _allBookings = const [
    DoctorPatientBooking(
      doctorLoginId: 'doc1001',
      patientName: 'นายสมชาย ใจดี',
      queueNumber: '0012',
      date: '12/08/2567',
      time: '10:00 น.',
      status: 'ยืนยันแล้ว',
    ),
    DoctorPatientBooking(
      doctorLoginId: 'doc1001',
      patientName: 'นางสาวน้ำฝน แก้วใส',
      queueNumber: '0019',
      date: '13/08/2567',
      time: '14:30 น.',
      status: 'รอดำเนินการ',
    ),
    DoctorPatientBooking(
      doctorLoginId: 'doc1002',
      patientName: 'นายพงศกร กล้าหาญ',
      queueNumber: '0024',
      date: '15/08/2567',
      time: '09:30 น.',
      status: 'ยืนยันแล้ว',
    ),
  ];

  final List<DoctorTreatmentHistory> _historicalRecords = const [
    DoctorTreatmentHistory(
      doctorLoginId: 'doc1001',
      patientName: 'นายสมชาย ใจดี',
      date: '05/08/2567',
      treatment: 'กายภาพบำบัดหลังผ่าตัดเข่า',
      status: 'เสร็จสิ้น',
    ),
    DoctorTreatmentHistory(
      doctorLoginId: 'doc1001',
      patientName: 'นางสาวน้ำฝน แก้วใส',
      date: '30/07/2567',
      treatment: 'นวดบำบัดกล้ามเนื้อหลัง',
      status: 'เสร็จสิ้น',
    ),
    DoctorTreatmentHistory(
      doctorLoginId: 'doc1002',
      patientName: 'นายพงศกร กล้าหาญ',
      date: '25/07/2567',
      treatment: 'ฝังเข็มฟื้นฟู',
      status: 'เสร็จสิ้น',
    ),
  ];

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 17, minute: 0),
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  void _addAvailability() {
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกวันที่และช่วงเวลาที่ว่างก่อน')),
      );
      return;
    }

    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เวลาสิ้นสุดต้องมากกว่าเวลาเริ่มต้น')),
      );
      return;
    }

    setState(() {
      _availabilities.add(
        DoctorAvailability(
          date: _selectedDate!,
          startTime: _startTime!,
          endTime: _endTime!,
        ),
      );
      // persist to repository
      final model = DoctorAvailabilityModel(
        dateIso: _selectedDate!.toIso8601String(),
        startHHmm:
            '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
        endHHmm:
            '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
      );
      DoctorRepository.addAvailability(widget.doctor.loginId, model);
      _selectedDate = null;
      _startTime = null;
      _endTime = null;
    });
  }

  @override
  void initState() {
    super.initState();
    // load saved availabilities from repository
    final models = DoctorRepository.getAvailabilitiesForDoctor(
      widget.doctor.loginId,
    );
    for (final m in models) {
      DateTime? date;
      try {
        date = DateTime.parse(m.dateIso);
      } catch (_) {
        date = DateTime.now();
      }
      TimeOfDay parseTime(String s) {
        final parts = s.split(':');
        final h = int.tryParse(parts[0]) ?? 0;
        final mm = int.tryParse(parts[1]) ?? 0;
        return TimeOfDay(hour: h, minute: mm);
      }

      setState(() {
        _availabilities.add(
          DoctorAvailability(
            date: date!,
            startTime: parseTime(m.startHHmm),
            endTime: parseTime(m.endHHmm),
          ),
        );
      });
    }
  }

  void _logout() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  List<DoctorPatientBooking> get _bookingsForDoctor => _allBookings
      .where((item) => item.doctorLoginId == widget.doctor.loginId)
      .toList();

  List<DoctorTreatmentHistory> get _historyForDoctor => _historicalRecords
      .where((item) => item.doctorLoginId == widget.doctor.loginId)
      .toList();

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildAvailabilityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'สวัสดีคุณ ${widget.doctor.name}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xff114d58),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'อีเมล: ${widget.doctor.email}',
            style: const TextStyle(fontSize: 14, color: Color(0xff3b6b70)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Text(
            'เพิ่มวันที่เข้างานและเวลาว่าง',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  label: 'วันที่เข้างาน',
                  value: _selectedDate != null
                      ? _formatDate(_selectedDate!)
                      : 'เลือกวันที่',
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoCard(
                  label: 'เวลาเริ่ม',
                  value: _startTime != null
                      ? _formatTime(_startTime!)
                      : 'เลือกเวลา',
                  onTap: _pickStartTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoCard(
            label: 'เวลาสิ้นสุด',
            value: _endTime != null ? _formatTime(_endTime!) : 'เลือกเวลา',
            onTap: _pickEndTime,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _addAvailability,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff13a2ac),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'เพิ่มเวลาว่าง',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'รายการเวลาว่าง',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (_availabilities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'ยังไม่ได้เพิ่มเวลาว่าง',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xff6b8e91)),
              ),
            )
          else
            Column(
              children: _availabilities
                  .map((item) => _AvailabilityCard(item: item))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPatientsTab() {
    final bookings = _bookingsForDoctor;
    return SafeArea(
      child: bookings.isEmpty
          ? const Center(
              child: Text(
                'ยังไม่มีผู้ป่วยจองคิวกับคุณหมอคนนี้',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xff6b8e91)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _BookingCard(booking: bookings[index]),
            ),
    );
  }

  Widget _buildHistoryTab() {
    final records = _historyForDoctor;
    return SafeArea(
      child: records.isEmpty
          ? const Center(
              child: Text(
                'ยังไม่มีประวัติการรักษา',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xff6b8e91)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _HistoryCard(record: records[index]),
            ),
    );
  }

  Widget _buildProfileTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'โปรไฟล์คุณหมอ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xff114d58),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xffdef7f5),
                      child: Icon(
                        Icons.medical_services_rounded,
                        size: 40,
                        color: Color(0xff159ea3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      widget.doctor.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff114d58),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'แพทย์กายภาพบำบัด',
                      style: TextStyle(fontSize: 13, color: Color(0xff5f8d93)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ProfileRow(label: 'อีเมล', value: widget.doctor.email),
                  const Divider(color: Color(0xffe7f2f3)),
                  _ProfileRow(
                    label: 'รหัสล็อกอิน',
                    value: widget.doctor.loginId,
                  ),
                  const Divider(color: Color(0xffe7f2f3)),
                  _ProfileRow(
                    label: 'จำนวนผู้ป่วยที่จอง',
                    value: _bookingsForDoctor.length.toString(),
                  ),
                  const Divider(color: Color(0xffe7f2f3)),
                  _ProfileRow(
                    label: 'ประวัติการรักษา',
                    value: _historyForDoctor.length.toString(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildAvailabilityTab(),
      _buildPatientsTab(),
      _buildHistoryTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('หน้าคุณหมอ'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'ออกจากระบบ',
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(index: _selectedTab, children: pages),
      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0c000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            _DoctorNavItem(
              label: 'ว่าง',
              icon: Icons.event_available_rounded,
              active: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
            _DoctorNavItem(
              label: 'ผู้ป่วย',
              icon: Icons.group_rounded,
              active: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
            ),
            _DoctorNavItem(
              label: 'ประวัติ',
              icon: Icons.history_rounded,
              active: _selectedTab == 2,
              onTap: () => setState(() => _selectedTab = 2),
            ),
            _DoctorNavItem(
              label: 'โปรไฟล์',
              icon: Icons.person_rounded,
              active: _selectedTab == 3,
              onTap: () => setState(() => _selectedTab = 3),
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorAvailability {
  DoctorAvailability({
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
}

class DoctorPatientBooking {
  const DoctorPatientBooking({
    required this.doctorLoginId,
    required this.patientName,
    required this.queueNumber,
    required this.date,
    required this.time,
    required this.status,
  });

  final String doctorLoginId;
  final String patientName;
  final String queueNumber;
  final String date;
  final String time;
  final String status;
}

class DoctorTreatmentHistory {
  const DoctorTreatmentHistory({
    required this.doctorLoginId,
    required this.patientName,
    required this.date,
    required this.treatment,
    required this.status,
  });

  final String doctorLoginId;
  final String patientName;
  final String date;
  final String treatment;
  final String status;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xfff3feff),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xffd9f0f2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xff6b8f94)),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xff114d58),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.item});

  final DoctorAvailability item;

  @override
  Widget build(BuildContext context) {
    final date =
        '${item.date.day.toString().padLeft(2, '0')}/${item.date.month.toString().padLeft(2, '0')}/${item.date.year}';
    final timeRange =
        '${item.startTime.format(context)} - ${item.endTime.format(context)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffd8eef0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xff114d58),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            timeRange,
            style: const TextStyle(fontSize: 14, color: Color(0xff3b6b70)),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final DoctorPatientBooking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffd8eef0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking.patientName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff114d58),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffe0fbf9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  booking.status,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff12aeb6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.confirmation_number_outlined,
                size: 16,
                color: Color(0xff0f979f),
              ),
              const SizedBox(width: 8),
              Text(
                'คิว ${booking.queueNumber}',
                style: const TextStyle(fontSize: 12, color: Color(0xff285e65)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 16,
                color: Color(0xff0f979f),
              ),
              const SizedBox(width: 8),
              Text(
                booking.date,
                style: const TextStyle(fontSize: 12, color: Color(0xff285e65)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Color(0xff0f979f),
              ),
              const SizedBox(width: 8),
              Text(
                booking.time,
                style: const TextStyle(fontSize: 12, color: Color(0xff285e65)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record});

  final DoctorTreatmentHistory record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffd8eef0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                record.patientName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff114d58),
                ),
              ),
              Text(
                record.status,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff0f979f),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'วันที่: ${record.date}',
            style: const TextStyle(fontSize: 12, color: Color(0xff285e65)),
          ),
          const SizedBox(height: 6),
          Text(
            'การรักษา: ${record.treatment}',
            style: const TextStyle(fontSize: 12, color: Color(0xff285e65)),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xff6b8f94)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xff114d58),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorNavItem extends StatelessWidget {
  const _DoctorNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: active
                    ? const Color(0xff13a2ac)
                    : const Color(0xff7b9da1),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: active
                      ? const Color(0xff13a2ac)
                      : const Color(0xff7b9da1),
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
