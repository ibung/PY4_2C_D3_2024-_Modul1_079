class LoginController {
  final Map<String, String> _users = {
    "admin": "admin123",
    "ibnu": "836836",
    "hilmi": "080306",
  };

  static const Map<String, String> userRoles = {
    "admin": "Ketua",
    "ibnu": "Anggota",
    "hilmi": "Anggota",
  };

  // ← TAMBAH: map user ke teamId
  // Ganti nilai 'MEKTRA_KLP_079' dengan ID tim kamu yang sebenarnya.
  // Semua anggota satu tim HARUS pakai teamId yang sama persis
  // agar data mereka muncul di MongoDB filter getLogsByTeam().
  static const Map<String, String> userTeams = {
    "admin": "MEKTRA_KLP_079",
    "ibnu":  "MEKTRA_KLP_079",
    "hilmi": "MEKTRA_KLP_079",
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

  String getRoleFor(String username) {
    return userRoles[username] ?? 'Anggota';
  }

  // ← TAMBAH: ambil teamId berdasarkan username
  String getTeamIdFor(String username) {
    return userTeams[username] ?? 'no_team';
  }
}