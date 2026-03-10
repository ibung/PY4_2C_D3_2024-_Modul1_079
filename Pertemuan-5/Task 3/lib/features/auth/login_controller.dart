class LoginController {
  final Map<String, String> _users = {
    "admin": "admin123",
    "ibnu": "836836",
    "hilmi": "080306",
  };

  // ← TAMBAH: map user ke role
  static const Map<String, String> userRoles = {
    "admin": "Ketua",
    "ibnu": "Anggota",
    "hilmi": "Anggota",
  };

  int _attempts = 0;
  static const int maxAttempts = 3;

  int get attempts => _attempts;
  bool get isLocked => _attempts >= maxAttempts;

  void resetAttempts() => _attempts = 0;

  String? validate(String username, String password) {
    if (username.isEmpty) return "Username tidak boleh kosong";
    if (password.isEmpty) return "Password tidak boleh kosong";
    return null;
  }

  bool login(String username, String password) {
    if (_users[username] == password) {
      _attempts = 0;
      return true;
    }
    _attempts++;
    return false;
  }

  // ← TAMBAH: ambil role berdasarkan username
  String getRoleFor(String username) {
    return userRoles[username] ?? 'Anggota';
  }
}