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

  String currentUserId   = '';
  String currentUserRole = 'Anggota';
  String currentTeamId   = '';

  Box<LogModel> get _myBox => Hive.box<LogModel>('offline_logs');

  // ─── FR-03 FIX: Inject user session sebelum operasi apapun ──────────────────
  /// Panggil method ini tepat setelah login berhasil, sebelum loadLogs().
  /// Contoh di screen:
  ///   controller.setCurrentUser(
  ///     userId  : username,
  ///     role    : loginController.getRoleFor(username),
  ///     teamId  : loginController.getTeamIdFor(username),
  ///   );
  void setCurrentUser({
    required String userId,
    required String role,
    required String teamId,
  }) {
    currentUserId   = userId;
    currentUserRole = role;
    currentTeamId   = teamId;
  }

  // ─── LOAD (Offline-First + FR-04 Team Isolation) ─────────────────────────────
  Future<void> loadLogs(String teamId) async {
    currentTeamId = teamId;

    // FR-04: Hive lokal difilter by teamId agar data tim lain tidak bocor
    final localFiltered = _myBox.values
        .where((log) => AccessControlService.isTeamMember(teamId, log.teamId))
        .toList();
    logsNotifier.value = localFiltered;

    try {
      // MongoDB sudah filter by teamId via getLogsByTeam()
      final cloudData = await MongoService().getLogsByTeam(teamId);

      // Ambil pending lokal yang belum sync (dan milik tim ini)
      final pendingData = _myBox.values
          .where((log) => !log.isSynced &&
              AccessControlService.isTeamMember(teamId, log.teamId))
          .toList();

      // Hapus hanya data yang sudah sync (milik tim ini)
      final keysToDelete = _myBox.values
          .where((log) =>
              log.isSynced &&
              AccessControlService.isTeamMember(teamId, log.teamId))
          .map((log) => log.key)
          .toList();
      for (final key in keysToDelete) {
        await _myBox.delete(key);
      }

      await _myBox.addAll(cloudData);

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

  // ─── SYNC PENDING ─────────────────────────────────────────────────────────────
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

  // ─── ADD ──────────────────────────────────────────────────────────────────────
  Future<void> addLog(
    String title,
    String description,
    String category,
    String authorId,
    String teamId,
  ) async {
    final newLog = LogModel(
      id: mongo.ObjectId().oid,
      title: title,
      description: description,
      timestamp: DateTime.now().toIso8601String(),
      category: category,
      authorId: authorId,
      teamId: teamId,
      isSynced: false,
    );

    await _myBox.add(newLog);
    logsNotifier.value = [...logsNotifier.value, newLog];

    try {
      await MongoService().insertLogModel(newLog);

      final hiveIndex =
          _myBox.values.toList().indexWhere((l) => l.id == newLog.id);
      if (hiveIndex != -1) {
        await _myBox.putAt(hiveIndex, newLog.copyWith(isSynced: true));
      }

      logsNotifier.value = logsNotifier.value.map((l) {
        return l.id == newLog.id ? l.copyWith(isSynced: true) : l;
      }).toList();

      await LogHelper.writeLog(
        "SUCCESS: '${newLog.title}' tersinkron ke Atlas.",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: '${newLog.title}' disimpan lokal (isSynced=false) - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // ─── UPDATE (FR-03: cek role + ownership) ────────────────────────────────────
  Future<bool> updateLog(
    int index,
    String title,
    String description,
    String category,
  ) async {
    final target = logsNotifier.value[index];
    final isOwner = target.authorId == currentUserId;

    // FR-03: Guard — tolak jika tidak punya izin
    if (!AccessControlService.canPerform(
      currentUserRole,
      AccessControlService.actionUpdate,
      isOwner: isOwner,
    )) {
      await LogHelper.writeLog(
        "SECURITY: Unauthorized update attempt by '$currentUserId' "
        "(role: $currentUserRole, isOwner: $isOwner)",
        source: "log_controller.dart",
        level: 1,
      );
      return false; // ← kembalikan false agar UI bisa tampilkan pesan error
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
    return true;
  }

  // ─── DELETE (FR-03: cek role + ownership) ────────────────────────────────────
  Future<bool> removeLog(int index) async {
    final target = logsNotifier.value[index];
    final isOwner = target.authorId == currentUserId;

    // FR-03: Guard — tolak jika tidak punya izin
    if (!AccessControlService.canPerform(
      currentUserRole,
      AccessControlService.actionDelete,
      isOwner: isOwner,
    )) {
      await LogHelper.writeLog(
        "SECURITY: Unauthorized delete attempt by '$currentUserId' "
        "(role: $currentUserRole, isOwner: $isOwner)",
        source: "log_controller.dart",
        level: 1,
      );
      return false; // ← kembalikan false agar UI bisa tampilkan pesan error
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
    return true;
  }

  // ─── CONNECTIVITY LISTENER ────────────────────────────────────────────────────
  void startConnectivityListener(String teamId) {
    Connectivity().onConnectivityChanged.listen((result) async {
      final isOnline = result != ConnectivityResult.none;
      if (isOnline) {
        await LogHelper.writeLog(
          "CONNECTIVITY: Internet kembali, memulai sync...",
          source: "log_controller.dart",
          level: 2,
        );
        await syncPendingLogs();
        await loadLogs(teamId);
      }
    });
  }
}