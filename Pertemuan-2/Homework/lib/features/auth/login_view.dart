// login_view.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logbook_app_079/features/auth/login_controller.dart';
import 'package:logbook_app_079/features/logbook/counter_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _obscure = true;
  String? _userError;
  String? _passError;

  // ===== COOLDOWN =====
  int _cooldown = 0;
  Timer? _timer;

  void _startCooldown() {
    setState(() => _cooldown = 10);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _cooldown--);
      if (_cooldown <= 0) {
        t.cancel();
        _controller.resetAttempts();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  // ===== HANDLE LOGIN =====
  void _handleLogin() {
    final user = _userController.text.trim();
    final pass = _passController.text;

    // Validasi kosong
    setState(() {
      _userError = user.isEmpty ? "Username tidak boleh kosong" : null;
      _passError = pass.isEmpty ? "Password tidak boleh kosong" : null;
    });
    if (_userError != null || _passError != null) return;

    if (_controller.login(user, pass)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CounterView(username: user)),
      );
    } else {
      // Cek apakah baru mencapai batas
      if (_controller.isLocked) _startCooldown();

      setState(() => _passError = "Username atau password salah "
          "(${_controller.attempts}/${LoginController.maxAttempts})");
    }
  }

  // ===== INPUT DECORATION =====
  InputDecoration _inputStyle(String label, IconData icon, String? error) =>
      InputDecoration(
        labelText: label,
        errorText: error,
        prefixIcon: Icon(icon, color: Colors.blue),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isLocked = _controller.isLocked && _cooldown > 0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // ===== LOGO - GANTI JADI IMAGE =====
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/loginpage.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text("Logbook App", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("Masuk untuk melanjutkan", style: TextStyle(color: Colors.grey.shade500)),
                const SizedBox(height: 36),

                // ===== USERNAME =====
                TextField(
                  controller: _userController,
                  enabled: !isLocked,
                  onChanged: (_) => setState(() => _userError = null),
                  decoration: _inputStyle("Username", Icons.person_outline, _userError),
                ),

                const SizedBox(height: 14),

                // ===== PASSWORD =====
                TextField(
                  controller: _passController,
                  obscureText: _obscure,
                  enabled: !isLocked,
                  onChanged: (_) => setState(() => _passError = null),
                  decoration: _inputStyle("Password", Icons.lock_outline, _passError).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ===== COOLDOWN WARNING =====
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(children: [
                      Icon(Icons.lock_clock, color: Colors.red.shade400, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Terlalu banyak percobaan. Coba lagi dalam $_cooldown detik",
                        style: TextStyle(color: Colors.red.shade600, fontSize: 13),
                      ),
                    ]),
                  ),

                // ===== LOGIN BUTTON =====
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLocked ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                    ),
                    child: Text(
                      isLocked ? "Tunggu $_cooldown detik..." : "Masuk",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Text("Hint: admin/123 · user1/pass1 · user2/pass2",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}