import 'package:flutter/material.dart';
import 'appointment.dart';
import 'history.dart';

void main() => runApp(const QueueApp());

class QueueApp extends StatelessWidget {
  const QueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARM Physical Therapy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff12aeb6)),
        fontFamily: 'Tahoma',
      ),
      home: const QueueHomePage(),
    );
  }
}

class QueueHomePage extends StatefulWidget {
  const QueueHomePage({super.key});

  @override
  State<QueueHomePage> createState() => _QueueHomePageState();
}

class _QueueHomePageState extends State<QueueHomePage> {
  int _selectedTab = 0;
  String _queue = '0001';

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xff10aeb5);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 370;

    return Scaffold(
      backgroundColor: const Color(0xfff7fcfd),
      body: Stack(
        children: [
          const _HeaderBackground(),
          SafeArea(
            child: Column(
              children: [
                _TopBar(compact: compact),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: _QueueCard(
                        queue: _queue,
                        onConfirm: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AppointmentPage()),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNavigation(
        selectedIndex: _selectedTab,
        onTap: (value) {
          if (value == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            );
            return;
          }
          setState(() => _selectedTab = value);
        },
        color: teal,
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
          borderRadius: BorderRadius.vertical(bottom: Radius.elliptical(220, 75)),
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
  const _TopBar({required this.compact});
  final bool compact;

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
            child: const Icon(Icons.accessibility_new_rounded, color: Color(0xff16adb5), size: 23),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ออมรักษาสุขภาพบ้านชุมชน',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: compact ? 10 : 11, fontWeight: FontWeight.w700, color: const Color(0xff27828b))),
                const Text('ARM PHYSICAL THERAPY', style: TextStyle(fontSize: 7.5, letterSpacing: .2, color: Color(0xff6e9ca1))),
              ],
            ),
          ),
          Container(
            height: 34,
            width: 34,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.notifications_none_rounded, color: Color(0xff159fa8), size: 21),
          ),
        ],
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.queue, required this.onConfirm});
  final String queue;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
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
            const _DetailsTile(icon: Icons.calendar_month_outlined, title: 'วันที่', subtitle: 'เลือกวันที่เข้ารับบริการ'),
            const SizedBox(height: 6),
            const _DetailsTile(icon: Icons.access_time_rounded, title: 'เวลา', subtitle: 'เลือกเวลาที่ต้องการ', hasArrow: true),
            const SizedBox(height: 6),
            const _DetailsTile(icon: Icons.location_on_rounded, title: 'สถานที่', subtitle: 'เลือกสาขาที่ใช้บริการ', hasArrow: true),
            const SizedBox(height: 10),
            SizedBox(
              height: 47,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onConfirm,
                icon: const Icon(Icons.verified_user_outlined, size: 22),
                label: const Text('ยืนยันการจองคิว', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xff11b1b7),
                  elevation: 4,
                  shadowColor: const Color(0x664ebbc0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                ),
              ),
            ),
            const SizedBox(height: 9),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('กรุณามาก่อนเวลานัดหมาย 15 นาที', style: TextStyle(fontSize: 8.5, color: Color(0xff557d82))),
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
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xff42b8bf)),
            child: const Icon(Icons.person_rounded, size: 43, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Color(0xff173f45))),
                Text('ยินดีต้อนรับ', style: TextStyle(fontSize: 10, color: Color(0xff82a0a5))),
                SizedBox(height: 2),
                Row(children: [Icon(Icons.verified_user_outlined, size: 11, color: Color(0xff14abb3)), SizedBox(width: 3), Text('ข้อมูลผู้ใช้งานเป็นปัจจุบัน', style: TextStyle(fontSize: 8, color: Color(0xff5b8c91)))]),
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
            const Expanded(child: Text('คิว', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: Color(0xff146c74)))),
            Container(height: 45, width: 1, color: const Color(0xffb7e5e7)),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(queue, style: const TextStyle(fontSize: 43, height: .95, fontWeight: FontWeight.w800, letterSpacing: 2, color: Color(0xff087f87))),
                  const SizedBox(height: 5),
                  const Text('กรุณามาตามเวลานัด', style: TextStyle(fontSize: 7.5, color: Color(0xff57848a))),
                ],
              ),
            ),
          ],
        ),
      );
}

class _DetailsTile extends StatelessWidget {
  const _DetailsTile({required this.icon, required this.title, required this.subtitle, this.hasArrow = true});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool hasArrow;

  @override
  Widget build(BuildContext context) => Container(
        height: 49,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xffd8eef0))),
        child: Row(
          children: [
            Container(
              height: 29,
              width: 29,
              decoration: const BoxDecoration(color: Color(0xffe8fafa), shape: BoxShape.circle),
              child: Icon(icon, color: const Color(0xff1aaab3), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xff386d73))), Text(subtitle, style: const TextStyle(fontSize: 7.5, color: Color(0xff82a2a6)))])),
            if (hasArrow) const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xff139da7)),
          ],
        ),
      );
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.selectedIndex, required this.onTap, required this.color});
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const items = [(Icons.home_rounded, 'หน้าหลัก'), (Icons.calendar_month_outlined, 'จองคิว'), (Icons.assignment_outlined, 'ประวัติ'), (Icons.person_outline_rounded, 'บัญชีผู้ใช้')];
    return Container(
      height: 65,
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x120d7b82), blurRadius: 10, offset: Offset(0, -2))]),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = i == selectedIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(i),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(items[i].$1, size: 23, color: active ? color : const Color(0xff72999e)), const SizedBox(height: 3), Text(items[i].$2, style: TextStyle(fontSize: 8, color: active ? color : const Color(0xff72999e), fontWeight: active ? FontWeight.w700 : FontWeight.w400))]),
            ),
          );
        }),
      ),
    );
  }
}
