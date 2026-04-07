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

  // ─── SAFE COLLECTION (dengan deteksi stale connection) ───
  Future<DbCollection> _getSafeCollection() async {
    // Cek apakah koneksi benar-benar hidup, bukan hanya flag isConnected
    // mongo_dart bisa stuck di state "connected" padahal sudah putus
    final bool needsReconnect = _db == null ||
        !_db!.isConnected ||
        _collection == null;

    if (needsReconnect) {
      await LogHelper.writeLog(
        "Koleksi belum siap, mencoba (re)koneksi...",
        source: _source,
        level: 3,
      );
      // Reset dulu supaya connect() tidak reuse state yang rusak
      await _forceClose();
      await connect();
    }

    return _collection!;
  }

  /// Tutup paksa tanpa throw — dipakai sebelum reconnect
  Future<void> _forceClose() async {
    try {
      if (_db != null) {
        await _db!.close();
      }
    } catch (_) {
      // Abaikan error saat force-close
    } finally {
      _db = null;
      _collection = null;
    }
  }

  // ─── CONNECT ─────────────────────────────────────────────
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
            "Koneksi Timeout (15s). Cek IP Whitelist Atlas atau sinyal HP.",
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
      // Reset state agar reconnect berikutnya berjalan bersih
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

  // ─── CLOSE ───────────────────────────────────────────────
  Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      await LogHelper.writeLog(
        "Koneksi ke Atlas ditutup.",
        source: _source,
        level: 2,
      );
    }
    _db = null;
    _collection = null;
  }

  // ─── READ (lama, tetap dipertahankan) ────────────────────
  Future<List<Logbook>> getLogs() async {
    try {
      final DbCollection collection = await _getSafeCollection();
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

  // ─── READ — filter by teamId ──────────────────────────────
  Future<List<LogModel>> getLogsByTeam(String teamId) async {
    try {
      final collection = await _getSafeCollection();

      // Jika teamId kosong, ambil semua (fallback aman)
      final SelectorBuilder selector = teamId.isEmpty
          ? where.exists('title')           // ambil semua dokumen
          : where.eq('teamId', teamId);     // filter normal

      final List<Map<String, dynamic>> data =
          await collection.find(selector).toList();

      await LogHelper.writeLog(
        "Berhasil fetch ${data.length} dokumen untuk teamId='$teamId'.",
        source: _source,
        level: 2,
      );

      return data.map((json) => LogModel.fromMap(json)).toList();
    } catch (e) {
      await LogHelper.writeLog(
        "GAGAL getLogsByTeam: $e",
        source: _source,
        level: 1,
      );
      // Coba reset koneksi untuk panggilan berikutnya
      await _forceClose();
      return [];
    }
  }

  // ─── CREATE (Logbook) ────────────────────────────────────
  Future<void> insertLog(Logbook log) async {
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
      final DbCollection collection = await _getSafeCollection();
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
      final DbCollection collection = await _getSafeCollection();
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