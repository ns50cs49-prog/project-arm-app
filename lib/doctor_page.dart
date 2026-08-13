import 'package:flutter/material.dart';

import 'doctor_repository.dart';
import 'login.dart';

class DoctorPage extends StatefulWidget {
  const DoctorPage({super.key, required this.doctor});

  final DoctorAccount doctor;

  @override
  State<DoctorPage> createState() => _DoctorPageState();
}

class _DoctorPageState extends State<DoctorPage> {
  int _selectedTab = 0;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _maxQueueController = TextEditingController();

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

  Future<void> _addAvailability() async {
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

    final maxQueue = int.tryParse(_maxQueueController.text.trim());
    if (maxQueue == null || maxQueue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกจำนวนคิวที่รับให้ถูกต้อง')),
      );
      return;
    }

    try {
      await DoctorRepository.addAvailability(
        widget.doctor.loginId,
        date: _selectedDate!,
        start: _startTime!,
        end: _endTime!,
        maxQueue: maxQueue,
      ).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _selectedDate = null;
        _startTime = null;
        _endTime = null;
        _maxQueueController.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เพิ่มเวลาว่างสำเร็จ')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เพิ่มเวลาว่างไม่สำเร็จ: $error')));
    }
  }

  Future<void> _deleteAvailability(String availabilityId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบเวลาว่าง'),
        content: const Text(
          'ต้องการลบเวลาว่างที่ตั้งไว้สำหรับวันนี้หรือไม่? คิวที่ผู้ป่วยจองไว้แล้วจะยังคงอยู่เหมือนเดิม',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ลบ',
              style: TextStyle(color: Color(0xffe64051)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await DoctorRepository.deleteAvailability(
        widget.doctor.loginId,
      ).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบเวลาว่างสำเร็จ')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ลบเวลาว่างไม่สำเร็จ: $error')));
    }
  }

  Future<void> _callNextQueue(Map<String, dynamic> booking) async {
    final id = booking['id'] as String;
    final time = (booking['time'] as String?)?.trim();
    final name = _bookingPatientName(booking);

    try {
      await DoctorRepository.markAppointmentCalled(
        id,
      ).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      final timeLabel = (time == null || time.isEmpty) ? '' : ' เวลา $time';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เรียกคิวคุณ$name$timeLabel')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เรียกคิวไม่สำเร็จ: $error')));
    }
  }

  void _logout() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  List<DoctorTreatmentHistory> get _historyForDoctor => _historicalRecords
      .where((item) => item.doctorLoginId == widget.doctor.loginId)
      .toList();

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xffdef7f5),
                  child: Icon(
                    Icons.medical_services_rounded,
                    size: 20,
                    color: Color(0xff159ea3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'หมอ ${widget.doctor.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff114d58),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                  _InfoCard(
                    label: 'วันที่',
                    value: _selectedDate != null
                        ? _formatDate(_selectedDate!)
                        : 'เลือกวันที่',
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        'เวลา',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff114d58),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TimeChip(
                          value: _startTime != null
                              ? _formatTime(_startTime!)
                              : 'เริ่ม',
                          onTap: _pickStartTime,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TimeChip(
                          value: _endTime != null
                              ? _formatTime(_endTime!)
                              : 'สิ้นสุด',
                          onTap: _pickEndTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        'รับกี่คิว',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff114d58),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 72,
                        child: TextField(
                          controller: _maxQueueController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: const Color(0xfff3feff),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xffd9f0f2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'คิว',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xff6b8f94),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _addAvailability,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff13a2ac),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'ยืนยัน',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<DoctorAvailabilityModel>>(
              stream: DoctorRepository.watchAvailabilitiesForDoctor(
                widget.doctor.loginId,
              ),
              builder: (context, snapshot) {
                final slots = snapshot.data ?? const [];
                if (slots.isEmpty) return const SizedBox.shrink();
                final slot = slots.first;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xfffff6f6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xffffd7d7)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'เวลาว่างที่ตั้งไว้วันนี้',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff114d58),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${slot.startHHmm} - ${slot.endHHmm} น. (${slot.bookedCount}/${slot.maxQueue} คิว)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xff6b8f94),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: slot.id == null
                            ? null
                            : () => _deleteAvailability(slot.id!),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xffe64051),
                          size: 18,
                        ),
                        label: const Text(
                          'ลบ',
                          style: TextStyle(
                            color: Color(0xffe64051),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'คิวที่กำลังรอ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: DoctorRepository.watchAppointmentsForDoctor(
                widget.doctor.loginId,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'โหลดรายชื่อคิวไม่สำเร็จ: ${snapshot.error}',
                      style: const TextStyle(color: Color(0xffe64051)),
                    ),
                  );
                }
                final bookings = snapshot.data ?? const [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (bookings.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'ยังไม่มีผู้ป่วยรอคิว',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xff6b8e91)),
                        ),
                      )
                    else
                      ...bookings.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _QueueRow(
                            position: entry.key + 1,
                            booking: entry.value,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: bookings.isEmpty
                            ? null
                            : () => _callNextQueue(bookings.first),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff13a2ac),
                          disabledBackgroundColor: const Color(0xffb9dde0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'เรียกคิว',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
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
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: DoctorRepository.watchAppointmentsForDoctor(
                      widget.doctor.loginId,
                    ),
                    builder: (context, snapshot) => _ProfileRow(
                      label: 'จำนวนผู้ป่วยที่จอง',
                      value: snapshot.hasError
                          ? 'ผิดพลาด'
                          : (snapshot.data?.length ?? 0).toString(),
                    ),
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
  void dispose() {
    _maxQueueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_buildHomeTab(), _buildHistoryTab(), _buildProfileTab()];

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
              label: 'หน้าหลัก',
              icon: Icons.home_rounded,
              active: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
            _DoctorNavItem(
              label: 'ประวัติ',
              icon: Icons.menu_book_rounded,
              active: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
            ),
            _DoctorNavItem(
              label: 'โปรไฟล์',
              icon: Icons.person_rounded,
              active: _selectedTab == 2,
              onTap: () => setState(() => _selectedTab = 2),
            ),
          ],
        ),
      ),
    );
  }
}

String _bookingPatientName(Map<String, dynamic> booking) {
  final displayName = (booking['displayName'] as String?)?.trim();
  if (displayName != null && displayName.isNotEmpty) return displayName;
  final email = (booking['email'] as String?)?.trim();
  if (email != null && email.isNotEmpty) return email;
  return 'ผู้ป่วย';
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
        width: double.infinity,
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

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xfff3feff),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xffd9f0f2)),
        ),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xff114d58),
          ),
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.position, required this.booking});

  final int position;
  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) {
    final queueNumber = position.toString().padLeft(3, '0');
    final time = (booking['time'] as String?)?.trim();
    final name = _bookingPatientName(booking);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffd8eef0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xffe0fbf9),
              shape: BoxShape.circle,
            ),
            child: Text(
              queueNumber,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xff12aeb6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff114d58),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (time == null || time.isEmpty) ? 'ไม่ระบุเวลา' : time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff6b8f94),
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
