// login_controller.dart
class LoginController {
  // Database sederhana (Hardcoded)
  final String _validUsername = "admin";
  final String _validPassword = "123";

  // Fungsi pengecekan (Logic-Only)
  // Fungsi ini mengembalikan true jika cocok, false jika salah.
  bool login(String username, String password) {
    if (username == _validUsername && password == _validPassword) {
      return true;
    }
    return false;
  }
}