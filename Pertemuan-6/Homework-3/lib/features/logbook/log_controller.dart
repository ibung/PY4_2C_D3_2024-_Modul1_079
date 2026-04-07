import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);

  static const String storageKey = "user_logs";

  LogController() {
    loadLogs();
    // Setiap logsNotifier berubah, filteredLogs ikut diperbarui
    logsNotifier.addListener(() {
      filteredLogs.value = logsNotifier.value;
    });
  }

  // ===== SEARCH =====
  void searchLog(String query) {
    if (query.isEmpty) {
      filteredLogs.value = logsNotifier.value;
    } else {
      filteredLogs.value = logsNotifier.value
          .where((log) => log.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  // ===== ADD =====
  void addLog(String title, String description, String category) {
    final newLog = LogModel(
      title: title,
      description: description,
      timestamp: DateTime.now().toString(),
      category: category,
    );
    logsNotifier.value = [...logsNotifier.value, newLog];
    saveLogs();
  }

  // ===== EDIT =====
  void updateLog(int index, String title, String description, String category) {
    final list = List<LogModel>.from(logsNotifier.value);
    list[index] = LogModel(
      title: title,
      description: description,
      timestamp: DateTime.now().toString(),
      category: category,
    );
    logsNotifier.value = list;
    saveLogs();
  }

  // ===== DELETE =====
  void removeLog(int index) {
    final list = List<LogModel>.from(logsNotifier.value);
    list.removeAt(index);
    logsNotifier.value = list;
    saveLogs();
  }

  // ===== SAVE =====
  Future<void> saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(logsNotifier.value.map((l) => l.toMap()).toList());
    await prefs.setString(storageKey, json);
  }

  // ===== LOAD =====
  Future<void> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(storageKey);
    if (json != null) {
      final List decoded = jsonDecode(json);
      logsNotifier.value = decoded.map((e) => LogModel.fromMap(e)).toList();
    }
  }
}