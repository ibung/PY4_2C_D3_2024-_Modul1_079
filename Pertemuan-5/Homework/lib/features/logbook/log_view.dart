import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import '../auth/login_view.dart';
import 'package:logbook_app_079/services/mongo_service.dart';
import 'package:logbook_app_079/helpers/log_helper.dart';
import 'package:logbook_app_079/features/logbook/log_editor_page.dart';
import 'package:logbook_app_079/features/logbook/log_controller.dart';
import 'package:logbook_app_079/features/logbook/models/log_model.dart';
import 'package:lottie/lottie.dart';

class LogView extends StatefulWidget {
  final String username;
  final String userId;
  final String userRole;
  final String teamId;

  const LogView({
    super.key,
    required this.username,
    required this.userId,
    required this.userRole,
    required this.teamId,
  });

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final TextEditingController _searchCtrl = TextEditingController();

  late String _currentUserId;
  late String _currentUserRole;

  // ✅ FIX: Inisial dengan Future.value([]) untuk hindari Late Initialization Error
  late Future<List<LogModel>> _logsFuture = Future.value([]);
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
      ..currentUserRole = _currentUserRole
      ..currentTeamId = widget.teamId;
    _logController.startConnectivityListener(widget.teamId);
    _loadLogs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<bool> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _loadLogs() {
    // ✅ FIX: Panggil _fetchLogs() di luar setState dulu,
    //         baru assign Future-nya ke dalam setState.
    //         setState TIDAK boleh menerima closure yang return Future.
    final future = _fetchLogs();
    setState(() => _logsFuture = future);
    LogHelper.writeLog(
      "FutureBuilder: Fetch ulang data dari Atlas.",
      source: _source,
      level: 3,
    );
  }

  // ─── FETCH (PERBAIKAN UTAMA) ──────────────────────────────────────────────
  // BUG LAMA: fetch lewat _logController.loadLogs() lalu baca logsNotifier.value
  //           → nilainya tidak dijamin sinkron, bisa kembalikan data Hive lama.
  // FIX: ambil langsung dari MongoService, update notifier di background.
  Future<List<LogModel>> _fetchLogs() async {
    final bool online = await _checkConnection();

    if (!online) {
      if (mounted) setState(() => _isOffline = true);
      LogHelper.writeLog(
        "OFFLINE: Tidak ada koneksi, memuat dari Hive cache.",
        source: _source,
        level: 1,
      );
      final hiveData = _logController.logsNotifier.value;
      if (hiveData.isNotEmpty) return hiveData;
      throw Exception(
        "Tidak ada koneksi internet.\n"
        "Pastikan Wi-Fi atau data seluler aktif, lalu coba lagi.",
      );
    }

    if (mounted) setState(() => _isOffline = false);

    // Ambil langsung dari Atlas — hasilnya pasti sinkron
    final List<LogModel> cloudData = await MongoService().getLogsByTeam(
      widget.teamId,
    );

    // Update notifier di background (tidak block return)
    _logController.logsNotifier.value = cloudData;

    return cloudData;
  }

  Future<void> _onRefresh() async {
    _loadLogs();
    await _logsFuture.catchError((_) => <LogModel>[]);
  }

  // ─── FILTER VISIBILITY ────────────────────────────────────────────────────
  // BUG LAMA: isPublic null → default true, jadi semua log orang lain ikut tampil.
  // FIX: tampilkan hanya milik sendiri ATAU yang benar-benar isPublic == true.
  List<LogModel> _applyVisibility(List<LogModel> logs) {
    return logs.where((log) {
      final isOwner =
          log.authorId.trim().toLowerCase() ==
          _currentUserId.trim().toLowerCase();
      return isOwner || log.isPublic;
    }).toList();
  }

  List<LogModel> _applySearch(List<LogModel> logs) {
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

  String _formatTimestamp(String timestamp) {
    final date = DateTime.tryParse(timestamp) ?? DateTime.now();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return "Baru saja";
    if (diff.inMinutes < 60) return "${diff.inMinutes} menit yang lalu";
    if (diff.inHours < 24) return "${diff.inHours} jam yang lalu";
    if (diff.inDays == 1) return "Kemarin";
    if (diff.inDays < 7) return "${diff.inDays} hari yang lalu";
    return DateFormat("d MMM yyyy", "id_ID").format(date);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              'https://lottie.host/embed/4be2f986-5093-468a-946a-720eb20154ad/Z8t01bhSbi.lottie',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.inbox_outlined,
                size: 100,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Belum ada aktivitas hari ini?\nMulai catat kemajuan proyek Anda!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
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
          Expanded(
            child: FutureBuilder<List<LogModel>>(
              future: _logsFuture,
              builder: (context, snapshot) {
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

                if (snapshot.hasError) {
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
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final List<LogModel> allLogs = snapshot.data ?? [];
                final List<LogModel> visibleLogs = _applyVisibility(allLogs);
                final List<LogModel> logs = _applySearch(visibleLogs);

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
                            final LogModel log = logs[index];
                            return Dismissible(
                              key: Key(log.id ?? '${log.title}_$index'),
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
                                final isOwner =
                                    log.authorId.trim().toLowerCase() ==
                                    _currentUserId.trim().toLowerCase();
                                if (!isOwner) {
                                  _loadLogs();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Hanya pemilik catatan yang bisa menghapus',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                final hiveIndex = _logController
                                    .logsNotifier
                                    .value
                                    .indexWhere((l) => l.id == log.id);
                                if (hiveIndex != -1) {
                                  await _logController.removeLog(hiveIndex);
                                }
                                if (log.id != null) {
                                  try {
                                    await MongoService().deleteLog(
                                      ObjectId.fromHexString(log.id!),
                                    );
                                  } catch (_) {}
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
                                timestamp: _formatTimestamp(log.timestamp),
                                onEdit: () => _goToEditor(log: log),
                                onDelete: () => _confirmDelete(log),
                                currentUserId: _currentUserId,
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

  void _goToEditor({LogModel? log}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LogEditorPage(
          log: log,
          controller: _logController,
          currentUserId: _currentUserId,
          currentUserRole: _currentUserRole,
          currentTeamId: widget.teamId,
        ),
      ),
    ).then((_) => _loadLogs());
  }

  void _confirmDelete(LogModel log) {
    final isOwner =
        log.authorId.trim().toLowerCase() ==
        _currentUserId.trim().toLowerCase();
    if (!isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hanya pemilik catatan yang bisa menghapus'),
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
              final hiveIndex = _logController.logsNotifier.value.indexWhere(
                (l) => l.id == log.id,
              );
              if (hiveIndex != -1) {
                await _logController.removeLog(hiveIndex);
              }
              if (log.id != null) {
                try {
                  await MongoService().deleteLog(
                    ObjectId.fromHexString(log.id!),
                  );
                } catch (_) {}
              }
              _loadLogs();
            },
            child: const Text("Hapus"),
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

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET: CARD ITEM LOG
// ─────────────────────────────────────────────────────────────────────────────

class _LogCard extends StatelessWidget {
  final LogModel log;
  final String timestamp;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String currentUserId;

  const _LogCard({
    required this.log,
    required this.timestamp,
    required this.onEdit,
    required this.onDelete,
    required this.currentUserId,
  });

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Mechanical':
        return Colors.green.shade100;
      case 'Electronic':
        return Colors.blue.shade100;
      case 'Software':
        return Colors.purple.shade100;
      case 'Urgent':
        return Colors.red.shade100;
      case 'Pekerjaan':
        return Colors.orange.shade100;
      case 'Pribadi':
        return Colors.teal.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _categoryBorderColor(String cat) {
    switch (cat) {
      case 'Mechanical':
        return Colors.green.shade400;
      case 'Electronic':
        return Colors.blue.shade400;
      case 'Software':
        return Colors.purple.shade400;
      case 'Urgent':
        return Colors.red.shade400;
      case 'Pekerjaan':
        return Colors.orange.shade400;
      case 'Pribadi':
        return Colors.teal.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  Color _categoryTextColor(String cat) {
    switch (cat) {
      case 'Mechanical':
        return Colors.green.shade800;
      case 'Electronic':
        return Colors.blue.shade800;
      case 'Software':
        return Colors.purple.shade800;
      case 'Urgent':
        return Colors.red.shade800;
      case 'Pekerjaan':
        return Colors.orange.shade800;
      case 'Pribadi':
        return Colors.teal.shade800;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Mechanical':
        return Icons.settings;
      case 'Electronic':
        return Icons.electrical_services;
      case 'Software':
        return Icons.code;
      case 'Urgent':
        return Icons.priority_high;
      case 'Pekerjaan':
        return Icons.work_outline;
      case 'Pribadi':
        return Icons.person_outline;
      default:
        return Icons.label_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner =
        log.authorId.trim().toLowerCase() == currentUserId.trim().toLowerCase();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: _categoryBorderColor(log.category),
              width: 5,
            ),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF1E3A5F).withOpacity(0.1),
            child: Icon(
              _categoryIcon(log.category),
              color: const Color(0xFF1E3A5F),
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  log.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Tooltip(
                message: log.isPublic ? 'Publik' : 'Privat',
                child: Icon(
                  log.isPublic ? Icons.public : Icons.lock_outline,
                  size: 14,
                  color: log.isPublic ? Colors.green.shade600 : Colors.grey,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _categoryColor(log.category),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _categoryIcon(log.category),
                      size: 10,
                      color: _categoryTextColor(log.category),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      log.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: _categoryTextColor(log.category),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (log.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                LayoutBuilder(
                  builder: (context, _) {
                    final lines = log.description.split('\n');
                    final preview = lines.take(3).join('\n');
                    final isTruncated =
                        lines.length > 3 || log.description.length > 120;
                    final displayText = isTruncated
                        ? '${preview.length > 120 ? preview.substring(0, 120) : preview}...'
                        : preview;
                    return MarkdownBody(
                      data: displayText,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                        strong: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        em: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                        ),
                      ),
                      shrinkWrap: true,
                      softLineBreak: true,
                    );
                  },
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 11, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    timestamp,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    "by ${log.authorId} · ${log.teamId}",
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],
          ),
          trailing: isOwner
              ? PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Hapus', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                )
              : const Icon(Icons.lock_outline, color: Colors.grey, size: 18),
        ),
      ),
    );
  }
}
