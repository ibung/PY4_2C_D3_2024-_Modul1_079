import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../auth/login_view.dart';
import 'package:logbook_app_079/models/logbook_model.dart';
import 'package:logbook_app_079/services/mongo_service.dart';
import 'package:logbook_app_079/helpers/log_helper.dart';
import 'package:logbook_app_079/features/logbook/log_editor_page.dart';
import 'package:logbook_app_079/features/logbook/log_controller.dart';
import 'package:logbook_app_079/features/logbook/models/log_model.dart';
import 'package:logbook_app_079/services/access_control_service.dart';

class LogView extends StatefulWidget {
  final String username;
  final String userId;
  final String userRole;

  const LogView({
    super.key,
    required this.username,
    required this.userId,
    required this.userRole,
  });

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  static const List<String> _categories = [
    'Pekerjaan', 'Pribadi', 'Urgent', 'Lainnya',
  ];
  String _selectedCategory = 'Pribadi';

  late String _currentUserId;
  late String _currentUserRole;

  late Future<List<Logbook>> _logsFuture;
  late final LogController _logController;

  final String _source = "log_view.dart";
  String _searchQuery = '';
  bool _isOffline = false;

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
    _currentUserId = widget.userId;
    _currentUserRole = widget.userRole;

    _logController = LogController()
      ..currentUserId = _currentUserId
      ..currentUserRole = _currentUserRole;
    _logController.startConnectivityListener('');
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
  // CONNECTION GUARD
  // ─────────────────────────────────────────────────────────

  Future<bool> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // LOAD / REFRESH
  // ─────────────────────────────────────────────────────────

  void _loadLogs() {
    setState(() {
      _logsFuture = _fetchWithConnectionGuard();
    });
    LogHelper.writeLog(
      "FutureBuilder: Fetch ulang data dari Atlas.",
      source: _source,
      level: 3,
    );
  }

  Future<List<Logbook>> _fetchWithConnectionGuard() async {
    final bool online = await _checkConnection();

    if (!online) {
      setState(() => _isOffline = true);
      LogHelper.writeLog(
        "OFFLINE: Tidak ada koneksi, memuat dari Hive cache.",
        source: _source,
        level: 1,
      );
      // Ambil dari Hive saat offline, convert ke Logbook
      final hiveData = _logController.logsNotifier.value;
      if (hiveData.isNotEmpty) {
        return hiveData.map((lm) => Logbook(
          title: lm.title,
          description: lm.description,
          date: DateTime.tryParse(lm.timestamp) ?? DateTime.now(),
          category: lm.category,
          authorId: lm.authorId,
          teamId: lm.teamId,
        )).toList();
      }
      throw Exception(
        "Tidak ada koneksi internet.\nPastikan Wi-Fi atau data seluler aktif, lalu coba lagi.",
      );
    }

    setState(() => _isOffline = false);
    final logs = await MongoService().getLogs();

    // Sync ke Hive saat online agar cache selalu fresh
    await _logController.loadLogs('');

    return logs;
  }

  Future<void> _onRefresh() async {
    LogHelper.writeLog(
      "Pull-to-Refresh: User menarik layar untuk refresh.",
      source: _source,
      level: 3,
    );
    _loadLogs();
    await _logsFuture.catchError((_) {});
  }

  List<Logbook> _applySearch(List<Logbook> logs) {
    if (_searchQuery.trim().isEmpty) return logs;
    final q = _searchQuery.toLowerCase();
    return logs
        .where((l) =>
            l.title.toLowerCase().contains(q) ||
            l.description.toLowerCase().contains(q))
        .toList();
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return "Baru saja";
    if (diff.inMinutes < 60) return "${diff.inMinutes} menit yang lalu";
    if (diff.inHours < 24) return "${diff.inHours} jam yang lalu";
    if (diff.inDays == 1) return "Kemarin";
    if (diff.inDays < 7) return "${diff.inDays} hari yang lalu";
    return DateFormat("d MMM yyyy", "id_ID").format(date);
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        title: const Text(
          "Daily Logger",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Badge role di appbar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: _currentUserRole == 'Ketua'
                  ? Colors.amber.shade700
                  : Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _currentUserRole,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 4),
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
          // ── HEADER GREETING ──────────────────────────
          Container(
            width: double.infinity,
            color: const Color(0xFF1E3A5F),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              "$_greeting, ${widget.username}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // ── OFFLINE BANNER ───────────────────────────
          if (_isOffline)
            Container(
              width: double.infinity,
              color: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Offline Mode — Menampilkan data cache lokal",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _loadLogs,
                    child: const Text(
                      "Coba Lagi",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── SEARCH BAR ───────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val),
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

          // ── LIST CATATAN ─────────────────────────────
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

                // STATE 2: Error
                if (snapshot.hasError) {
                  LogHelper.writeLog(
                    "FutureBuilder Error: ${snapshot.error}",
                    source: _source,
                    level: 1,
                  );
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isOffline ? Icons.wifi_off : Icons.cloud_off,
                            size: 72,
                            color: _isOffline
                                ? Colors.orange.shade400
                                : Colors.red.shade300,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _isOffline
                                ? "Kamu Sedang Offline"
                                : "Gagal Terhubung ke Server",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isOffline
                                ? "Aktifkan Wi-Fi atau data seluler,\nlalu tarik layar ke bawah untuk refresh."
                                : "Server tidak merespons.\nCek koneksi atau coba beberapa saat lagi.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton.icon(
                            onPressed: _loadLogs,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Coba Lagi"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A5F),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
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

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: const Color(0xFF1E3A5F),
                  strokeWidth: 2.5,
                  child: logs.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: _buildEmptyState(),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final Logbook log = logs[index];
                            return Dismissible(
                              key: Key(
                                log.id?.toHexString() ??
                                    '${log.title}_${log.date.millisecondsSinceEpoch}',
                              ),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (_) async {
                                // ← TAMBAH: cek izin sebelum hapus
                                final isOwner = log.authorId == _currentUserId;
                                if (!AccessControlService.canPerform(
                                  _currentUserRole,
                                  AccessControlService.actionDelete,
                                  isOwner: isOwner,
                                )) {
                                  // Batalkan dismiss — reload agar item muncul kembali
                                  _loadLogs();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Anda tidak punya izin untuk menghapus catatan ini'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                // Hapus dari DB
                                if (log.id != null) {
                                  await MongoService().deleteLog(log.id!);
                                }
                                // Hapus dari Hive juga
                                final hiveIndex = _logController.logsNotifier.value
                                    .indexWhere((l) => l.id == log.id?.toHexString());
                                if (hiveIndex != -1) {
                                  await _logController.removeLog(hiveIndex);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('"${log.title}" dihapus'),
                                      backgroundColor: Colors.red.shade700,
                                    ),
                                  );
                                }
                                _loadLogs();
                              },
                              child: _LogCard(
                                log: log,
                                timestamp: _formatTimestamp(log.date),
                                onEdit: () => _goToEditor(
                                  log: LogModel(
                                    id: log.id?.toHexString(),
                                    title: log.title,
                                    description: log.description,
                                    timestamp: log.date.toIso8601String(),
                                    category: log.category ?? 'Pribadi',
                                    authorId: log.authorId ?? _currentUserId,
                                    teamId: log.teamId ?? '',
                                  ),
                                  index: index,
                                ),
                                onDelete: () => _confirmDelete(log),
                                currentUserId: _currentUserId,
                                currentUserRole: _currentUserRole,
                              ),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _goToEditor(),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Tambah"),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // EMPTY STATE
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
                ? "Tap tombol + untuk mulai mencatat"
                : "Coba kata kunci lain",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // NAVIGATION & DIALOGS
  // ─────────────────────────────────────────────────────────

  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LogEditorPage(
          log: log,
          index: index,
          controller: _logController,
          currentUserId: _currentUserId,
          currentUserRole: _currentUserRole,
          currentTeamId: '',
        ),
      ),
    ).then((_) => _loadLogs());
  }

  void _confirmDelete(Logbook log) {
    final isOwner = log.authorId == _currentUserId;
    if (!AccessControlService.canPerform(
      _currentUserRole,
      AccessControlService.actionDelete,
      isOwner: isOwner,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak punya izin untuk menghapus catatan ini'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
              if (log.id != null) await MongoService().deleteLog(log.id!);
              final hiveIndex = _logController.logsNotifier.value
                  .indexWhere((l) => l.id == log.id?.toHexString());
              if (hiveIndex != -1) {
                await _logController.removeLog(hiveIndex);
              }
              _loadLogs();
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  Widget _buildDialog({
    required String title,
    required VoidCallback onSave,
    String saveLabel = "Simpan",
  }) {
    return StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
              const Text("Kategori:",
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration:
                    const InputDecoration(border: OutlineInputBorder()),
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
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
            child: const Text("Ya, Keluar",
                style: TextStyle(color: Colors.red)),
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
  final String timestamp;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String currentUserId;
  final String currentUserRole;

  const _LogCard({
    required this.log,
    required this.timestamp,
    required this.onEdit,
    required this.onDelete,
    required this.currentUserId,
    required this.currentUserRole,
  });

  Color _categoryColor(String? cat) {
    switch (cat) {
      case 'Urgent': return Colors.red.shade100;
      case 'Pekerjaan': return Colors.blue.shade100;
      case 'Pribadi': return Colors.green.shade100;
      default: return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = log.authorId == currentUserId;
    final canEdit = AccessControlService.canPerform(
      currentUserRole, AccessControlService.actionUpdate,
      isOwner: isOwner,
    );
    final canDelete = AccessControlService.canPerform(
      currentUserRole, AccessControlService.actionDelete,
      isOwner: isOwner,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1E3A5F).withOpacity(0.1),
          child: const Icon(Icons.article, color: Color(0xFF1E3A5F)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(log.title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (log.category != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _categoryColor(log.category),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(log.category!,
                    style: const TextStyle(fontSize: 10)),
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
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 11, color: Colors.grey),
                const SizedBox(width: 4),
                Text(timestamp,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
                // ← Tampilkan pemilik catatan
                const Spacer(),
                Text(
                  "by ${log.authorId ?? 'unknown'}",
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade400),
                ),
              ],
            ),
          ],
        ),
        trailing: (canEdit || canDelete)
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (ctx) => [
                  if (canEdit)
                    const PopupMenuItem(
                        value: 'edit', child: Text('Edit')),
                  if (canDelete)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Hapus',
                          style: TextStyle(color: Colors.red)),
                    ),
                ],
              )
            : const Icon(Icons.lock_outline,
                color: Colors.grey, size: 18),
      ),
    );
  }
}