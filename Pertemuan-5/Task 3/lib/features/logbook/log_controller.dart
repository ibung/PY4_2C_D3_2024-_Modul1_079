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

  Box<LogModel> get _myBox => Hive.box<LogModel>('offline_logs');

  // ─── LOAD (Offline-First) ────────────────────────────────
  Future<void> loadLogs(String teamId) async {
    logsNotifier.value = _myBox.values.toList();

    try {
      final cloudData = await MongoService().getLogsByTeam(teamId);
      await _myBox.clear();
      await _myBox.addAll(cloudData);
      logsNotifier.value = cloudData;
      await LogHelper.writeLog(
        "SYNC: Data berhasil diperbarui dari Atlas",
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

  // ─── ADD ────────────────────────────────────────────────
  Future<void> addLog(
    String title,
    String description,
    String category,
  ) async {
    final newLog = LogModel(
      id: mongo.ObjectId().oid,
      title: title,
      description: description,
      timestamp: DateTime.now().toIso8601String(),
      category: category,
      authorId: currentUserId,
      teamId: '',
    );

    await _myBox.add(newLog);
    logsNotifier.value = [...logsNotifier.value, newLog];

    try {
      await MongoService().insertLogModel(newLog);
      await LogHelper.writeLog(
        "SUCCESS: Data tersinkron ke Cloud",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Data tersimpan lokal, akan sinkron saat online - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // ─── UPDATE ─────────────────────────────────────────────
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

    final updated = LogModel(
      id: target.id,
      title: title,
      description: description,
      timestamp: DateTime.now().toIso8601String(),
      category: category,
      authorId: target.authorId,
      teamId: target.teamId,
    );

    final hiveIndex = _myBox.values.toList().indexWhere((l) => l.id == target.id);
    if (hiveIndex != -1) await _myBox.putAt(hiveIndex, updated);

    final list = List<LogModel>.from(logsNotifier.value);
    list[index] = updated;
    logsNotifier.value = list;

    try {
      await MongoService().updateLogModel(updated);
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Gagal sync update ke Atlas - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // ─── DELETE ─────────────────────────────────────────────
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

    final hiveIndex = _myBox.values.toList().indexWhere((l) => l.id == target.id);
    if (hiveIndex != -1) await _myBox.deleteAt(hiveIndex);

    final list = List<LogModel>.from(logsNotifier.value);
    list.removeAt(index);
    logsNotifier.value = list;

    if (target.id != null) {
      try {
        await MongoService().deleteLog(mongo.ObjectId.fromHexString(target.id!));
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
  void startConnectivityListener(String teamId) {
    Connectivity().onConnectivityChanged.listen((result) async {
      final isOnline = result != ConnectivityResult.none;
      if (isOnline) {
        await LogHelper.writeLog(
          "CONNECTIVITY: Internet kembali, memulai sync...",
          source: "log_controller.dart",
          level: 2,
        );
        await loadLogs(teamId);
      }
    });
  }
}