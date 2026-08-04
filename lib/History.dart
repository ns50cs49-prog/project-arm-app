import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    const tabs = ['ทั้งหมด', 'กำลังมาถึง', 'เสร็จสิ้นแล้ว', 'ยกเลิกแล้ว'];
    final appointments = <_Appointment>[
      const _Appointment(month: 'พ.ค.', day: '14', year: '2567', time: '09:00 น.', status: 'ยืนยันแล้ว', state: _State.confirmed),
      const _Appointment(month: 'เม.ย.', day: '30', year: '2567', time: '10:00 น.', status: 'เสร็จสิ้นแล้ว', state: _State.completed),
      const _Appointment(month: 'เม.ย.', day: '18', year: '2567', time: '11:00 น.', status: 'ยกเลิก', state: _State.cancelled),
    ];
    final visible = _tab == 0 ? appointments : appointments.where((item) => item.state.index == _tab - 1).toList();

    return Scaffold(
      backgroundColor: const Color(0xfff8fcfd),
      body: SafeArea(
        child: Column(
          children: [
            const _HistoryHeader(),
            const _MemberCard(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: SizedBox(
                height: 32,
                child: Row(
                  children: List.generate(tabs.length, (index) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index == tabs.length - 1 ? 0 : 7),
                      child: _HistoryTab(label: tabs[index], selected: _tab == index, onTap: () => setState(() => _tab = index)),
                    ),
                  )),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: visible.length,
                itemBuilder: (context, index) => _AppointmentCard(appointment: visible[index]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _HistoryNavigation(),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0d246c70), blurRadius: 5, offset: Offset(0, 2))]),
        child: Row(children: [
          IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.chevron_left_rounded, color: Color(0xff167f88))),
          const SizedBox(width: 2),
          const Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ประวัติการกายภาพบำบัด', style: TextStyle(fontSize: 15, height: 1, fontWeight: FontWeight.w700, color: Color(0xff155a62))), SizedBox(height: 4), Text('ตรวจสอบประวัติการรักษากายภาพบำบัด', style: TextStyle(fontSize: 8.5, color: Color(0xff72979b)))])),
          const Icon(Icons.notifications_none_rounded, color: Color(0xff159da7), size: 23),
        ]),
      );
}

class _MemberCard extends StatelessWidget {
  const _MemberCard();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0d246c70), blurRadius: 7, offset: Offset(0, 2))]),
        child: Row(children: [
          const CircleAvatar(radius: 25, backgroundColor: Color(0xff3bb6be), child: Icon(Icons.person_rounded, size: 42, color: Colors.white)),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('User', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xff1c535a))), SizedBox(height: 2), Text('หมายเลขคิว 0001', style: TextStyle(fontSize: 9, color: Color(0xff527d83))), SizedBox(height: 3), Row(children: [Icon(Icons.verified_user_outlined, size: 11, color: Color(0xff16a8b1)), SizedBox(width: 3), Text('ข้อมูลของคุณเป็นปัจจุบัน', style: TextStyle(fontSize: 8, color: Color(0xff5c9095)))])])),
          const Icon(Icons.chevron_right_rounded, color: Color(0xff198b95)),
        ]),
      );
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? const Color(0xff0ca8b0) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: selected ? const Color(0xff0ca8b0) : const Color(0xffe0eef0))),
            child: Text(label, style: TextStyle(fontSize: 8.5, color: selected ? Colors.white : const Color(0xff588087), fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
          ),
        ),
      );
}

enum _State { confirmed, completed, cancelled }

class _Appointment {
  const _Appointment({required this.month, required this.day, required this.year, required this.time, required this.status, required this.state});
  final String month;
  final String day;
  final String year;
  final String time;
  final String status;
  final _State state;
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});
  final _Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final (icon, section, color, background) = switch (appointment.state) {
      _State.confirmed => (Icons.calendar_month_rounded, 'กำลังจะมาถึง', const Color(0xff118c96), const Color(0xffe4f7f0)),
      _State.completed => (Icons.check_circle_rounded, 'เสร็จสิ้นแล้ว', const Color(0xff0d9984), const Color(0xffe1f6ed)),
      _State.cancelled => (Icons.cancel_rounded, 'ยกเลิกแล้ว', const Color(0xffe64051), const Color(0xffffe8eb)),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11), boxShadow: const [BoxShadow(color: Color(0x0b246c70), blurRadius: 6, offset: Offset(0, 2))]),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 7),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 5), Text(section, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))]),
          const SizedBox(height: 7),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _DateBox(appointment: appointment),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.access_time_rounded, size: 13, color: Color(0xff21a5ae)), const SizedBox(width: 4), Text(appointment.time, style: const TextStyle(fontSize: 9, color: Color(0xff376f76)))]),
              const SizedBox(height: 3),
              const Row(children: [Icon(Icons.local_hospital_outlined, size: 12, color: Color(0xff21a5ae)), SizedBox(width: 4), Text('กายภาพบำบัด', style: TextStyle(fontSize: 8.5, color: Color(0xff578088)))]),
              const SizedBox(height: 3),
              const Text('Arm care Physical Therapy Clinic', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: Color(0xff376f76))),
              const SizedBox(height: 2),
              const Row(children: [Icon(Icons.location_on_outlined, size: 11, color: Color(0xff6e9ca1)), SizedBox(width: 3), Text('ชั้น 2 จุดบริการ Arm care', style: TextStyle(fontSize: 7.5, color: Color(0xff6e9ca1)))]),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)), child: Text(appointment.status, style: TextStyle(fontSize: 7.5, color: color, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 7),
          const Text('รายการรักษากายภาพบำบัด', style: TextStyle(fontSize: 7.5, color: Color(0xff527e84))),
          const SizedBox(height: 4),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_Treatment(icon: Icons.accessibility_new_rounded, label: 'ยืดกล้ามเนื้อ'), _Treatment(icon: Icons.spa_outlined, label: 'อัลตราซาวด์'), _Treatment(icon: Icons.back_hand_outlined, label: 'นวดบำบัด')]),
          const SizedBox(height: 6),
          Container(height: 22, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: const Color(0xfff8fcfd), borderRadius: BorderRadius.circular(6)), child: const Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('รายละเอียด', style: TextStyle(fontSize: 8, color: Color(0xff4a7b82))), SizedBox(width: 4), Icon(Icons.chevron_right_rounded, size: 15, color: Color(0xff159da7))])),
        ]),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.appointment});
  final _Appointment appointment;

  @override
  Widget build(BuildContext context) => Container(width: 55, padding: const EdgeInsets.symmetric(vertical: 5), decoration: BoxDecoration(color: const Color(0xfff1fbfc), borderRadius: BorderRadius.circular(5)), child: Column(children: [Text(appointment.month, style: const TextStyle(fontSize: 8, color: Color(0xff487c83))), Text(appointment.day, style: const TextStyle(fontSize: 24, height: .85, fontWeight: FontWeight.w700, color: Color(0xff126975))), const SizedBox(height: 4), Text(appointment.year, style: const TextStyle(fontSize: 8, color: Color(0xff487c83)))]));
}

class _Treatment extends StatelessWidget {
  const _Treatment({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, size: 16, color: const Color(0xff65bfc4)), const SizedBox(width: 3), Text(label, style: const TextStyle(fontSize: 7.5, color: Color(0xff62898e)))]);
}

class _HistoryNavigation extends StatelessWidget {
  const _HistoryNavigation();

  @override
  Widget build(BuildContext context) => Container(height: 59, decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x120d7b82), blurRadius: 8, offset: Offset(0, -2))]), child: const Row(children: [Expanded(child: _Nav(icon: Icons.home_outlined, label: 'หน้าหลัก')), Expanded(child: _Nav(icon: Icons.calendar_month_outlined, label: 'จองคิว')), Expanded(child: _Nav(icon: Icons.assignment_rounded, label: 'ประวัติ', active: true)), Expanded(child: _Nav(icon: Icons.person_outline_rounded, label: 'บัญชีผู้ใช้'))]));
}

class _Nav extends StatelessWidget {
  const _Nav({required this.icon, required this.label, this.active = false});
  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 21, color: active ? const Color(0xff0fa8b0) : const Color(0xff70969b)), const SizedBox(height: 2), Text(label, style: TextStyle(fontSize: 7.5, color: active ? const Color(0xff0fa8b0) : const Color(0xff70969b), fontWeight: active ? FontWeight.w700 : FontWeight.w400))]);
}
