import 'package:flutter/material.dart';
import 'log_controller.dart';
import 'models/log_model.dart';
import 'widgets/log_item_widget.dart';

class LogView extends StatefulWidget {
  const LogView({super.key});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final LogController _controller = LogController();

  final TextEditingController _titleController =
      TextEditingController();
  final TextEditingController _descController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Logger"),
      ),

      body: ValueListenableBuilder<List<LogModel>>(
        valueListenable: _controller.logsNotifier,
        builder: (context, logs, child) {
          if (logs.isEmpty) {
            return const Center(
              child: Text("Belum ada catatan."),
            );
          }

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];

              return LogItemWidget(
                log: log,
                onEdit: () =>
                    _showEditDialog(index, log),
                onDelete: () =>
                    _controller.removeLog(index),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ================= ADD =================
  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Catatan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration:
                  const InputDecoration(labelText: "Judul"),
            ),
            TextField(
              controller: _descController,
              decoration:
                  const InputDecoration(labelText: "Deskripsi"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              _controller.addLog(
                _titleController.text,
                _descController.text,
              );

              _titleController.clear();
              _descController.clear();

              Navigator.pop(context);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  // ================= EDIT =================
  void _showEditDialog(int index, LogModel log) {
    _titleController.text = log.title;
    _descController.text = log.description;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Catatan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController),
            TextField(controller: _descController),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              _controller.updateLog(
                index,
                _titleController.text,
                _descController.text,
              );

              _titleController.clear();
              _descController.clear();

              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
}