import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  static const String _storageKey = 'user_logs_data';

  LogController() {
    loadFromDisk();
  }

  void addLog(String title, String desc) {
    final newLog = LogModel(
      title: title,
      description: desc,
      date: DateTime.now().toString(),
    );

    logsNotifier.value = [...logsNotifier.value, newLog];
    saveToDisk();
  }

  void updateLog(int index, String title, String desc) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);

    currentLogs[index] = LogModel(
      title: title,
      description: desc,
      date: DateTime.now().toString(),
    );

    logsNotifier.value = currentLogs;
    saveToDisk();
  }

  void removeLog(int index) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs.removeAt(index);
    logsNotifier.value = currentLogs;
    saveToDisk();
  }

  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();

    final encodedData = jsonEncode(
      logsNotifier.value.map((e) => e.toMap()).toList(),
    );

    await prefs.setString(_storageKey, encodedData);
  }

  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);

    if (data != null) {
      final List decoded = jsonDecode(data);
      logsNotifier.value =
          decoded.map((e) => LogModel.fromMap(e)).toList();
    }
  }
}