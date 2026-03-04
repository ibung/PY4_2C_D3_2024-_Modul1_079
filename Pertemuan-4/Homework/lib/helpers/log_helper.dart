import 'dart:developer' as dev;
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

class LogHelper {
  static Future<void> writeLog(
    String message, {
    String source = "Unknown",
    int level = 2,
  }) async {
    final int configLevel = int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;
    final String muteList = dotenv.env['LOG_MUTE'] ?? '';

    if (level > configLevel) return;

    final List<String> mutedSources = muteList
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (mutedSources.contains(source)) return;

    try {
      final DateTime now = DateTime.now();
      final String timestamp = DateFormat('HH:mm:ss').format(now);
      final String label = _getLabel(level);
      final String color = _getColor(level);

      // Output ke Dart developer log
      dev.log(message, name: source, time: now, level: level * 100);

      // Output berwarna ke terminal
      print('$color[$timestamp][$label][$source] -> $message\x1B[0m');

      // Task 4: Tulis ke file log per tanggal
      await _writeToFile(now, label, source, message);
    } catch (e) {
      dev.log("Logging failed: $e", name: "SYSTEM", level: 1000);
    }
  }

  /// Menulis log ke file logs/dd-MM-yyyy.log
  /// Menggunakan path_provider agar path valid di semua platform.
  static Future<void> _writeToFile(
    DateTime now,
    String label,
    String source,
    String message,
  ) async {
    try {
      // getApplicationDocumentsDirectory() → path yang bisa ditulis di semua platform
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory logsDir = Directory('${appDir.path}/logs');

      // Buat folder logs/ jika belum ada
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      final String dateStr = DateFormat('dd-MM-yyyy').format(now);
      final String timeStr = DateFormat('HH:mm:ss').format(now);
      final File logFile = File('${logsDir.path}/$dateStr.log');
      final String logLine = '[$timeStr][$label][$source] -> $message\n';

      // Append ke file — log lama tidak tertimpa
      await logFile.writeAsString(logLine, mode: FileMode.append);

      // Cetak path saat pertama kali file dibuat (berguna untuk debugging)
      dev.log(
        "Log ditulis ke: ${logFile.path}",
        name: "LogHelper",
        level: 100,
      );
    } catch (e) {
      dev.log("File logging failed: $e", name: "LogHelper", level: 1000);
    }
  }

  static String _getLabel(int level) {
    switch (level) {
      case 1: return "ERROR";
      case 2: return "INFO";
      case 3: return "VERBOSE";
      default: return "LOG";
    }
  }

  static String _getColor(int level) {
    switch (level) {
      case 1: return '\x1B[31m'; // Merah
      case 2: return '\x1B[32m'; // Hijau
      case 3: return '\x1B[34m'; // Biru
      default: return '\x1B[0m';
    }
  }
}