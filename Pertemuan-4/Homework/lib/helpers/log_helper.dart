import 'dart:developer' as dev;
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Task 4: Professional Audit Logging
///
/// Fitur:
/// - Verbosity Control via LOG_LEVEL di .env (1=ERROR, 2=INFO, 3=VERBOSE)
/// - Source Filtering via LOG_MUTE di .env (comma-separated)
/// - File log per tanggal: /logs/dd-mm-yyyy.log
class LogHelper {
  static Future<void> writeLog(
    String message, {
    String source = "Unknown",
    int level = 2,
  }) async {
    // Baca konfigurasi dari .env
    final int configLevel = int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;
    final String muteList = dotenv.env['LOG_MUTE'] ?? '';

    // Filter berdasarkan level (hanya tampilkan jika level <= configLevel)
    if (level > configLevel) return;

    // Filter berdasarkan source (matikan log dari file tertentu)
    final List<String> mutedSources =
        muteList.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (mutedSources.contains(source)) return;

    try {
      final DateTime now = DateTime.now();
      final String timestamp = DateFormat('HH:mm:ss').format(now);
      final String label = _getLabel(level);
      final String color = _getColor(level);

      // Output ke Dart developer log
      dev.log(message, name: source, time: now, level: level * 100);

      // Output berwarna ke terminal
      // Catatan: LOG_LEVEL=3 menampilkan semua detail log (VERBOSE)
      print('$color[$timestamp][$label][$source] -> $message\x1B[0m');

      // Task 4: Tulis ke file log per tanggal di folder /logs/
      await _writeToFile(now, label, source, message);
    } catch (e) {
      dev.log("Logging failed: $e", name: "SYSTEM", level: 1000);
    }
  }

  /// Menulis log ke file /logs/dd-mm-yyyy.log
  /// File terbentuk otomatis per tanggal
  static Future<void> _writeToFile(
    DateTime now,
    String label,
    String source,
    String message,
  ) async {
    try {
      final String dateStr = DateFormat('dd-MM-yyyy').format(now);
      final String timeStr = DateFormat('HH:mm:ss').format(now);
      final Directory logsDir = Directory('logs');

      // Buat folder /logs jika belum ada
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      final File logFile = File('logs/$dateStr.log');
      final String logLine = '[$timeStr][$label][$source] -> $message\n';

      // Append ke file (tidak menimpa log sebelumnya)
      await logFile.writeAsString(logLine, mode: FileMode.append);
    } catch (e) {
      // Gagal tulis file tidak boleh crash aplikasi
      dev.log("File logging failed: $e", name: "LogHelper", level: 1000);
    }
  }

  static String _getLabel(int level) {
    switch (level) {
      case 1:
        return "ERROR";
      case 2:
        return "INFO";
      case 3:
        return "VERBOSE";
      default:
        return "LOG";
    }
  }

  static String _getColor(int level) {
    switch (level) {
      case 1:
        return '\x1B[31m'; // Merah untuk ERROR
      case 2:
        return '\x1B[32m'; // Hijau untuk INFO
      case 3:
        return '\x1B[34m'; // Biru untuk VERBOSE
      default:
        return '\x1B[0m';
    }
  }
}