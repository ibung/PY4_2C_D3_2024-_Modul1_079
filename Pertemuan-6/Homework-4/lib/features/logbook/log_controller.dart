import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/mongo_service.dart';
import '../../models/logbook_model.dart';
import 'models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);

  /// Notifikasi status pemuatan awal (latency cloud)
  final ValueNotifier<bool> isLoading = ValueNotifier(true);

  // ✅ Hapus = MongoService() dari sini
  final MongoService _db;

  static const String storageKey = "user_logs";

  // ✅ Pindahkan MongoService() ke initializer list
  LogController() : _db = MongoService() {
    _initialize();
    logsNotifier.addListener(() {
      filteredLogs.value = logsNotifier.value;
    });
  }

  /// Constructor khusus untuk unit testing
  LogController.withDb(MongoService db) : _db = db {
    _initialize();
    logsNotifier.addListener(() {
      filteredLogs.value = logsNotifier.value;
    });
  }

  Future<void> _initialize() async {
    await loadLogs();
    isLoading.value = false;
  }

  // ===== SEARCH =====
  void searchLog(String query) {
    if (query.isEmpty) {
      filteredLogs.value = logsNotifier.value;
    } else {
      filteredLogs.value = logsNotifier.value
          .where(
            (log) =>
                log.title.toLowerCase().contains(query.toLowerCase()) ||
                log.description.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
  }

  // ===== ADD =====
  void addLog(String title, String description, String category) async {
    final newLog = LogModel(
      title: title,
      description: description,
      timestamp: DateTime.now().toIso8601String(),
      category: category,
    );

    // Tambahkan ke lokal dulu agar UI langsung responsif
    logsNotifier.value = [...logsNotifier.value, newLog];

    // Kirim ke cloud
    try {
      final inserted = Logbook(
        title: title,
        description: description,
        date: DateTime.parse(newLog.timestamp),
      );
      await _db.insertLog(inserted);
    } catch (_) {
      // Gagal cloud tidak menghentikan aplikasi
    }

    await saveLogs();
  }

  // ===== EDIT =====
  void updateLog(
    int index,
    String title,
    String description,
    String category,
  ) async {
    final old = logsNotifier.value[index];

    final updated = LogModel(
      id: old.id,
      title: title,
      description: description,
      timestamp: DateTime.now().toIso8601String(),
      category: category,
    );

    final list = List<LogModel>.from(logsNotifier.value);
    list[index] = updated;
    logsNotifier.value = list;

    // Jika log lama punya id cloud, update ke Atlas
    if (old.id != null) {
      try {
        await _db.updateLog(
          Logbook(
            id: ObjectId.fromHexString(old.id!),
            title: title,
            description: description,
            date: DateTime.parse(updated.timestamp),
          ),
        );
      } catch (_) {}
    }

    await saveLogs();
  }

  // ===== DELETE =====
  void removeLog(int index) async {
    final target = logsNotifier.value[index];

    final list = List<LogModel>.from(logsNotifier.value);
    list.removeAt(index);
    logsNotifier.value = list;

    // Hapus dari cloud jika punya id
    if (target.id != null) {
      try {
        await _db.deleteLog(ObjectId.fromHexString(target.id!));
      } catch (_) {}
    }

    await saveLogs();
  }

  // ===== SAVE ke SharedPreferences =====
  Future<void> saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(logsNotifier.value.map((l) => l.toMap()).toList());
    await prefs.setString(storageKey, json);
  }

  // ===== LOAD: Cloud dulu, fallback ke lokal =====
  Future<void> loadLogs() async {
    // Coba ambil dari MongoDB Atlas
    try {
      await _db.connect();
      final cloudData = await _db.getLogs();

      logsNotifier.value = cloudData
          .map(
            (lb) => LogModel(
              id: lb.id?.toHexString(),
              title: lb.title,
              description: lb.description,
              timestamp: lb.date.toIso8601String(),
              category: 'Pribadi',
            ),
          )
          .toList();

      // Simpan salinan lokal untuk mode offline
      await saveLogs();
      return;
    } catch (_) {
      // Cloud gagal → fallback ke SharedPreferences
    }

    // Fallback: ambil dari lokal
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(storageKey);
    if (json != null) {
      final List decoded = jsonDecode(json);
      logsNotifier.value = decoded.map((e) => LogModel.fromMap(e)).toList();
    }
  }
}