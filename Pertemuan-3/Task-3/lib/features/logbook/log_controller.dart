import 'package:flutter/material.dart';
import 'models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);

  void addLog(String title, String description) {
    final newLog = LogModel(
      title: title,
      description: description,
      timestamp: DateTime.now().toString(),
    );

    logsNotifier.value = [...logsNotifier.value, newLog];
  }

  void updateLog(int index, String title, String description) {
    final updatedList = List<LogModel>.from(logsNotifier.value);

    updatedList[index] = LogModel(
      title: title,
      description: description,
      timestamp: DateTime.now().toString(),
    );

    logsNotifier.value = updatedList;
  }

  void removeLog(int index) {
    final updatedList = List<LogModel>.from(logsNotifier.value);
    updatedList.removeAt(index);
    logsNotifier.value = updatedList;
  }
}