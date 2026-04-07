import 'package:flutter/material.dart';
import '../auth/login_view.dart';
import 'log_controller.dart';
import 'models/log_model.dart';
import 'widgets/log_item_widget.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final LogController _controller = LogController();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  // Kategori yang tersedia
  static const List<String> _categories = ['Pekerjaan', 'Pribadi', 'Urgent', 'Lainnya'];
  String _selectedCategory = 'Pribadi';

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return "Selamat Pagi";
    if (h < 15) return "Selamat Siang";
    if (h < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),

      // ===== APP BAR =====
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        title: const Text("Daily Logger", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),

      body: Column(
        children: [
          // ===== HEADER GREETING =====
          Container(
            width: double.infinity,
            color: const Color(0xFF1E3A5F),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              "$_greeting, ${widget.username} 👋",
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),

          // ===== SEARCH BAR =====
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => _controller.searchLog(val),
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

          // ===== LIST CATATAN =====
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.filteredLogs,
              builder: (context, logs, _) {

                // Tampilan saat belum ada catatan
                if (logs.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];

                    // ===== SWIPE TO DELETE =====
                    return Dismissible(
                      key: Key(log.timestamp),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        // Cari index asli di logsNotifier (bukan filteredLogs)
                        final realIndex = _controller.logsNotifier.value
                            .indexWhere((l) => l.timestamp == log.timestamp);
                        if (realIndex != -1) _controller.removeLog(realIndex);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${log.title}" dihapus'),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      },
                      child: LogItemWidget(
                        log: log,
                        onEdit: () {
                          final realIndex = _controller.logsNotifier.value
                              .indexWhere((l) => l.timestamp == log.timestamp);
                          _showEditDialog(realIndex, log);
                        },
                        onDelete: () {
                          final realIndex = _controller.logsNotifier.value
                              .indexWhere((l) => l.timestamp == log.timestamp);
                          if (realIndex != -1) _controller.removeLog(realIndex);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ===== FAB TAMBAH =====
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Tambah"),
      ),
    );
  }

  // ===== EMPTY STATE =====
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Text(
              _searchCtrl.text.isEmpty 
                  ? "Belum ada aktivitas hari ini?" 
                  : "Catatan tidak ditemukan",
              style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              _searchCtrl.text.isEmpty 
                  ? "Mulai catat kemajuan proyek Anda!" 
                  : "Coba kata kunci lain",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, 
                  color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // ===== DIALOG TAMBAH =====
  void _showAddDialog() {
    _titleCtrl.clear();
    _descCtrl.clear();
    _selectedCategory = 'Pribadi';

    showDialog(
      context: context,
      builder: (context) => _buildDialog(
        title: "Tambah Catatan",
        onSave: () {
          if (_titleCtrl.text.trim().isEmpty) return;
          _controller.addLog(_titleCtrl.text.trim(), _descCtrl.text.trim(), _selectedCategory);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ===== DIALOG EDIT =====
  void _showEditDialog(int index, LogModel log) {
    _titleCtrl.text = log.title;
    _descCtrl.text = log.description;
    _selectedCategory = log.category;

    showDialog(
      context: context,
      builder: (context) => _buildDialog(
        title: "Edit Catatan",
        saveLabel: "Update",
        onSave: () {
          if (_titleCtrl.text.trim().isEmpty) return;
          _controller.updateLog(index, _titleCtrl.text.trim(), _descCtrl.text.trim(), _selectedCategory);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ===== REUSABLE DIALOG =====
  Widget _buildDialog({required String title, required VoidCallback onSave, String saveLabel = "Simpan"}) {
    return StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Input judul
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: "Judul", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              // Input deskripsi
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Deskripsi", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              // Dropdown kategori
              const Text("Kategori:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => _selectedCategory = val);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A5F), foregroundColor: Colors.white),
            child: Text(saveLabel),
          ),
        ],
      ),
    );
  }

  // ===== DIALOG LOGOUT =====
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
              );
            },
            child: const Text("Ya, Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}