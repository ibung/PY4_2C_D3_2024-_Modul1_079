import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);

  static const String storageKey = "user_logs";

  LogController() {
    loadLogs(); // Load saat app start
  }

  // ================= ADD =================
  void addLog(String title, String description) {
    final newLog = LogModel(
      title: title,
      description: description,
      timestamp: DateTime.now().toString(),
    );

    logsNotifier.value = [...logsNotifier.value, newLog];
    saveLogs();
  }

  // ================= EDIT =================
  void updateLog(int index, String title, String description) {
    final updatedList = List<LogModel>.from(logsNotifier.value);

    updatedList[index] = LogModel(
      title: title,
      description: description,
      timestamp: DateTime.now().toString(),
    );

    logsNotifier.value = updatedList;
    saveLogs();
  }

  // ================= DELETE =================
  void removeLog(int index) {
    final updatedList = List<LogModel>.from(logsNotifier.value);
    updatedList.removeAt(index);

    logsNotifier.value = updatedList;
    saveLogs();
  }

  // ================= SAVE JSON =================
  Future<void> saveLogs() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = jsonEncode(
      logsNotifier.value.map((log) => log.toMap()).toList(),
    );

    await prefs.setString(storageKey, jsonString);
  }

  // ================= LOAD JSON =================
  Future<void> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = prefs.getString(storageKey);

    if (jsonString != null) {
      final List decoded = jsonDecode(jsonString);

      logsNotifier.value =
          decoded.map((e) => LogModel.fromMap(e)).toList();
    }
  }
}