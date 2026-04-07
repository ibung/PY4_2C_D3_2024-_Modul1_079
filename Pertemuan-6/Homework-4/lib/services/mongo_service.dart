import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_079/models/logbook_model.dart';
import 'package:logbook_app_079/helpers/log_helper.dart';

class MongoService {
  // --- SINGLETON PATTERN ---
  static final MongoService _instance = MongoService._internal();

  factory MongoService() => _instance;

  MongoService._internal();
  // -------------------------

  /// Koneksi ke MongoDB Atlas (nullable untuk cek status inisialisasi)
  Db? _db;
  DbCollection? _collection;

  // Nama database dan koleksi yang digunakan di Atlas
  static const String _dbName = 'logbook_db';
  static const String _collectionName = 'logs';

  final String _source = "mongo_service.dart";

  /// Fungsi internal untuk memastikan koleksi siap digunakan.
  /// Melakukan reconnect otomatis jika koneksi terputus (Anti-LateInitializationError).
  Future<DbCollection> _getSafeCollection() async {
    if (_db == null || !_db!.isConnected || _collection == null) {
      await LogHelper.writeLog(
        "Koleksi belum siap, mencoba rekoneksi...",
        source: _source,
        level: 3, // VERBOSE — hanya muncul jika LOG_LEVEL=3
      );
      await connect();
    }
    return _collection!;
  }

  // ─────────────────────────────────────────────
  // CONNECT & CLOSE
  // ─────────────────────────────────────────────

  /// Inisialisasi koneksi ke MongoDB Atlas.
  /// Timeout 15 detik untuk toleransi jaringan seluler.
  Future<void> connect() async {
    try {
      final String? dbUri = dotenv.env['MONGODB_URI'];
      if (dbUri == null || dbUri.isEmpty) {
        throw Exception("MONGODB_URI tidak ditemukan di file .env");
      }

      await LogHelper.writeLog(
        "Membuka koneksi ke MongoDB Atlas...",
        source: _source,
        level: 3,
      );

      _db = await Db.create(dbUri);

      await _db!.open().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
            "Koneksi Timeout (15s). Cek IP Whitelist Atlas (0.0.0.0/0) atau sinyal HP.",
          );
        },
      );

      _collection = _db!.collection(_collectionName);

      await LogHelper.writeLog(
        "SUCCESS: Terhubung ke Atlas. DB: '$_dbName', Koleksi: '$_collectionName' siap.",
        source: _source,
        level: 2, // INFO
      );
    } catch (e) {
      await LogHelper.writeLog(
        "GAGAL koneksi ke Atlas: $e",
        source: _source,
        level: 1, // ERROR
      );
      rethrow;
    }
  }

  /// Menutup koneksi ke MongoDB Atlas dengan aman.
  Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      await LogHelper.writeLog(
        "Koneksi ke Atlas ditutup.",
        source: _source,
        level: 2,
      );
    }
  }

  // ─────────────────────────────────────────────
  // CRUD OPERATIONS
  // ─────────────────────────────────────────────

  /// READ: Mengambil semua dokumen dari koleksi 'logs' di Atlas.
  /// Task 3: Dipanggil oleh FutureBuilder di log_view.dart
  Future<List<Logbook>> getLogs() async {
    await LogHelper.writeLog(
      "Memulai fetch data dari Atlas...",
      source: _source,
      level: 3,
    );

    try {
      final DbCollection collection = await _getSafeCollection();
      final List<Map<String, dynamic>> data = await collection.find().toList();

      await LogHelper.writeLog(
        "Berhasil fetch ${data.length} dokumen dari Atlas.",
        source: _source,
        level: 2,
      );

      return data.map((json) => Logbook.fromMap(json)).toList();
    } catch (e) {
      await LogHelper.writeLog(
        "GAGAL fetch data: $e",
        source: _source,
        level: 1,
      );
      return []; // Kembalikan list kosong agar UI tidak crash
    }
  }

  /// CREATE: Menyimpan dokumen baru ke Atlas.
  Future<void> insertLog(Logbook log) async {
    await LogHelper.writeLog(
      "Menyimpan log baru: '${log.title}'",
      source: _source,
      level: 3,
    );

    try {
      final DbCollection collection = await _getSafeCollection();
      await collection.insertOne(log.toMap());

      await LogHelper.writeLog(
        "SUCCESS: Log '${log.title}' berhasil disimpan ke Atlas.",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "GAGAL insert log '${log.title}': $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// UPDATE: Mengganti dokumen berdasarkan ObjectId.
  Future<void> updateLog(Logbook log) async {
    await LogHelper.writeLog(
      "Memperbarui log ID: ${log.id}",
      source: _source,
      level: 3,
    );

    try {
      if (log.id == null) {
        throw Exception("ObjectId null — tidak bisa melakukan update.");
      }

      final DbCollection collection = await _getSafeCollection();
      await collection.replaceOne(where.id(log.id!), log.toMap());

      await LogHelper.writeLog(
        "SUCCESS: Log '${log.title}' (ID: ${log.id}) berhasil diperbarui.",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "GAGAL update log '${log.title}': $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// DELETE: Menghapus dokumen berdasarkan ObjectId.
  Future<void> deleteLog(ObjectId id) async {
    await LogHelper.writeLog(
      "Menghapus log ID: $id",
      source: _source,
      level: 3,
    );

    try {
      final DbCollection collection = await _getSafeCollection();
      await collection.remove(where.id(id));

      await LogHelper.writeLog(
        "SUCCESS: Log ID $id berhasil dihapus dari Atlas.",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "GAGAL hapus log ID $id: $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }
}