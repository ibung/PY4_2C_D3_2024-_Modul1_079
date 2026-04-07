import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_079/features/logbook/models/log_model.dart';
import 'package:logbook_app_079/features/logbook/log_controller.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final String currentUserId;
  final String currentUserRole;
  final String currentTeamId;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
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

  static const List<String> _categories = [
    'Pekerjaan',
    'Pribadi',
    'Urgent',
    'Lainnya',
  ];
  late String _selectedCategory;

  // Contoh markdown yang ditampilkan sebagai hint saat deskripsi kosong
  static const String _markdownHint = '''
**Contoh penggunaan Markdown:**

# Judul Besar
## Sub Judul

**Teks tebal**, *teks miring*, ~~dicoret~~

Daftar item:
- Item pertama
- Item kedua
  - Sub item

Kode inline: `int x = 5;`

Blok kode:
```dart
void main() {
  print('Hello World');
}
```

> Ini adalah blockquote

---
Garis pemisah di atas
''';

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.log?.title ?? '');
    _descController =
        TextEditingController(text: widget.log?.description ?? '');
    _selectedCategory = widget.log?.category ?? 'Pribadi';

    _descController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul tidak boleh kosong'),
          backgroundColor: Color(0xFF1E3A5F),
        ),
      );
      return;
    }

    if (widget.log == null) {
      widget.controller.addLog(
        title,
        desc,
        _selectedCategory,
        widget.currentUserId,
        widget.currentTeamId,
      );
    } else {
      widget.controller.updateLog(
        widget.index!,
        title,
        desc,
        _selectedCategory,
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.log != null;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A5F),
          foregroundColor: Colors.white,
          title: Text(
            isEdit ? 'Edit Catatan' : 'Catatan Baru',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: Icon(Icons.edit_note), text: 'Editor'),
              Tab(icon: Icon(Icons.preview), text: 'Pratinjau'),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Simpan',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // ── TAB 1: EDITOR ───────────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Judul',
                      hintText: 'Contoh: Praktikum Modul 5',
                      prefixIcon: const Icon(Icons.title,
                          color: Color(0xFF1E3A5F)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dropdown Kategori
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: const Icon(Icons.label_outline,
                          color: Color(0xFF1E3A5F)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _categories
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Info markdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Deskripsi mendukung format Markdown. '
                            'Lihat tab Pratinjau untuk melihat hasilnya.',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Area deskripsi
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _descController,
                      maxLines: 15,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _markdownHint,
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontFamily: 'monospace',
                            fontSize: 13),
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tombol simpan bawah (kemudahan)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: Text(
                        isEdit ? 'Perbarui Catatan' : 'Simpan Catatan',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── TAB 2: PRATINJAU MARKDOWN ───────────────────
            _descController.text.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.preview,
                            size: 64,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada konten untuk dipratinjau',
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tulis sesuatu di tab Editor',
                          style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : Markdown(
                    data: _descController.text,
                    padding: const EdgeInsets.all(16),
                    styleSheet: MarkdownStyleSheet(
                      h1: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F)),
                      h2: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F)),
                      code: TextStyle(
                        backgroundColor: Colors.grey.shade100,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                              color: Colors.grey.shade400, width: 4),
                        ),
                        color: Colors.grey.shade50,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}