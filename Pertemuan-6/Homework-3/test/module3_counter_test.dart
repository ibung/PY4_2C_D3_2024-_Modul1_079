// test/module3_counter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logbook_app_079/features/logbook/log_controller.dart';

void main() {
  var actual, expected;

  group('Module 3 - LogController (Save Data to Disk)', () {
    late LogController controller;

    setUp(() async {
      // (1) setup (arrange, build)
      SharedPreferences.setMockInitialValues({});
      controller = LogController();
      await Future.delayed(Duration.zero); // tunggu loadLogs selesai
    });

    // ── TC01 ──────────────────────────────────────────────────────────────────
    test('TC01 - addLog harus menambahkan log baru ke dalam list', () {
      // (2) exercise (act, operate)
      controller.addLog('Judul Test', 'Deskripsi Test', 'Pribadi');
      actual = controller.logsNotifier.value.length;
      expected = 1;

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC02 ──────────────────────────────────────────────────────────────────
    test('TC02 - addLog harus menyimpan data judul dengan benar', () {
      // (2) exercise (act, operate)
      controller.addLog('Judul Test', 'Deskripsi Test', 'Pribadi');
      actual = controller.logsNotifier.value.first.title;
      expected = 'Judul Test';

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC03 ──────────────────────────────────────────────────────────────────
    test('TC03 - updateLog harus mengubah data log pada index yang ditentukan', () {
      // (1) setup (arrange, build)
      controller.addLog('Judul Lama', 'Deskripsi Lama', 'Pribadi');

      // (2) exercise (act, operate)
      controller.updateLog(0, 'Judul Baru', 'Deskripsi Baru', 'Pekerjaan');
      actual = controller.logsNotifier.value[0].title;
      expected = 'Judul Baru';

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC04 ──────────────────────────────────────────────────────────────────
    test('TC04 - removeLog harus menghapus log pada index yang ditentukan', () {
      // (1) setup (arrange, build)
      controller.addLog('Log 1', 'Desc 1', 'Pribadi');
      controller.addLog('Log 2', 'Desc 2', 'Pekerjaan');

      // (2) exercise (act, operate)
      controller.removeLog(0);
      actual = controller.logsNotifier.value.length;
      expected = 1;

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC05 ──────────────────────────────────────────────────────────────────
    test('TC05 - removeLog harus menghapus log yang benar berdasarkan index', () {
      // (1) setup (arrange, build)
      controller.addLog('Log 1', 'Desc 1', 'Pribadi');
      controller.addLog('Log 2', 'Desc 2', 'Pekerjaan');

      // (2) exercise (act, operate)
      controller.removeLog(0);
      actual = controller.logsNotifier.value.first.title;
      expected = 'Log 2';

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC06 ──────────────────────────────────────────────────────────────────
    test('TC06 - searchLog harus menampilkan hasil yang sesuai kata kunci', () {
      // (1) setup (arrange, build)
      controller.addLog('Belajar Flutter', 'Desc', 'Pribadi');
      controller.addLog('Makan Siang', 'Desc', 'Pribadi');

      // (2) exercise (act, operate)
      controller.searchLog('flutter');
      actual = controller.filteredLogs.value.length;
      expected = 1;

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC07 ──────────────────────────────────────────────────────────────────
    test('TC07 - searchLog dengan query kosong harus menampilkan semua log', () {
      // (1) setup (arrange, build)
      controller.addLog('Log 1', 'Desc 1', 'Pribadi');
      controller.addLog('Log 2', 'Desc 2', 'Pekerjaan');

      // (2) exercise (act, operate)
      controller.searchLog('');
      actual = controller.filteredLogs.value.length;
      expected = 2;

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC08 ──────────────────────────────────────────────────────────────────
    test('TC08 - searchLog harus mengembalikan list kosong jika tidak ada yang cocok', () {
      // (1) setup (arrange, build)
      controller.addLog('Belajar Flutter', 'Desc', 'Pribadi');

      // (2) exercise (act, operate)
      controller.searchLog('tidakada');
      actual = controller.filteredLogs.value.length;
      expected = 0;

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC09 ──────────────────────────────────────────────────────────────────
    test('TC09 - saveLogs dan loadLogs harus menyimpan dan memuat data dengan benar', () async {
      // (1) setup (arrange, build)
      controller.addLog('Log Tersimpan', 'Desc', 'Pribadi');
      await controller.saveLogs();

      // (2) exercise (act, operate)
      final newController = LogController();
      await newController.loadLogs();
      actual = newController.logsNotifier.value.length;
      expected = 1;

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC10 ──────────────────────────────────────────────────────────────────
    test('TC10 - filteredLogs harus ikut diperbarui saat logsNotifier berubah', () {
      // (2) exercise (act, operate)
      controller.addLog('Log Baru', 'Desc', 'Pribadi');
      actual = controller.filteredLogs.value.length;
      expected = 1;

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });
  });
}