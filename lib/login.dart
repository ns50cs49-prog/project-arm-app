import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'doctor_page.dart';
import 'admin_home.dart';
import 'doctor_repository.dart';
import 'patient_home.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

const _adminEmail = 'raddawan3079@gmail.com';

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกอีเมลและรหัสผ่าน')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final doctor = await DoctorRepository.findDoctorAccount(email, password);
      if (doctor != null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DoctorPage(doctor: doctor)),
        );
        return;
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      if (email.trim().toLowerCase() == _adminEmail) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                AdminHomePage(adminName: 'Admin', adminEmail: email),
          ),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PatientHomePage()),
      );
      return;
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'invalid-email' => 'รูปแบบอีเมลไม่ถูกต้อง',
        'user-not-found' => 'ไม่พบบัญชีผู้ใช้นี้',
        'wrong-password' ||
        'invalid-credential' => 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
        'network-request-failed' => 'เชื่อมต่ออินเทอร์เน็ตไม่สำเร็จ',
        _ => 'เข้าสู่ระบบไม่สำเร็จ กรุณาลองใหม่',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff7fcfd),
    body: Stack(
      children: [
        const _Backdrop(),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(13),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(23, 28, 23, 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .91),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: const Color(0xffd2eff0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x15369ea5),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Brand(),
                      const SizedBox(height: 16),
                      _Input(
                        controller: _emailController,
                        icon: Icons.person_rounded,
                        hint: 'อีเมล',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      _Input(
                        controller: _passwordController,
                        icon: Icons.lock_rounded,
                        hint: 'รหัสผ่าน',
                        obscureText: _hidePassword,
                        trailing: IconButton(
                          splashRadius: 18,
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 19,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.only(top: 5, bottom: 6),
                          ),
                          child: const Text(
                            'ลืมรหัสผ่าน?',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xff178d97),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xff1cc2c9), Color(0xff0d93a0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x3313aeb7),
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _isLoading ? null : _login,
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.input_rounded,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'เข้าสู่ระบบ',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'ยังไม่มีบัญชี?',
                            style: TextStyle(fontSize: 10),
                          ),
                          TextButton(
                            onPressed: () async {
                              final registered = await Navigator.of(context)
                                  .push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterPage(),
                                    ),
                                  );
                              if (registered == true && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'สมัครสมาชิกสำเร็จ กรุณาเข้าสู่ระบบ',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text('สมัครสมาชิก'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 13,
                            color: Color(0xff72a9ae),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'ข้อมูลของคุณปลอดภัย 100%',
                            style: TextStyle(
                              fontSize: 8.5,
                              color: Color(0xff71969a),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffd9f7f8), Color(0xfff9ffff), Color(0xffd9f5f6)],
          ),
        ),
      ),
      const Positioned(
        top: 25,
        right: 22,
        child: Icon(Icons.add, color: Color(0xff42c4cb), size: 32),
      ),
      const Positioned(
        top: 40,
        right: 55,
        child: Icon(Icons.add, color: Color(0xff80dce0), size: 15),
      ),
      const Positioned(
        bottom: 50,
        right: 19,
        child: Icon(
          Icons.monitor_heart_outlined,
          size: 52,
          color: Color(0x3373cfd3),
        ),
      ),
      const Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Icon(
          Icons.monitor_heart_outlined,
          size: 80,
          color: Color(0x3373cfd3),
        ),
      ),
    ],
  );
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 86,
        width: 86,
        child: ClipOval(
          child: Image.asset(
            'assets/icon/app_icon.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
      const Text(
        'ARM ReMotion',
        style: TextStyle(
          fontSize: 27,
          height: 1,
          fontWeight: FontWeight.w800,
          color: Color(0xff075e67),
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'ระบบเช็คสถานะเครื่องและจองคิว',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: Color(0xff159ca5),
        ),
      ),
      const SizedBox(height: 2),
      const Text(
        'ARM PHYSICAL THERAPY',
        style: TextStyle(
          fontSize: 7,
          letterSpacing: .55,
          color: Color(0xff78a9ad),
        ),
      ),
    ],
  );
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.icon,
    required this.hint,
    this.obscureText = false,
    this.trailing,
    this.keyboardType,
  });
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool obscureText;
  final Widget? trailing;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 11, color: Color(0xff8ba9ad)),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xff1babb4)),
      suffixIcon: trailing,
      filled: true,
      fillColor: const Color(0xffeef9fa),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xff14adb6), width: 1.6),
      ),
    ),
  );
}
