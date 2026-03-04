import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logbook_app_079/features/auth/login_controller.dart';
import 'package:logbook_app_079/features/logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _controller = LoginController();
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  bool _obscure = true;
  String? _userError;
  String? _passError;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

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

  void _handleLogin() {
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;

    setState(() {
      _userError = user.isEmpty ? "Username tidak boleh kosong" : null;
      _passError = pass.isEmpty ? "Password tidak boleh kosong" : null;
    });

    if (_userError != null || _passError != null) return;

    if (_controller.login(user, pass)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LogView(username: user)),
      );
    } else {
      if (_controller.isLocked) _startCooldown();
      setState(() => _passError =
          "Username atau password salah (${_controller.attempts}/${LoginController.maxAttempts})");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = _controller.isLocked && _cooldown > 0;

    return Scaffold(
      body: Container(
        // Background gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A5F), Color(0xFF2C5F8A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              // ===== LOGO & JUDUL =====
              const Spacer(),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 3),
                ),
                child: ClipOval(
                  child: Image.asset('assets/images/loginpage.jpg', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Logbook App",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Catat aktivitas harianmu",
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const Spacer(),

              // ===== FORM CARD =====
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Masuk", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // USERNAME
                    TextField(
                      controller: _userCtrl,
                      enabled: !isLocked,
                      decoration: _inputDecor("Username", Icons.person_outline, _userError),
                    ),
                    const SizedBox(height: 14),

                    // PASSWORD
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      enabled: !isLocked,
                      decoration: _inputDecor("Password", Icons.lock_outline, _passError).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // TOMBOL MASUK
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLocked ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A5F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isLocked ? "Tunggu $_cooldown detik..." : "Masuk",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper untuk InputDecoration agar tidak repetitif
  InputDecoration _inputDecor(String label, IconData icon, String? error) {
    return InputDecoration(
      labelText: label,
      errorText: error,
      prefixIcon: Icon(icon, color: const Color(0xFF1E3A5F)),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}