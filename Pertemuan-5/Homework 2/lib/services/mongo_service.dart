import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_079/models/logbook_model.dart';
import 'package:logbook_app_079/features/logbook/models/log_model.dart';
import 'package:logbook_app_079/helpers/log_helper.dart';

class MongoService {
  static final MongoService _instance = MongoService._internal();
  factory MongoService() => _instance;
  MongoService._internal();

  Db? _db;
  DbCollection? _collection;

  static const String _dbName = 'logbook_db';
  static const String _collectionName = 'logs';
  final String _source = "mongo_service.dart";

  // ─── CONNECTION LOCK ─────────────────────────────────────
  // Mencegah 2 fungsi memanggil connect() bersamaan (race condition).
  // Jika sudah ada proses koneksi berjalan, fungsi lain tunggu dulu.
  bool _isConnecting = false;
  Future<void>? _connectingFuture;

  bool get _isReady =>
      _db != null && _db!.isConnected && _collection != null;

  Future<DbCollection> _getSafeCollection() async {
    if (_isReady) return _collection!;

    // Kalau sedang ada proses connect, tunggu proses itu selesai
    if (_isConnecting && _connectingFuture != null) {
      await LogHelper.writeLog(
        "Menunggu koneksi yang sedang berjalan...",
        source: _source,
        level: 3,
      );
      await _connectingFuture;
      if (_isReady) return _collection!;
    }

    // Belum ada koneksi sama sekali, mulai baru
    await connect();
    return _collection!;
  }

  Future<void> connect() async {
    // Kalau sudah connected, skip
    if (_isReady) return;

    // Kalau sedang connecting, tunggu yang sudah ada
    if (_isConnecting && _connectingFuture != null) {
      await _connectingFuture;
      return;
    }

    _isConnecting = true;
    _connectingFuture = _doConnect();
    try {
      await _connectingFuture;
    } finally {
      _isConnecting = false;
      _connectingFuture = null;
    }
  }

  Future<void> _doConnect() async {
    try {
      // Tutup koneksi lama kalau ada
      if (_db != null) {
        try {
          await _db!.close();
        } catch (_) {}
        _db = null;
        _collection = null;
      }

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
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception(
            "Koneksi Timeout (20s). Cek IP Whitelist Atlas atau sinyal HP.",
          );
        },
      );
      _collection = _db!.collection(_collectionName);

      await LogHelper.writeLog(
        "SUCCESS: Terhubung ke Atlas.",
        source: _source,
        level: 2,
      );
    } catch (e) {
      _db = null;
      _collection = null;
      await LogHelper.writeLog(
        "GAGAL koneksi ke Atlas: $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      _db = null;
      _collection = null;
      await LogHelper.writeLog(
        "Koneksi ke Atlas ditutup.",
        source: _source,
        level: 2,
      );
    }
  }

  // ─── READ (lama) ─────────────────────────────────────────
  Future<List<Logbook>> getLogs() async {
    try {
      final collection = await _getSafeCollection();
      final List<Map<String, dynamic>> data =
          await collection.find().toList();
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
      return [];
    }
  }

  // ─── READ — filter by teamId ─────────────────────────────
  Future<List<LogModel>> getLogsByTeam(String teamId) async {
    try {
      final collection = await _getSafeCollection();
      await LogHelper.writeLog(
        "INFO: Fetching data for Team: $teamId",
        source: _source,
        level: 3,
      );
      final List<Map<String, dynamic>> data =
          await collection.find(where.eq('teamId', teamId)).toList();
      return data.map((json) => LogModel.fromMap(json)).toList();
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Fetch Failed - $e",
        source: _source,
        level: 1,
      );
      return [];
    }
  }

  // ─── CREATE (Logbook) ────────────────────────────────────
  Future<void> insertLog(Logbook log) async {
    try {
      final collection = await _getSafeCollection();
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

  // ─── CREATE (LogModel) ───────────────────────────────────
  Future<void> insertLogModel(LogModel log) async {
    try {
      final collection = await _getSafeCollection();
      await collection.insertOne(log.toMap());
      await LogHelper.writeLog(
        "SUCCESS: LogModel '${log.title}' tersinkron ke Atlas.",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Gagal sinkron '${log.title}' ke Atlas: $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  // ─── UPDATE (Logbook) ────────────────────────────────────
  Future<void> updateLog(Logbook log) async {
    try {
      if (log.id == null) throw Exception("ObjectId null — tidak bisa update.");
      final collection = await _getSafeCollection();
      await collection.replaceOne(where.id(log.id!), log.toMap());
      await LogHelper.writeLog(
        "SUCCESS: Log '${log.title}' berhasil diperbarui.",
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

  // ─── UPDATE (LogModel, upsert) ───────────────────────────
  Future<void> updateLogModel(LogModel log) async {
    try {
      if (log.id == null) throw Exception("ID null — tidak bisa update.");
      final collection = await _getSafeCollection();
      await collection.replaceOne(
        where.id(ObjectId.fromHexString(log.id!)),
        log.toMap(),
        upsert: true,
      );
      await LogHelper.writeLog(
        "SUCCESS: LogModel '${log.title}' diperbarui di Atlas.",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Gagal update '${log.title}' di Atlas: $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  // ─── DELETE ──────────────────────────────────────────────
  Future<void> deleteLog(ObjectId id) async {
    try {
      final collection = await _getSafeCollection();
      await collection.remove(where.id(id));
      await LogHelper.writeLog(
        "SUCCESS: Log ID $id berhasil dihapus.",
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