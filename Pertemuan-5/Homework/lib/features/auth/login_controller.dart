class LoginController {
  // ===== USERS =====
  final Map<String, String> _users = {
    // tim_greece
    "admin": "admin123",
    "ibnu":  "836836",
    "hilmi": "080306",
    // tim_spartan
    "zeus": "pass123",
    "hera": "pass456",
  };

  // ===== ROLES =====
  static const Map<String, String> userRoles = {
    "admin": "Ketua",
    "ibnu":  "Anggota",
    "hilmi": "Anggota",
    "zeus":  "Ketua",
    "hera":  "Anggota",
  };

  // ===== TEAM MAPPING =====
  static const Map<String, String> userTeams = {
    "admin": "tim_greece",
    "ibnu":  "tim_greece",
    "hilmi": "tim_greece",
    "zeus":  "tim_spartan",
    "hera":  "tim_spartan",
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

  // ===== GETTERS =====
  String getRoleFor(String username) {
    return userRoles[username] ?? 'Anggota';
  }

  String getTeamFor(String username) {
    return userTeams[username] ?? 'tim_greece';
  }
}