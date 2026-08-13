import 'package:firebase_auth/firebase_auth.dart';
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
  }

  void _switchAdminMode(AdminMode mode) {
    setState(() {
      _adminMode = mode;
      _selectedDoctorLoginId = null;
      _selectedPatientName = null;
      _doctorSearch = '';
    });
  }

  void _addDoctor() {
    if (!_formKey.currentState!.validate()) return;

    final doctor = DoctorAccount(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      loginId: _loginIdController.text.trim(),
    );

    setState(() {
      DoctorRepository.addDoctor(doctor);
    });

    _clearForm();
    Navigator.of(context).pop();
  }

  Future<void> _showAddDoctorDialog() async {
    _clearForm();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มข้อมูลหมอ'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'ชื่อหมอ',
                hintText: 'เช่น นพ. สมชาย นาคมศักดิ์',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _emailController,
                label: 'อีเมลหมอ',
                hintText: 'เช่น doctor@example.com',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _loginIdController,
                label: 'รหัสล็อกอินหมอ',
                hintText: 'เช่น doc1001',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(onPressed: _addDoctor, child: const Text('เพิ่มหมอ')),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'จัดการรายชื่อ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xff114d58),
              ),
            ),
            const SizedBox(height: 18),
            _AdminActionCard(
              label: 'จัดการรายชื่อหมอ',
              onTap: () => _switchAdminMode(AdminMode.doctor),
            ),
            const SizedBox(height: 16),
            _AdminActionCard(
              label: 'จัดการรายชื่อผู้ป่วย',
              onTap: () => _switchAdminMode(AdminMode.patient),
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
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DoctorDetailPage(
                                  doctor: doctor,
                                  onDelete: () {
                                    setState(() {
                                      DoctorRepository.removeDoctor(
                                        doctor.loginId,
                                      );
                                      _selectedDoctorLoginId = null;
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                            );
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
    final patients = DoctorRepository.getPatientNames();
    final patientSearch = _doctorSearch.trim().toLowerCase();
    final matchingDoctors = patientSearch.isEmpty
        ? const <DoctorAccount>[]
        : DoctorRepository.doctors
              .where(
                (doctor) => doctor.name.toLowerCase().contains(patientSearch),
              )
              .toList();
    final filteredPatients = patients.where((name) {
      if (patientSearch.isEmpty) return true;
      if (name.toLowerCase().contains(patientSearch)) return true;
      return DoctorRepository.getTreatmentsForPatient(name).any((treatment) {
        final doctorName = DoctorRepository.doctors
            .firstWhere(
              (doctor) => doctor.loginId == treatment.doctorLoginId,
              orElse: () =>
                  const DoctorAccount(name: '', email: '', loginId: ''),
            )
            .name
            .toLowerCase();
        return doctorName.contains(patientSearch);
      });
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
                    'ประวัติการรักษา',
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
              hintText: 'ค้นหาชื่อผู้ป่วยหรือชื่อหมอ',
              value: _doctorSearch,
              onChanged: (value) => setState(() => _doctorSearch = value),
            ),
          ),
          const SizedBox(height: 12),
          if (matchingDoctors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final doctor in matchingDoctors) ...[
                    _buildDoctorDetailCard(doctor),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xffd8f3f2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: filteredPatients.isEmpty
                  ? const Center(
                      child: Text(
                        'ไม่พบผู้ป่วยที่ค้นหา',
                        style: TextStyle(color: Color(0xff5b8a8f)),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredPatients.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final patient = filteredPatients[index];
                        return _SelectionTile(
                          title: patient,
                          subtitle:
                              'เคยกายภาพกับ ${DoctorRepository.getTreatmentsForPatient(patient).length} หมอ',
                          selected: false,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PatientHistoryPage(patientName: patient),
                              ),
                            );
                          },
                        );
                      },
                    ),
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
                'เลือกผู้ป่วยเพื่อดูประวัติการรักษาแบบแยกหน้าจอ พร้อมค้นหาด้วยชื่อผู้ป่วยหรือชื่อหมอที่รักษา',
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
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xfff6fdfe),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
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
        height: 74,
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
                icon: Icons.home_outlined,
                label: 'หน้าหลัก',
                active: _selectedTab == 0,
                onTap: () => _navigateTo(0),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.calendar_month_outlined,
                label: 'จัดการคิว',
                active: _selectedTab == 1,
                onTap: () => _navigateTo(1),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.assignment_rounded,
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

class DoctorDetailPage extends StatelessWidget {
  const DoctorDetailPage({
    super.key,
    required this.doctor,
    required this.onDelete,
  });

  final DoctorAccount doctor;
  final VoidCallback onDelete;

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
                  _DetailField(label: 'ชื่อ-สกุล', value: doctor.name),
                  const SizedBox(height: 10),
                  _DetailField(label: 'รหัสล็อกอิน', value: doctor.loginId),
                  const SizedBox(height: 10),
                  _DetailField(label: 'เมล', value: doctor.email),
                  const SizedBox(height: 10),
                  _DetailField(label: 'เบอร์โทร', value: '081-234-5678'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
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
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onDelete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffff5b5b),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('ลบ'),
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
