import 'package:flutter/material.dart';

class AppointmentPage extends StatelessWidget {
  const AppointmentPage({super.key, this.id, this.data});

  final String? id;
  final Map<String, dynamic>? data;

  factory AppointmentPage.fromMap({required String id, required Map<String, dynamic> data}) => AppointmentPage(id: id, data: data);

  @override
  Widget build(BuildContext context) {
    final queue = data?['queue']?.toString() ?? '0001';
    final dateRaw = data?['date'] as String?;
    final date = dateRaw != null ? DateTime.tryParse(dateRaw) : null;
    final dateText = date != null ? '${date.day} ${_thaiMonth(date.month)} ${date.year + 543}' : 'ไม่ระบุวันที่';
    final time = data?['time']?.toString() ?? 'ไม่ระบุเวลา';
    final location = data?['location']?.toString() ?? 'ARM ReMotion Physical Therapy Clinic';
    final doctorName = data?['doctorName']?.toString() ?? 'ไม่ระบุแพทย์';
    final displayName = (data?['displayName'] as String?)?.trim();
    final email = (data?['email'] as String?)?.trim();
    final patientName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (email != null && email.isNotEmpty)
        ? email
        : 'ผู้ป่วย';

    return Scaffold(
      backgroundColor: const Color(0xfff7fcfd),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.chevron_left_rounded, color: Color(0xff168d96))),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('นัดหมายของฉัน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xff155a62))), Text('รายละเอียดการนัดหมายกายภาพบำบัด', style: TextStyle(fontSize: 8.5, color: Color(0xff72979b)))]),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.notifications_none_rounded, color: Color(0xff159da7)))],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(children: [
              Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x123a9da2), blurRadius: 12, offset: Offset(0, 4))]), child: const Column(children: [CircleAvatar(radius: 31, backgroundColor: Color(0xffdef7f5), child: Icon(Icons.check_circle_rounded, size: 48, color: Color(0xff14aa9d))), SizedBox(height: 12), Text('จองคิวสำเร็จ', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Color(0xff17616a))), SizedBox(height: 5), Text('เราได้บันทึกนัดหมายของคุณเรียบร้อยแล้ว', style: TextStyle(fontSize: 10, color: Color(0xff6d999d)))])),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xffd8eff1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('รายละเอียดนัดหมาย', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xff215b62))), const SizedBox(height: 14), _AppointmentRow(icon: Icons.confirmation_number_outlined, title: 'หมายเลขคิว', value: queue), const Divider(height: 19, color: Color(0xffe5f1f2)), _AppointmentRow(icon: Icons.medical_services_outlined, title: 'แพทย์', value: doctorName), const Divider(height: 19, color: Color(0xffe5f1f2)), _AppointmentRow(icon: Icons.person_outline_rounded, title: 'ผู้ป่วย', value: patientName), const Divider(height: 19, color: Color(0xffe5f1f2)), _AppointmentRow(icon: Icons.calendar_month_outlined, title: 'วันนัดหมาย', value: dateText), const Divider(height: 19, color: Color(0xffe5f1f2)), _AppointmentRow(icon: Icons.access_time_rounded, title: 'เวลา', value: time), const Divider(height: 19, color: Color(0xffe5f1f2)), _AppointmentRow(icon: Icons.location_on_outlined, title: 'สถานที่', value: location) ])),
              const SizedBox(height: 15),
              const Text('กรุณามาก่อนเวลานัดหมาย 15 นาที', style: TextStyle(fontSize: 10, color: Color(0xff668d92))),
            ]),
          ),
        ),
      ),
    );
  }

  static String _thaiMonth(int m) {
    const months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
    return months[(m - 1).clamp(0, 11)];
  }
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Row(children: [Container(height: 32, width: 32, decoration: const BoxDecoration(color: Color(0xffe9fafb), shape: BoxShape.circle), child: Icon(icon, size: 18, color: const Color(0xff16a7b0))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 9, color: Color(0xff70979b))), const SizedBox(height: 2), Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xff285e65)))]))]);
}
