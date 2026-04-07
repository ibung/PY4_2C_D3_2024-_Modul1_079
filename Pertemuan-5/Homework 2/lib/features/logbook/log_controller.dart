import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../services/mongo_service.dart';
import '../../services/access_control_service.dart';
import '../../helpers/log_helper.dart';
import 'models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  String currentUserId = '';
  String currentUserRole = 'Anggota';
  String currentTeamId = '';

  Box<LogModel> get _myBox => Hive.box<LogModel>('offline_logs');

  // ─── LOAD (Offline-First) ────────────────────────────────
  Future<void> loadLogs(String teamId) async {
    currentTeamId = teamId;

    // Tampilkan data lokal dulu (termasuk yang belum sync)
    logsNotifier.value = _myBox.values.toList();

    try {
      final cloudData = await MongoService().getLogsByTeam(teamId);

      // Ambil data lokal yang BELUM tersinkron sebelum clear
      final pendingData = _myBox.values
          .where((log) => !log.isSynced)
          .toList();

      // Hapus hanya data yang sudah sync (aman di-replace dari cloud)
      final keysToDelete = _myBox.values
          .where((log) => log.isSynced)
          .map((log) => log.key)
          .toList();
      for (final key in keysToDelete) {
        await _myBox.delete(key);
      }

      // Masukkan data terbaru dari Atlas
      await _myBox.addAll(cloudData);

      // Tampilkan gabungan: cloud + pending lokal
      logsNotifier.value = [...cloudData, ...pendingData];

      await LogHelper.writeLog(
        "SYNC: ${cloudData.length} data dari Atlas, "
        "${pendingData.length} data pending lokal.",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "OFFLINE: Menggunakan data cache lokal - $e",
        source: "log_controller.dart",
        level: 2,
      );
    }
  }

  // ─── SYNC PENDING ────────────────────────────────────────
  // Dipanggil saat HP kembali online. Upload semua data
  // yang isSynced == false ke Atlas, lalu tandai jadi true.
  Future<void> syncPendingLogs() async {
    final pendingLogs = _myBox.values
        .where((log) => !log.isSynced)
        .toList();

    if (pendingLogs.isEmpty) {
      await LogHelper.writeLog(
        "SYNC: Tidak ada data pending.",
        source: "log_controller.dart",
        level: 3,
      );
      return;
    }

    await LogHelper.writeLog(
      "SYNC: Mengunggah ${pendingLogs.length} data pending ke Atlas...",
      source: "log_controller.dart",
      level: 2,
    );

    int successCount = 0;
    for (final log in pendingLogs) {
      try {
        await MongoService().insertLogModel(log);

        // Tandai sudah sync di Hive
        final hiveIndex =
            _myBox.values.toList().indexWhere((l) => l.id == log.id);
        if (hiveIndex != -1) {
          await _myBox.putAt(hiveIndex, log.copyWith(isSynced: true));
        }
        successCount++;
      } catch (e) {
        await LogHelper.writeLog(
          "WARNING: Gagal upload '${log.title}' - $e",
          source: "log_controller.dart",
          level: 1,
        );
      }
    }

    await LogHelper.writeLog(
      "SYNC: $successCount/${pendingLogs.length} data berhasil diupload.",
      source: "log_controller.dart",
      level: 2,
    );
  }

  // ─── ADD ─────────────────────────────────────────────────
  // authorId dan teamId sekarang diterima langsung dari UI
  // (dikirim oleh LogEditorPage sesuai pola di modul).
  Future<void> addLog(
    String title,
    String description,
    String category,
    String authorId,   // ← dari currentUser['uid'] di UI
    String teamId,     // ← dari currentUser['teamId'] di UI
  ) async {
    final newLog = LogModel(
      id: mongo.ObjectId().oid,
      title: title,
      description: description,
      timestamp: DateTime.now().toIso8601String(),
      category: category,
      authorId: authorId,
      teamId: teamId,
      isSynced: false, // belum tersinkron
    );

    // Simpan lokal dulu (instan, tidak peduli koneksi)
    await _myBox.add(newLog);
    logsNotifier.value = [...logsNotifier.value, newLog];

    // Coba langsung kirim ke Atlas
    try {
      await MongoService().insertLogModel(newLog);

      // Berhasil → update isSynced jadi true
      final hiveIndex =
          _myBox.values.toList().indexWhere((l) => l.id == newLog.id);
      if (hiveIndex != -1) {
        await _myBox.putAt(hiveIndex, newLog.copyWith(isSynced: true));
      }

      // Update notifier juga
      logsNotifier.value = logsNotifier.value.map((l) {
        return l.id == newLog.id ? l.copyWith(isSynced: true) : l;
      }).toList();

      await LogHelper.writeLog(
        "SUCCESS: '${newLog.title}' tersinkron ke Atlas.",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      // Offline/gagal → isSynced tetap false, akan dicoba saat online
      await LogHelper.writeLog(
        "WARNING: '${newLog.title}' disimpan lokal "
        "(isSynced=false), akan sync saat online - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // ─── UPDATE ──────────────────────────────────────────────
  Future<void> updateLog(
    int index,
    String title,
    String description,
    String category,
  ) async {
    final target = logsNotifier.value[index];

    final isOwner = target.authorId == currentUserId;
    if (!AccessControlService.canPerform(
      currentUserRole,
      AccessControlService.actionUpdate,
      isOwner: isOwner,
    )) {
      await LogHelper.writeLog(
        "SECURITY: Unauthorized update attempt by $currentUserId",
        source: "log_controller.dart",
        level: 1,
      );
      return;
    }

    final updated = target.copyWith(
      title: title,
      description: description,
      timestamp: DateTime.now().toIso8601String(),
      category: category,
      isSynced: false,
    );

    final hiveIndex =
        _myBox.values.toList().indexWhere((l) => l.id == target.id);
    if (hiveIndex != -1) await _myBox.putAt(hiveIndex, updated);

    final list = List<LogModel>.from(logsNotifier.value);
    list[index] = updated;
    logsNotifier.value = list;

    try {
      await MongoService().updateLogModel(updated);

      final synced = updated.copyWith(isSynced: true);
      if (hiveIndex != -1) await _myBox.putAt(hiveIndex, synced);
      list[index] = synced;
      logsNotifier.value = List.from(list);

      await LogHelper.writeLog(
        "SUCCESS: '${updated.title}' diperbarui di Atlas.",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Gagal sync update ke Atlas - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // ─── DELETE ──────────────────────────────────────────────
  Future<void> removeLog(int index) async {
    final target = logsNotifier.value[index];

    final isOwner = target.authorId == currentUserId;
    if (!AccessControlService.canPerform(
      currentUserRole,
      AccessControlService.actionDelete,
      isOwner: isOwner,
    )) {
      await LogHelper.writeLog(
        "SECURITY BREACH: Unauthorized delete attempt by $currentUserId",
        source: "log_controller.dart",
        level: 1,
      );
      return;
    }

    final hiveIndex =
        _myBox.values.toList().indexWhere((l) => l.id == target.id);
    if (hiveIndex != -1) await _myBox.deleteAt(hiveIndex);

    final list = List<LogModel>.from(logsNotifier.value);
    list.removeAt(index);
    logsNotifier.value = list;

    if (target.id != null) {
      try {
        await MongoService()
            .deleteLog(mongo.ObjectId.fromHexString(target.id!));
        await LogHelper.writeLog(
          "SUCCESS: '${target.title}' dihapus dari Atlas.",
          source: "log_controller.dart",
          level: 2,
        );
      } catch (e) {
        await LogHelper.writeLog(
          "WARNING: Gagal hapus dari Atlas - $e",
          source: "log_controller.dart",
          level: 1,
        );
      }
    }
  }

  // ─── CONNECTIVITY LISTENER ───────────────────────────────
  // Urutan yang benar: syncPending DULU → baru loadLogs
  // agar data offline tidak tertimpa data cloud.
  void startConnectivityListener(String teamId) {
    Connectivity().onConnectivityChanged.listen((result) async {
      final isOnline = result != ConnectivityResult.none;
      if (isOnline) {
        await LogHelper.writeLog(
          "CONNECTIVITY: Internet kembali, memulai sync...",
          source: "log_controller.dart",
          level: 2,
        );
        await syncPendingLogs(); // ← 1. upload pending dulu
        await loadLogs(teamId);  // ← 2. baru pull dari Atlas
      }
    });
  }
}