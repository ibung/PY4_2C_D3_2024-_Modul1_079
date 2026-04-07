import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_079/features/logbook/models/log_model.dart';
import 'package:logbook_app_079/features/logbook/log_controller.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final LogController controller;
  final String currentUserId;
  final String currentUserRole;
  final String currentTeamId;

  const LogEditorPage({
    super.key,
    this.log,
    required this.controller,
    required this.currentUserId,
    required this.currentUserRole,
    required this.currentTeamId,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  String _selectedCategory = 'Pribadi';
  bool _isPublic = false; // ← TASK 5

  static const List<String> _categories = [
    'Mechanical',
    'Electronic',
    'Software',
    'Pekerjaan',
    'Pribadi',
    'Urgent',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );
    _selectedCategory = widget.log?.category ?? 'Pribadi';
    _isPublic = widget.log?.isPublic ?? false; // ← TASK 5

    _descController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul tidak boleh kosong'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.log == null) {
      await widget.controller.addLog(
        _titleController.text.trim(),
        _descController.text.trim(),
        _selectedCategory,
        isPublic: _isPublic, // ← TASK 5
      );
    } else {
      await widget.controller.updateLog(
        widget.log!.id!,
        _titleController.text.trim(),
        _descController.text.trim(),
        _selectedCategory,
        isPublic: _isPublic, // ← TASK 5
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan berhasil disimpan ✓'),
          backgroundColor: Color(0xFF1E3A5F),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A5F),
          foregroundColor: Colors.white,
          title: Text(
            widget.log == null ? "Catatan Baru" : "Edit Catatan",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Simpan',
              onPressed: () => _save(),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: Icon(Icons.edit_note), text: "Editor"),
              Tab(icon: Icon(Icons.preview), text: "Pratinjau"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ── TAB 1: EDITOR ──────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: "Judul",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Kategori
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: "Kategori",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 8),

                  // ── Toggle Visibilitas (TASK 5) ──────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SwitchListTile(
                      value: _isPublic,
                      onChanged: (val) => setState(() => _isPublic = val),
                      title: Text(
                        _isPublic ? '🌐 Publik' : '🔒 Privat',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _isPublic
                            ? 'Semua anggota tim bisa melihat'
                            : 'Hanya kamu yang bisa melihat',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      activeColor: const Color(0xFF1E3A5F),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Hint Markdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '💡 Mendukung format Markdown: **tebal**, *miring*, # Judul, - list',
                      style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Area tulis
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _descController,
                        maxLines: null,
                        expands: true,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText:
                              "Tulis laporan dengan format Markdown...\n\n"
                              "# Judul Besar\n"
                              "## Sub Judul\n"
                              "**teks tebal**\n"
                              "- item list",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── TAB 2: PRATINJAU ───────────────────────
            _descController.text.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.preview_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada konten untuk ditampilkan',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  )
                : Markdown(
                    data: _descController.text,
                    padding: const EdgeInsets.all(16),
                  ),
          ],
        ),
      ),
    );
  }
}
