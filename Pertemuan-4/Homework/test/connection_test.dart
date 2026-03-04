import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_079/services/mongo_service.dart';
import 'package:logbook_app_079/helpers/log_helper.dart';

/// Task 2: Smoke Testing
/// Memverifikasi koneksi ke MongoDB Atlas via MongoService Singleton.
/// Jalankan dengan: flutter test test/connection_test.dart
void main() {
  const String sourceFile = "connection_test.dart";

  setUpAll(() async {
    // Load .env sebelum test berjalan
    await dotenv.load(fileName: ".env");

    await LogHelper.writeLog(
      "Setup: .env berhasil dimuat.",
      source: sourceFile,
      level: 3,
    );
  });

  tearDownAll(() async {
    // Tutup koneksi setelah semua test selesai
    await MongoService().close();
    await LogHelper.writeLog(
      "--- ALL TESTS FINISHED ---",
      source: sourceFile,
      level: 2,
    );
  });

  // ─── TEST 1: Koneksi Atlas ───────────────────────────────────
  test('Memastikan koneksi ke MongoDB Atlas berhasil via MongoService', () async {
    await LogHelper.writeLog(
      "--- START CONNECTION TEST ---",
      source: sourceFile,
      level: 2,
    );

    try {
      await MongoService().connect();

      // Verifikasi MONGODB_URI tersedia di .env
      expect(
        dotenv.env['MONGODB_URI'],
        isNotNull,
        reason: "MONGODB_URI harus ada di file .env",
      );
      expect(
        dotenv.env['MONGODB_URI'],
        isNotEmpty,
        reason: "MONGODB_URI tidak boleh kosong",
      );

      await LogHelper.writeLog(
        "SUCCESS: Terhubung ke MongoDB Atlas",
        source: sourceFile,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Kegagalan koneksi - $e",
        source: sourceFile,
        level: 1,
      );
      fail("Koneksi Atlas gagal: $e");
    }
  });

  // ─── TEST 2: Singleton Identity ─────────────────────────────
  test('MongoService harus mengembalikan instance yang sama (Singleton)', () {
    final MongoService instance1 = MongoService();
    final MongoService instance2 = MongoService();

    expect(
      identical(instance1, instance2),
      isTrue,
      reason: "MongoService harus Singleton — hanya boleh ada 1 instance.",
    );

    LogHelper.writeLog(
      "SUCCESS: Singleton verified — instance1 === instance2",
      source: sourceFile,
      level: 2,
    );
  });

  // ─── TEST 3: getLogs() tidak crash ──────────────────────────
  test('getLogs() harus mengembalikan List tanpa melempar exception', () async {
    await LogHelper.writeLog(
      "Testing getLogs()...",
      source: sourceFile,
      level: 3,
    );

    try {
      final List logs = await MongoService().getLogs();

      // Hasil boleh kosong, tapi tidak boleh null
      expect(logs, isA<List>());

      await LogHelper.writeLog(
        "SUCCESS: getLogs() mengembalikan ${logs.length} dokumen.",
        source: sourceFile,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: getLogs() melempar exception - $e",
        source: sourceFile,
        level: 1,
      );
      fail("getLogs() gagal: $e");
    }
  });
}