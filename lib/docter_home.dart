import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'appointment.dart';
import 'doctor_repository.dart';
import 'history.dart';

class DocterHomePage extends StatefulWidget {
  const DocterHomePage({
    super.key,
    required this.adminName,
    required this.adminEmail,
  });

  final String adminName;
  final String adminEmail;

  @override
  State<DocterHomePage> createState() => _DocterHomePageState();
}

class _DocterHomePageState extends State<DocterHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _loginIdController = TextEditingController();

  bool _notificationsEnabled = true;
  int _selectedTab = 0;

  void _navigateTo(int index) {
    setState(() => _selectedTab = index);
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _loginIdController.clear();
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
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text(
              'หน้าหลักแอดมิน',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xff114d58),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'เพิ่มข้อมูลหมอที่ใช้ล็อกอินเข้าสู่ระบบด้วยอีเมลและรหัสล็อกอิน',
              style: TextStyle(fontSize: 13, color: Color(0xff5f8d93)),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xffd8eef0)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'เพิ่มรายชื่อหมอ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff114d58),
                      ),
                    ),
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _addDoctor,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: const Color(0xff13a2ac),
                        ),
                        child: const Text(
                          'เพิ่มหมอ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'รายการหมอ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xff114d58),
              ),
            ),
            const SizedBox(height: 12),
            ...DoctorRepository.doctors.map(
              (doctor) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _DoctorAvailabilityCard(doctor: doctor),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
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

class _DoctorAvailabilityCard extends StatelessWidget {
  const _DoctorAvailabilityCard({required this.doctor});

  final DoctorAccount doctor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffd8eef0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff114d58),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'รหัสล็อกอิน',
                      style: TextStyle(fontSize: 12, color: Color(0xff5f8d93)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffe0fbf9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'ว่าง',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff12aeb6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DoctorInfoRow(label: 'รหัสล็อกอิน', value: doctor.loginId),
          const SizedBox(height: 8),
          _DoctorInfoRow(label: 'อีเมล', value: doctor.email),
        ],
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
