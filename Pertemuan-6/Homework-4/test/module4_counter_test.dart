// test/module4_log_cloud_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:logbook_app_079/services/mongo_service.dart';
import 'package:logbook_app_079/models/logbook_model.dart';
import 'package:logbook_app_079/features/logbook/log_controller.dart';
import 'package:logbook_app_079/features/logbook/models/log_model.dart';

import 'module4_counter_test.mocks.dart';

@GenerateMocks([MongoService])
void main() {
  var actual, expected;

  group('Module 4 - LogController (Save Data to Cloud Service)', () {
    late LogController controller;
    late MockMongoService mockDb;

    setUp(() async {
      // (1) setup (arrange, build)
      SharedPreferences.setMockInitialValues({});
      mockDb = MockMongoService();

      // Default stub: connect & getLogs sukses, return list kosong
      when(mockDb.connect()).thenAnswer((_) async {});
      when(mockDb.getLogs()).thenAnswer((_) async => []);
      when(mockDb.insertLog(any)).thenAnswer((_) async {});
      when(mockDb.updateLog(any)).thenAnswer((_) async {});
      when(mockDb.deleteLog(any)).thenAnswer((_) async {});

      controller = LogController.withDb(mockDb);
      await Future.delayed(const Duration(milliseconds: 100));
    });

    // ── TC01 ──────────────────────────────────────────────────────────────────
    test('TC01 - loadLogs harus memuat data dari cloud saat koneksi berhasil', () async {
      // (1) setup
      final cloudLogs = [
        Logbook(title: 'Log Cloud', description: 'Desc', date: DateTime.now()),
      ];
      when(mockDb.connect()).thenAnswer((_) async {});
      when(mockDb.getLogs()).thenAnswer((_) async => cloudLogs);

      final ctrl = LogController.withDb(mockDb);

      // (2) exercise
      await Future.delayed(const Duration(milliseconds: 100));
      actual = ctrl.logsNotifier.value.length;
      expected = 1;

      // (3) verify
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC02 ──────────────────────────────────────────────────────────────────
    test('TC02 - loadLogs harus fallback ke lokal saat cloud gagal', () async {
      // (1) setup — simpan data lokal dulu
      SharedPreferences.setMockInitialValues({
        'user_logs':
            '[{"id":null,"title":"Log Lokal","description":"Desc","timestamp":"2024-01-01T00:00:00.000","category":"Pribadi","authorId":null,"teamId":null}]',
      });
      when(mockDb.connect()).thenThrow(Exception('Tidak ada koneksi'));

      final ctrl = LogController.withDb(mockDb);

      // (2) exercise
      await Future.delayed(const Duration(milliseconds: 100));
      actual = ctrl.logsNotifier.value.length;
      expected = 1;

      // (3) verify
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC03 ──────────────────────────────────────────────────────────────────
    test('TC03 - addLog harus menambahkan log ke logsNotifier', () async {
      // (2) exercise
      controller.addLog('Judul Baru', 'Deskripsi', 'Pribadi');
      await Future.delayed(const Duration(milliseconds: 50));
      actual = controller.logsNotifier.value.length;
      expected = 1;

      // (3) verify
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC04 ──────────────────────────────────────────────────────────────────
    test('TC04 - addLog harus memanggil insertLog ke cloud', () async {
      // (2) exercise
      controller.addLog('Judul Cloud', 'Deskripsi', 'Pribadi');
      await Future.delayed(const Duration(milliseconds: 50));

      // (3) verify
      verify(mockDb.insertLog(any)).called(1);
    });

    // ── TC05 ──────────────────────────────────────────────────────────────────
    test('TC05 - addLog harus tetap berhasil meski cloud gagal', () async {
      // (1) setup — cloud gagal
      when(mockDb.insertLog(any)).thenThrow(Exception('Cloud error'));

      // (2) exercise
      controller.addLog('Judul Offline', 'Deskripsi', 'Pribadi');
      await Future.delayed(const Duration(milliseconds: 50));
      actual = controller.logsNotifier.value.length;
      expected = 1;

      // (3) verify — log tetap masuk meski cloud gagal
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC06 ──────────────────────────────────────────────────────────────────
    test('TC06 - updateLog harus mengubah data log pada index yang ditentukan', () async {
      // (1) setup
      controller.addLog('Judul Lama', 'Desc Lama', 'Pribadi');
      await Future.delayed(const Duration(milliseconds: 50));

      // (2) exercise
      controller.updateLog(0, 'Judul Baru', 'Desc Baru', 'Pekerjaan');
      await Future.delayed(const Duration(milliseconds: 50));
      actual = controller.logsNotifier.value[0].title;
      expected = 'Judul Baru';

      // (3) verify
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC07 ──────────────────────────────────────────────────────────────────
    test('TC07 - removeLog harus menghapus log dari logsNotifier', () async {
      // (1) setup
      controller.addLog('Log 1', 'Desc', 'Pribadi');
      controller.addLog('Log 2', 'Desc', 'Pekerjaan');
      await Future.delayed(const Duration(milliseconds: 50));

      // (2) exercise
      controller.removeLog(0);
      await Future.delayed(const Duration(milliseconds: 50));
      actual = controller.logsNotifier.value.length;
      expected = 1;

      // (3) verify
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC08 ──────────────────────────────────────────────────────────────────
    test('TC08 - searchLog harus memfilter log berdasarkan judul', () async {
      // (1) setup
      controller.addLog('Belajar Flutter', 'Desc', 'Pribadi');
      controller.addLog('Makan Siang', 'Desc', 'Pribadi');
      await Future.delayed(const Duration(milliseconds: 50));

      // (2) exercise
      controller.searchLog('flutter');
      actual = controller.filteredLogs.value.length;
      expected = 1;

      // (3) verify
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC09 ──────────────────────────────────────────────────────────────────
    test('TC09 - searchLog harus memfilter log berdasarkan deskripsi', () async {
      // (1) setup
      controller.addLog('Judul', 'Belajar Dart', 'Pribadi');
      controller.addLog('Judul2', 'Makan siang', 'Pribadi');
      await Future.delayed(const Duration(milliseconds: 50));

      // (2) exercise
      controller.searchLog('dart');
      actual = controller.filteredLogs.value.length;
      expected = 1;

      // (3) verify
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });

    // ── TC10 ──────────────────────────────────────────────────────────────────
    test('TC10 - isLoading harus false setelah inisialisasi selesai', () async {
      // (2) exercise
      await Future.delayed(const Duration(milliseconds: 200));
      actual = controller.isLoading.value;
      expected = false;

      // (3) verify
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
    });
  });
}