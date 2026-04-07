// test/module2_counter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_079/features/auth/login_controller.dart';

void main() {
  var actual, expected;

  group('Module 2 - LoginController', () {
    late LoginController controller;

    setUp(() {
      // (1) setup (arrange, build)
      controller = LoginController();
    });

    // ── TC01 ──────────────────────────────────────────────────────────────────
    test('TC01 - validate harus mengembalikan pesan error jika username kosong', () {
      // (2) exercise (act, operate)
      actual = controller.validate('', 'pass1');
      expected = "Username tidak boleh kosong";

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC02 ──────────────────────────────────────────────────────────────────
    test('TC02 - validate harus mengembalikan pesan error jika password kosong', () {
      // (2) exercise (act, operate)
      actual = controller.validate('admin', '');
      expected = "Password tidak boleh kosong";

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC03 ──────────────────────────────────────────────────────────────────
    test('TC03 - validate harus mengembalikan null jika username dan password tidak kosong', () {
      // (2) exercise (act, operate)
      actual = controller.validate('admin', '123');
      expected = null;

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC04 ──────────────────────────────────────────────────────────────────
    test('TC04 - login harus berhasil dengan kredensial yang benar', () {
      // (2) exercise (act, operate)
      actual = controller.login('admin', '123');
      expected = true;

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC05 ──────────────────────────────────────────────────────────────────
    test('TC05 - login harus gagal dengan password yang salah', () {
      // (2) exercise (act, operate)
      actual = controller.login('admin', 'salah');
      expected = false;

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC06 ──────────────────────────────────────────────────────────────────
    test('TC06 - login harus gagal dengan username yang tidak terdaftar', () {
      // (2) exercise (act, operate)
      actual = controller.login('tidakada', '123');
      expected = false;

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC07 ──────────────────────────────────────────────────────────────────
    test('TC07 - attempts harus bertambah setiap login gagal', () {
      // (2) exercise (act, operate)
      controller.login('admin', 'salah');
      controller.login('admin', 'salah');
      actual = controller.attempts;
      expected = 2;

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC08 ──────────────────────────────────────────────────────────────────
    test('TC08 - attempts harus direset setelah login berhasil', () {
      // (1) setup (arrange, build)
      controller.login('admin', 'salah'); // attempts = 1

      // (2) exercise (act, operate)
      controller.login('admin', '123'); // berhasil, reset
      actual = controller.attempts;
      expected = 0;

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC09 ──────────────────────────────────────────────────────────────────
    test('TC09 - isLocked harus true setelah 3 kali login gagal', () {
      // (2) exercise (act, operate)
      controller.login('admin', 'salah');
      controller.login('admin', 'salah');
      controller.login('admin', 'salah');
      actual = controller.isLocked;
      expected = true;

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC10 ──────────────────────────────────────────────────────────────────
    test('TC10 - resetAttempts harus mengatur attempts kembali ke nol', () {
      // (1) setup (arrange, build)
      controller.login('admin', 'salah');
      controller.login('admin', 'salah');
      controller.login('admin', 'salah'); // attempts = 3, locked

      // (2) exercise (act, operate)
      controller.resetAttempts();
      actual = controller.attempts;
      expected = 0;

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });
  });
}