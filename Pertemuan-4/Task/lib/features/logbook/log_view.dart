import 'package:flutter/material.dart';
import '../auth/login_view.dart';
import 'package:logbook_app_079/models/logbook_model.dart';
import 'package:logbook_app_079/services/mongo_service.dart';
import 'package:logbook_app_079/helpers/log_helper.dart';

/// Task 3: Async-Reactive Flow — MERGED dengan fitur UI lama
///
/// Fitur gabungan:
/// - Parameter [username] dipertahankan dari versi lama (agar login_view.dart tidak error)
/// - Greeting dinamik (Pagi/Siang/Sore/Malam) dari versi lama
/// - Search bar dari versi lama
/// - Swipe-to-delete (Dismissible) dari versi lama
/// - Dropdown kategori dari versi lama
/// - FutureBuilder + CircularProgressIndicator (Task 3)
/// - Pesan "Data Kosong" (Task 3)
/// - Auto-refresh via setState (Task 3)
/// - Smart logging via LogHelper di setiap aksi (Task 4)
class LogView extends StatefulWidget {
  final String username; // ← Dipertahankan agar login_view.dart tidak error
  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  // ── Controllers ──────────────────────────────────────────
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  // ── Kategori ─────────────────────────────────────────────
  static const List<String> _categories = [
    'Pekerjaan',
    'Pribadi',
    'Urgent',
    'Lainnya',
  ];
  String _selectedCategory = 'Pribadi';

  // ── Task 3: Future dikontrol manual untuk auto-refresh ───
  late Future<List<Logbook>> _logsFuture;

  // ── Task 4: Source identifier untuk LogHelper ────────────
  final String _source = "log_view.dart";

  // ── Search query filter client-side ──────────────────────
  String _searchQuery = '';

  // ── Greeting dinamik ─────────────────────────────────────
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return "Selamat Pagi";
    if (h < 15) return "Selamat Siang";
    if (h < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // LOAD / REFRESH DATA (Task 3)
  // ─────────────────────────────────────────────────────────

  void _loadLogs() {
    setState(() {
      _logsFuture = MongoService().getLogs();
    });
    LogHelper.writeLog(
      "FutureBuilder: Fetch ulang data dari Atlas.",
      source: _source,
      level: 3,
    );
  }

  /// Filter client-side berdasarkan search query
  List<Logbook> _applySearch(List<Logbook> logs) {
    if (_searchQuery.trim().isEmpty) return logs;
    final q = _searchQuery.toLowerCase();
    return logs
        .where(
          (l) =>
              l.title.toLowerCase().contains(q) ||
              l.description.toLowerCase().contains(q),
        )
        .toList();
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),

      // ── APP BAR ──────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        title: const Text(
          "Daily Logger",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh dari Atlas',
            onPressed: _loadLogs,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _showLogoutDialog,
          ),
        ],
      ),

      body: Column(
        children: [
          // ── HEADER GREETING ────────────────────────────
          Container(
            width: double.infinity,
            color: const Color(0xFF1E3A5F),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              "$_greeting, ${widget.username} 👋",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // ── SEARCH BAR ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
              decoration: InputDecoration(
                hintText: "Cari catatan...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // ── LIST CATATAN (Task 3: FutureBuilder) ───────
          Expanded(
            child: FutureBuilder<List<Logbook>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                // STATE 1: Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF1E3A5F)),
                        SizedBox(height: 16),
                        Text(
                          "Menghubungkan ke MongoDB Atlas...",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // STATE 2: Error koneksi
                if (snapshot.hasError) {
                  LogHelper.writeLog(
                    "FutureBuilder Error: ${snapshot.error}",
                    source: _source,
                    level: 1,
                  );
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_off,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Gagal terhubung ke Atlas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadLogs,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A5F),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // STATE 3 & 4: Data siap
                final List<Logbook> allLogs = snapshot.data ?? [];
                final List<Logbook> logs = _applySearch(allLogs);

                // STATE 3: Kosong (Task 3)
                if (logs.isEmpty) return _buildEmptyState();

                // STATE 4: Tampilkan list
                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final Logbook log = logs[index];

                    // SWIPE TO DELETE (dari versi lama)
                    return Dismissible(
                      key: Key(
                        log.id?.toHexString() ??
                            '${log.title}_${log.date.millisecondsSinceEpoch}',
                      ),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (_) async {
                        if (log.id != null) {
                          await MongoService().deleteLog(log.id!);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${log.title}" dihapus'),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                        // Task 3: Auto-refresh setelah swipe delete
                        _loadLogs();
                      },
                      child: _LogCard(
                        log: log,
                        onEdit: () => _showEditDialog(log),
                        onDelete: () => _confirmDelete(log),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ── FAB TAMBAH ─────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Tambah"),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // EMPTY STATE (gabungan versi lama + Task 3)
  // ─────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchCtrl.text.isEmpty
                ? "Belum ada catatan"
                : "Catatan tidak ditemukan",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchCtrl.text.isEmpty
                ? "Tap tombol + untuk mulai mencatat 🚀"
                : "Coba kata kunci lain",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // DIALOG: TAMBAH LOG
  // ─────────────────────────────────────────────────────────

  void _showAddDialog() {
    _titleCtrl.clear();
    _descCtrl.clear();
    _selectedCategory = 'Pribadi';

    showDialog(
      context: context,
      builder: (ctx) => _buildDialog(
        title: "Tambah Catatan",
        onSave: () async {
          if (_titleCtrl.text.trim().isEmpty) return;
          Navigator.pop(ctx);

          final Logbook newLog = Logbook(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            date: DateTime.now(),
            category: _selectedCategory,
          );

          await MongoService().insertLog(newLog);
          // Task 3: Auto-refresh setelah insert
          _loadLogs();
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // DIALOG: EDIT LOG
  // ─────────────────────────────────────────────────────────

  void _showEditDialog(Logbook log) {
    _titleCtrl.text = log.title;
    _descCtrl.text = log.description;
    _selectedCategory = log.category ?? 'Pribadi';

    showDialog(
      context: context,
      builder: (ctx) => _buildDialog(
        title: "Edit Catatan",
        saveLabel: "Update",
        onSave: () async {
          if (_titleCtrl.text.trim().isEmpty) return;
          Navigator.pop(ctx);

          final Logbook updated = Logbook(
            id: log.id,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            date: log.date,
            category: _selectedCategory,
          );

          await MongoService().updateLog(updated);
          // Task 3: Auto-refresh setelah update
          _loadLogs();
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // CONFIRM DELETE (via tombol popup menu)
  // ─────────────────────────────────────────────────────────

  void _confirmDelete(Logbook log) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Catatan?"),
        content: Text('Yakin ingin menghapus "${log.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (log.id != null) {
                await MongoService().deleteLog(log.id!);
              }
              // Task 3: Auto-refresh setelah delete
              _loadLogs();
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // REUSABLE DIALOG BUILDER (dari versi lama, + dropdown kategori)
  // ─────────────────────────────────────────────────────────

  Widget _buildDialog({
    required String title,
    required VoidCallback onSave,
    String saveLabel = "Simpan",
  }) {
    return StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: "Judul",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Deskripsi",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Kategori:",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map(
                      (cat) =>
                          DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => _selectedCategory = val);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
              foregroundColor: Colors.white,
            ),
            child: Text(saveLabel),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // DIALOG LOGOUT (dari versi lama)
  // ─────────────────────────────────────────────────────────

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
              );
            },
            child: const Text(
              "Ya, Keluar",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// WIDGET: CARD ITEM LOG
// ─────────────────────────────────────────────────────────

class _LogCard extends StatelessWidget {
  final Logbook log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LogCard({
    required this.log,
    required this.onEdit,
    required this.onDelete,
  });

  Color _categoryColor(String? cat) {
    switch (cat) {
      case 'Urgent':
        return Colors.red.shade100;
      case 'Pekerjaan':
        return Colors.blue.shade100;
      case 'Pribadi':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1E3A5F).withOpacity(0.1),
          child: const Icon(Icons.article, color: Color(0xFF1E3A5F)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                log.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (log.category != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _categoryColor(log.category),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.category!,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (log.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                log.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${log.date.day.toString().padLeft(2, '0')}-'
              '${log.date.month.toString().padLeft(2, '0')}-'
              '${log.date.year}  '
              '${log.date.hour.toString().padLeft(2, '0')}:'
              '${log.date.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(
              value: 'delete',
              child: Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}