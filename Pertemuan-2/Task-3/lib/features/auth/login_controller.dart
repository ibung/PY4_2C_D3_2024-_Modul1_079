// login_controller.dart
class LoginController {
  // ===== MULTIPLE USERS =====
  final Map<String, String> _users = {
    "admin": "123",
    "user1": "pass1",
    "user2": "pass2",
  };

  // ===== LOGIN ATTEMPT =====
  int _attempts = 0;
  static const int maxAttempts = 3;

  int get attempts => _attempts;
  bool get isLocked => _attempts >= maxAttempts;

  void resetAttempts() => _attempts = 0;

  // ===== VALIDATION =====
  String? validate(String username, String password) {
    if (username.isEmpty) return "Username tidak boleh kosong";
    if (password.isEmpty) return "Password tidak boleh kosong";
    return null;
  }

  // ===== LOGIN LOGIC =====
  bool login(String username, String password) {
    if (_users[username] == password) {
      _attempts = 0;
      return true;
    }
    _attempts++;
    return false;
  }
}