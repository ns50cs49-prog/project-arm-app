import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'appointment.dart';
import 'doctor_repository.dart';
import 'history.dart';
import 'login.dart';

enum AdminMode { none, doctor, patient }

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({
    super.key,
    required this.adminName,
    required this.adminEmail,
  });

  final String adminName;
  final String adminEmail;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _loginIdController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _notificationsEnabled = true;
  int _selectedTab = 0;
  AdminMode _adminMode = AdminMode.none;
  String _doctorSearch = '';
  String? _selectedDoctorLoginId;
  String? _selectedPatientName;

  void _navigateTo(int index) {
    setState(() => _selectedTab = index);
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _loginIdController.clear();
    _phoneController.clear();
  }

  void _switchAdminMode(AdminMode mode) {
    setState(() {
      _adminMode = mode;
      _selectedDoctorLoginId = null;
      _selectedPatientName = null;
      _doctorSearch = '';
    });
  }

  Future<void> _addDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    final doctor = DoctorAccount(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      loginId: _loginIdController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    try {
      await DoctorRepository.createDoctorAccount(doctor);
    } on FirebaseException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สร้างบัญชีหมอไม่สำเร็จ')),
        );
      }
      return;
    }

    _clearForm();
    if (mounted) {
      setState(() {});
      Navigator.of(context).pop();
    }
  }

  Future<void> _showAddDoctorDialog() async {
    _clearForm();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xffeefaf9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
        title: const Text(
          'เพิ่มข้อมูลหมอ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xff114d58),
          ),
        ),
        content: Form(
          key: _formKey,
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'ชื่อหมอ',
                  hintText: 'เช่น นพ. สมชาย นาคมศักดิ์',
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _emailController,
                  label: 'อีเมลหมอ',
                  hintText: 'เช่น doctor@example.com',
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _phoneController,
                  label: 'เบอร์โทรศัพท์หมอ',
                  hintText: 'เช่น 0812345678',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _loginIdController,
                  label: 'รหัสล็อกอินหมอ',
                  hintText: 'เช่น doc1001',
                ),
              ],
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'ยกเลิก',
                      style: TextStyle(
                        color: Color(0xff114d58),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _addDoctor(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff13a2ac),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('เพิ่มหมอ'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return _adminMode == AdminMode.none
        ? _buildSelectionScreen()
        : _adminMode == AdminMode.doctor
        ? _buildDoctorManagementScreen()
        : _buildPatientManagementScreen();
  }

  Widget _buildSelectionScreen() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xfff8ffff),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0f1f5a5a),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'แอดมิน',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff114d58),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'ระบบจัดการเครื่องกายภาพ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xff5f8d93),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xff7ed7d7), Color(0xff19a7b4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1f0c8a8d),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: Column(
                children: [
                  _DashboardCard(
                    label: 'สถานะเครื่อง',
                    icon: Icons.monitor_heart_outlined,
                    backgroundColor: const Color(0xff9fe2e0),
                    onTap: () {},
                    trailing: StreamBuilder<DatabaseEvent>(
                      stream: FirebaseDatabase.instance.ref('esp32/led').onValue,
                      builder: (context, snapshot) {
                        final data = snapshot.data?.snapshot.value;
                        final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
                        final status = (map['status'] ?? '').toString().toUpperCase();

                        final updatedAtValue =
                            map['updatedAt'] ??
                            map['timestamp'] ??
                            map['lastSeen'] ??
                            map['time'];

                        DateTime? updatedAt;
                        if (updatedAtValue is int) {
                          updatedAt = DateTime.fromMillisecondsSinceEpoch(updatedAtValue);
                        } else if (updatedAtValue is num) {
                          updatedAt = DateTime.fromMillisecondsSinceEpoch(updatedAtValue.round());
                        } else if (updatedAtValue is String) {
                          final parsed = int.tryParse(updatedAtValue);
                          if (parsed != null) {
                            updatedAt = DateTime.fromMillisecondsSinceEpoch(parsed);
                          } else {
                            updatedAt = DateTime.tryParse(updatedAtValue);
                          }
                        }

                        final isWorking =
                            status == 'ON' ||
                            status == 'WORKING' ||
                            status == 'RUNNING';
                        final isStaleOnline =
                            status == 'ONLINE' &&
                            updatedAt != null &&
                            DateTime.now().difference(updatedAt).inSeconds > 30;
                        final isOffline =
                            !snapshot.hasData ||
                            snapshot.hasError ||
                            status == 'OFF' ||
                            status == 'OFFLINE' ||
                            isStaleOnline;
                        final isOnline = !isWorking && !isOffline && (status == 'ONLINE' || status == 'CONNECTED');
                        final label = isWorking ? 'กำลังทำงาน' : isOnline ? 'ออนไลน์' : 'ออฟไลน์';
                        final color = isWorking
                            ? const Color(0xff0d9984)
                            : isOnline
                            ? const Color(0xfff39a1d)
                            : const Color(0xff7a8d92);

                        return Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DashboardCard(
                    label: 'จัดการรายชื่อหมอ',
                    subtitle: 'เพิ่ม / แก้ไข / ลบรายชื่อหมอ',
                    icon: Icons.medical_information_outlined,
                    backgroundColor: const Color(0xffa8e3de),
                    onTap: () => _switchAdminMode(AdminMode.doctor),
                  ),
                  const SizedBox(height: 18),
                  _DashboardCard(
                    label: 'จัดการรายชื่อผู้ป่วย',
                    subtitle: 'เพิ่ม / แก้ไข / ลบรายชื่อผู้ป่วย',
                    icon: Icons.people_alt_outlined,
                    backgroundColor: const Color(0xffa8e3de),
                    onTap: () => _switchAdminMode(AdminMode.patient),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorManagementScreen() {
    final filteredDoctors = DoctorRepository.doctors.where((doctor) {
      final search = _doctorSearch.trim().toLowerCase();
      return search.isEmpty || doctor.name.toLowerCase().contains(search);
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xff155f68),
                  ),
                  onPressed: () => _switchAdminMode(AdminMode.none),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'จัดการรายชื่อหมอ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff114d58),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xff13a2ac),
                    size: 30,
                  ),
                  onPressed: _showAddDoctorDialog,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SearchInput(
              hintText: 'ค้นหารายชื่อหมอ',
              value: _doctorSearch,
              onChanged: (value) => setState(() => _doctorSearch = value),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xffd8f3f2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: filteredDoctors.isEmpty
                  ? const Center(
                      child: Text(
                        'ไม่พบชื่อหมอที่ค้นหา',
                        style: TextStyle(color: Color(0xff5b8a8f)),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredDoctors.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final doctor = filteredDoctors[index];
                        return _SelectionTile(
                          title: doctor.name,
                          subtitle: 'รหัส: ${doctor.loginId}',
                          selected: false,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DoctorDetailPage(
                                  doctor: doctor,
                                ),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientManagementScreen() {
    final patientSearch = _doctorSearch.trim().toLowerCase();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xff155f68),
                  ),
                  onPressed: () => _switchAdminMode(AdminMode.none),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'บัญชีผู้เข้ารับการรักษา',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff114d58),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SearchInput(
              hintText: 'ค้นหาชื่อ อีเมล หรือเบอร์โทร',
              value: _doctorSearch,
              onChanged: (value) => setState(() => _doctorSearch = value),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<PatientRecord>>(
              future: DoctorRepository.getPatientRecordsFuture(),
              builder: (context, snapshot) {
                final patients = snapshot.data ?? DoctorRepository.getPatientRecords();
                final filteredPatients = patients.where((record) {
                  if (patientSearch.isEmpty) return true;
                  if (record.name.toLowerCase().contains(patientSearch)) return true;
                  if (record.id.toLowerCase().contains(patientSearch)) return true;
                  if (record.email.toLowerCase().contains(patientSearch)) return true;
                  return record.phone.toLowerCase().contains(patientSearch);
                }).toList();

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xff13a2ac),
                    ),
                  );
                }

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xffd8f3f2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: filteredPatients.isEmpty
                      ? const Center(
                          child: Text(
                            'ไม่พบบัญชีผู้เข้ารับการรักษาที่ค้นหา',
                            style: TextStyle(color: Color(0xff5b8a8f)),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredPatients.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final patient = filteredPatients[index];
                            return _SelectionTile(
                              title: patient.name,
                              subtitle: '${patient.email.isEmpty ? 'ยังไม่มีอีเมล' : patient.email}\n${patient.phone.isEmpty ? 'ยังไม่มีเบอร์โทร' : patient.phone}',
                              selected: false,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PatientAccountPage(patient: patient),
                                  ),
                                );
                                if (mounted) setState(() {});
                              },
                            );
                          },
                        ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xfff5fcfd),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xffd8eef0)),
              ),
              child: const Text(
                'เลือกบัญชีเพื่อแก้ไขอีเมล เบอร์โทรศัพท์ หรือส่งลิงก์ตั้งรหัสผ่านใหม่',
                style: TextStyle(fontSize: 14, color: Color(0xff114d58)),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDoctorDetailCard(DoctorAccount doctor) {
    final treatments = DoctorRepository.getTreatmentsForDoctor(doctor.loginId);
    final patientNames = treatments
        .map((item) => item.patientName)
        .toSet()
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff5fcfd),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffd8eef0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${doctor.name} เคยรักษาผู้ป่วยทั้งหมด ${patientNames.length} คน',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xff114d58),
            ),
          ),
          const SizedBox(height: 10),
          if (patientNames.isEmpty)
            const Text('ยังไม่มีผู้ป่วยที่รักษากับหมอคนนี้')
          else
            ...patientNames.map(
              (name) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SelectionTile(
                  title: name,
                  subtitle:
                      'รักษากับหมอคนนี้ ${DoctorRepository.getTreatmentsForPatientAndDoctor(name, doctor.loginId).length} ครั้ง',
                  selected: false,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PatientHistoryPage(patientName: name),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPatientDetailCard(List<TreatmentHistoryItem> treatments) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff5fcfd),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffd8eef0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ผู้ป่วย $_selectedPatientName เคยกายภาพกับหมอคนไหนบ้าง',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xff114d58),
            ),
          ),
          const SizedBox(height: 10),
          if (treatments.isEmpty)
            const Text('ยังไม่มีประวัติการกายภาพในระบบ')
          else
            ...treatments.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _HistoryItem(
                  title: _doctorName(item.doctorLoginId),
                  subtitle: '${item.treatmentType} • ${item.dateIso}',
                  note: item.note,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _doctorName(String loginId) {
    final doctor = DoctorRepository.doctors.firstWhere(
      (item) => item.loginId == loginId,
      orElse: () =>
          const DoctorAccount(name: 'ไม่ทราบหมอ', email: '', loginId: ''),
    );
    return doctor.name;
  }

  Widget _buildProfileContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text(
              'โปรไฟล์แอดมิน',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xff114d58),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'จัดการข้อมูลส่วนตัว',
              style: TextStyle(fontSize: 13, color: Color(0xff5f8d93)),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1a3f7784),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xffe4fbfd),
                    ),
                    child: const CircleAvatar(
                      radius: 42,
                      backgroundColor: Color(0xffdef7f5),
                      child: Icon(
                        Icons.person_rounded,
                        size: 46,
                        color: Color(0xff159ea3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.adminName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff114d58),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ผู้ดูแลระบบ',
                    style: TextStyle(fontSize: 12, color: Color(0xff5b8a8f)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.adminEmail,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xff6f9da1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xffd8eef0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ข้อมูลส่วนตัว',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff154f58),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ProfileItem(label: 'ชื่อ-นามสกุล', value: widget.adminName),
                  const Divider(color: Color(0xffe7f2f3)),
                  const _ProfileItem(label: 'ตำแหน่ง', value: 'ผู้ดูแลระบบ'),
                  const Divider(color: Color(0xffe7f2f3)),
                  const _ProfileItem(
                    label: 'เบอร์โทรศัพท์',
                    value: '081-234-5678',
                  ),
                  const Divider(color: Color(0xffe7f2f3)),
                  _ProfileItem(label: 'อีเมล', value: widget.adminEmail),
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
                  _SettingItem(
                    label: 'เปลี่ยนรหัสผ่าน',
                    icon: Icons.lock_outline_rounded,
                    onTap: () {},
                  ),
                  const Divider(color: Color(0xffe7f2f3), height: 0),
                  _SettingItem(
                    label: 'การแจ้งเตือน',
                    icon: Icons.notifications_active_outlined,
                    trailing: Switch(
                      value: _notificationsEnabled,
                      activeThumbColor: const Color(0xff13a2ac),
                      onChanged: (value) =>
                          setState(() => _notificationsEnabled = value),
                    ),
                  ),
                  const Divider(color: Color(0xffe7f2f3), height: 0),
                  _SettingItem(
                    label: 'ภาษา',
                    icon: Icons.language_rounded,
                    trailing: const Text(
                      'ไทย',
                      style: TextStyle(color: Color(0xff4c7e83)),
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
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
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _selectedTab,
      children: [
        _buildHomeContent(),
        const AppointmentPage(),
        const HistoryPage(showBottomNav: false),
        _buildProfileContent(),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xfff4fbfb),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xffdfeef0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xff13a2ac), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xffe15b5b)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xffe15b5b), width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'กรุณากรอก $label';
        }
        if (label == 'อีเมลหมอ' && !value.contains('@')) {
          return 'กรุณากรอกอีเมลให้ถูกต้อง';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _loginIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fcfd),
      appBar: _selectedTab == 3
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xff155f68)),
                onPressed: () {},
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xff155f68),
                  ),
                  onPressed: () {},
                ),
              ],
            )
          : null,
      body: _buildBody(),
      bottomNavigationBar: Container(
        height: 76,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0f000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.home_rounded,
                label: 'หน้าแรก',
                active: _selectedTab == 0,
                onTap: () => _navigateTo(0),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.receipt_long_rounded,
                label: 'ประวัติ',
                active: _selectedTab == 2,
                onTap: () => _navigateTo(2),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.person_rounded,
                label: 'โปรไฟล์',
                active: _selectedTab == 3,
                onTap: () => _navigateTo(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xfff4ffff),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xff114d58), size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff114d58),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff5f8d93),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff9be3e1),
        foregroundColor: const Color(0xff114d58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(vertical: 24),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.hintText,
    required this.value,
    required this.onChanged,
  });

  final String hintText;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.search, color: Color(0xff13a2ac)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xffe6fbfc) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xff12aeb6) : const Color(0xffd8eef0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.person_outline_rounded,
              color: selected
                  ? const Color(0xff12aeb6)
                  : const Color(0xff6a8a8f),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff114d58),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xff6a8a8f),
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
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.title, required this.subtitle, this.note});

  final String title;
  final String subtitle;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffd8eef0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xff114d58),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xff5b8a8f)),
          ),
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'หมายเหตุ: $note',
              style: const TextStyle(fontSize: 11, color: Color(0xff6a8a8f)),
            ),
          ],
        ],
      ),
    );
  }
}

class DoctorDetailPage extends StatefulWidget {
  const DoctorDetailPage({super.key, required this.doctor});

  final DoctorAccount doctor;

  @override
  State<DoctorDetailPage> createState() => _DoctorDetailPageState();
}

class _DoctorDetailPageState extends State<DoctorDetailPage> {
  late DoctorAccount _doctor;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _doctor = widget.doctor;
  }

  Future<void> _editDoctor() async {
    final name = TextEditingController(text: _doctor.name);
    final email = TextEditingController(text: _doctor.email);
    final phone = TextEditingController(text: _doctor.phoneNumber);
    final loginId = TextEditingController(text: _doctor.loginId);
    final updated = await showDialog<DoctorAccount>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขข้อมูลหมอ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'ชื่อหมอ')),
              TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'อีเมล')),
              TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'เบอร์โทรศัพท์')),
              TextField(controller: loginId, decoration: const InputDecoration(labelText: 'รหัสหมอ')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              DoctorAccount(
                name: name.text.trim(),
                email: email.text.trim(),
                phoneNumber: phone.text.trim(),
                loginId: loginId.text.trim(),
              ),
            ),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
    name.dispose();
    email.dispose();
    phone.dispose();
    loginId.dispose();
    if (updated == null || updated.name.isEmpty || updated.loginId.isEmpty) return;

    setState(() => _saving = true);
    try {
      await DoctorRepository.updateDoctorAccount(
        previousLoginId: _doctor.loginId,
        doctor: updated,
      );
      if (mounted) {
        setState(() => _doctor = updated);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลหมอแล้ว')));
      }
    } on FirebaseException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลหมอไม่สำเร็จ')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteDoctor() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบข้อมูลหมอ?'),
        content: Text('ข้อมูลหมอ ตารางเวลา นัดหมาย และประวัติการรักษาของ ${_doctor.name} จะถูกลบออกจากฐานข้อมูล ไม่สามารถกู้คืนได้'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffd84d4d), foregroundColor: Colors.white),
            child: const Text('ลบข้อมูลหมอ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await DoctorRepository.deleteDoctorAccount(_doctor.loginId);
      if (mounted) Navigator.of(context).pop();
    } on FirebaseException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบข้อมูลหมอไม่สำเร็จ')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeffaf9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xff155f68),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'จัดการรายชื่อหมอ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xff114d58),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xffa9e6e3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xff7ccfd0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, size: 48, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DetailField(label: 'ชื่อ-สกุล', value: _doctor.name),
                  const SizedBox(height: 10),
                  _DetailField(label: 'รหัสล็อกอิน', value: _doctor.loginId),
                  const SizedBox(height: 10),
                  _DetailField(label: 'เมล', value: _doctor.email),
                  const SizedBox(height: 10),
                  _DetailField(label: 'เบอร์โทร', value: _doctor.phoneNumber.isEmpty ? '-' : _doctor.phoneNumber),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _editDoctor,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff9be3e1),
                      foregroundColor: const Color(0xff114d58),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('แก้ไข'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _deleteDoctor,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffff5b5b),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('ลบข้อมูลหมอ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 14, color: Color(0xff114d58)),
      ),
    );
  }
}

class PatientAccountPage extends StatefulWidget {
  const PatientAccountPage({super.key, required this.patient});

  final PatientRecord patient;

  @override
  State<PatientAccountPage> createState() => _PatientAccountPageState();
}

class _PatientAccountPageState extends State<PatientAccountPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.patient.email);
    _phoneController = TextEditingController(text: widget.patient.phone);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('กรุณาระบุอีเมลให้ถูกต้อง');
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.patient.id).set({
        'name': widget.patient.name,
        'email': email,
        'phone': _phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) _showMessage('บันทึกข้อมูลบัญชีแล้ว');
    } on FirebaseException {
      if (mounted) _showMessage('บันทึกข้อมูลไม่สำเร็จ กรุณาลองใหม่');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('กรุณาระบุอีเมลก่อนเปลี่ยนรหัสผ่าน');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) _showMessage('ส่งลิงก์ตั้งรหัสผ่านใหม่ไปที่ $email แล้ว');
    } on FirebaseAuthException {
      if (mounted) _showMessage('ส่งลิงก์ตั้งรหัสผ่านใหม่ไม่สำเร็จ');
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบบัญชีผู้เข้ารับการรักษา?'),
        content: Text(
          'ข้อมูลบัญชี การนัดหมาย และประวัติการรักษาของ ${widget.patient.name} จะถูกลบออกจากฐานข้อมูล ไม่สามารถกู้คืนได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffd84d4d),
              foregroundColor: Colors.white,
            ),
            child: const Text('ลบบัญชี'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await DoctorRepository.deletePatientAccount(
        patientId: widget.patient.id,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('ลบบัญชีผู้เข้ารับการรักษาแล้ว')),
      );
    } on FirebaseException {
      if (mounted) _showMessage('ลบบัญชีไม่สำเร็จ กรุณาลองใหม่');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: const Color(0xff155f68)),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xffeffaf9),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text('จัดการบัญชีผู้เข้ารับการรักษา'),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xffa9e6e3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_rounded, color: Color(0xff155f68)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.patient.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff114d58),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _decoration('อีเมล', Icons.email_outlined),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _decoration('เบอร์โทรศัพท์', Icons.phone_outlined),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('บันทึกการเปลี่ยนแปลง'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _sendPasswordReset,
            icon: const Icon(Icons.lock_reset_outlined),
            label: const Text('เปลี่ยนรหัสผ่าน'),
          ),
          const SizedBox(height: 10),
          const Text(
            'ระบบจะส่งลิงก์ตั้งรหัสผ่านใหม่ไปยังอีเมลของผู้เข้ารับการรักษา',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xff5b8a8f)),
          ),
          const SizedBox(height: 36),
          OutlinedButton.icon(
            onPressed: _saving ? null : _deleteAccount,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('ลบบัญชีผู้เข้ารับการรักษา'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xffc93f3f),
              side: const BorderSide(color: Color(0xffe19a9a)),
            ),
          ),
        ],
      ),
    ),
  );
}

class PatientHistoryPage extends StatefulWidget {
  const PatientHistoryPage({super.key, required this.patientName});

  final String patientName;

  @override
  State<PatientHistoryPage> createState() => _PatientHistoryPageState();
}

class _PatientHistoryPageState extends State<PatientHistoryPage> {
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final allTreatments = DoctorRepository.getTreatmentsForPatient(
      widget.patientName,
    );
    final filteredTreatments = allTreatments.where((item) {
      final search = _searchText.trim().toLowerCase();
      return search.isEmpty ||
          item.doctorLoginId.toLowerCase().contains(search) ||
          item.patientName.toLowerCase().contains(search) ||
          DoctorRepository.doctors
              .firstWhere(
                (doctor) => doctor.loginId == item.doctorLoginId,
                orElse: () =>
                    const DoctorAccount(name: '', email: '', loginId: ''),
              )
              .name
              .toLowerCase()
              .contains(search);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xffeffaf9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xff155f68),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'ประวัติผู้ป่วย',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xff114d58),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xffa9e6e3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ประวัติการรักษา',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff114d58),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.patientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff114d58),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SearchInput(
                    hintText: 'ค้นหาชื่อผู้ป่วยหรือหมอที่รักษา',
                    value: _searchText,
                    onChanged: (value) => setState(() => _searchText = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: filteredTreatments.isEmpty
                  ? Center(
                      child: Text(
                        'ไม่พบประวัติสำหรับผู้ป่วย ${widget.patientName}',
                        style: const TextStyle(color: Color(0xff5b8a8f)),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredTreatments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filteredTreatments[index];
                        final doctor = DoctorRepository.doctors.firstWhere(
                          (doctor) => doctor.loginId == item.doctorLoginId,
                          orElse: () => const DoctorAccount(
                            name: 'ไม่ทราบหมอ',
                            email: '',
                            loginId: '',
                          ),
                        );
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PatientTreatmentDetailPage(
                                  treatment: item,
                                  doctorName: doctor.name,
                                ),
                              ),
                            );
                          },
                          child: _HistoryItem(
                            title: 'หมอ ${doctor.name}',
                            subtitle:
                                '${item.treatmentType} • ${item.bodyPart} • ${item.setCount} เซ็ต • ${item.dateIso}',
                            note: item.note,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientTreatmentDetailPage extends StatelessWidget {
  const PatientTreatmentDetailPage({
    super.key,
    required this.treatment,
    required this.doctorName,
  });

  final TreatmentHistoryItem treatment;
  final String doctorName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeffaf9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xff155f68),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'ข้อมูลผู้ป่วย',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xff114d58),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xffa9e6e3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xff7ccfd0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, size: 48, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DetailField(
                    label: 'ชื่อผู้ป่วย',
                    value: treatment.patientName,
                  ),
                  const SizedBox(height: 10),
                  _DetailField(label: 'หมอที่รักษา', value: doctorName),
                  const SizedBox(height: 10),
                  _DetailField(label: 'วันที่', value: treatment.dateIso),
                  const SizedBox(height: 10),
                  _DetailField(
                    label: 'กายภาพส่วนไหน',
                    value: treatment.bodyPart,
                  ),
                  const SizedBox(height: 10),
                  _DetailField(
                    label: 'จำนวนเซ็ต',
                    value: '${treatment.setCount} เซ็ต',
                  ),
                  const SizedBox(height: 10),
                  _DetailField(
                    label: 'ประเภทการรักษา',
                    value: treatment.treatmentType,
                  ),
                  if (treatment.note != null && treatment.note!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _DetailField(label: 'หมายเหตุ', value: treatment.note!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff9be3e1),
                  foregroundColor: const Color(0xff114d58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('กลับ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorInfoRow extends StatelessWidget {
  const _DoctorInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xff67888c),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xff114d58)),
          ),
        ),
      ],
    );
  }
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xff67888c)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
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

class _SettingItem extends StatelessWidget {
  const _SettingItem({
    required this.label,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final trailingWidget = trailing;

    final trailingWidgets = trailingWidget != null
        ? [trailingWidget]
        : const <Widget>[];

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xff159ea3)),
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
            ...trailingWidgets,
            const SizedBox(width: 4),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xff9bb7bb),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? const Color(0xff13a2ac) : const Color(0xff7b9da1),
              size: 24,
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
    );
  }
}
