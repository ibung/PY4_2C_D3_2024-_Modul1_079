// login_view.dart
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
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _obscure = true;
  String? _userError;
  String? _passError;

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

    setState(() {
      _userError =
          user.isEmpty ? "Username tidak boleh kosong" : null;
      _passError =
          pass.isEmpty ? "Password tidak boleh kosong" : null;
    });

    if (_userError != null || _passError != null) return;

    if (_controller.login(user, pass)) {
      // ===== NAVIGASI FIX =====
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LogView(
            username: user, // ⬅️ KIRIM USERNAME
          ),
        ),
      );
    } else {
      if (_controller.isLocked) _startCooldown();

      setState(() => _passError =
          "Username atau password salah "
          "(${_controller.attempts}/${LoginController.maxAttempts})");
    }
  }

  InputDecoration _inputStyle(
          String label, IconData icon, String? error) =>
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
      );

  @override
  Widget build(BuildContext context) {
    final isLocked =
        _controller.isLocked && _cooldown > 0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                // ===== LOGO =====
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
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

                const Text(
                  "Logbook App",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 36),

                // USERNAME
                TextField(
                  controller: _userController,
                  enabled: !isLocked,
                  decoration: _inputStyle(
                      "Username",
                      Icons.person_outline,
                      _userError),
                ),

                const SizedBox(height: 14),

                // PASSWORD
                TextField(
                  controller: _passController,
                  obscureText: _obscure,
                  enabled: !isLocked,
                  decoration: _inputStyle(
                          "Password",
                          Icons.lock_outline,
                          _passError)
                      .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => _obscure = !_obscure),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed:
                        isLocked ? null : _handleLogin,
                    child: Text(
                        isLocked ? "Tunggu..." : "Masuk"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}