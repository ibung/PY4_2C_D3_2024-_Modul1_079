import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_079/models/logbook_model.dart';
import 'package:logbook_app_079/features/logbook/models/log_model.dart'; // ← TAMBAH
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

  Future<DbCollection> _getSafeCollection() async {
    if (_db == null || !_db!.isConnected || _collection == null) {
      await LogHelper.writeLog(
        "Koleksi belum siap, mencoba rekoneksi...",
        source: _source,
        level: 3,
      );
      await connect();
    }
    return _collection!;
  }

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
      await LogHelper.writeLog("Koneksi ke Atlas ditutup.", source: _source, level: 2);
    }
  }

  // ─── READ (lama, tetap dipertahankan) ───────────────────
  Future<List<Logbook>> getLogs() async {
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
      await LogHelper.writeLog("GAGAL fetch data: $e", source: _source, level: 1);
      return [];
    }
  }

  // ─── READ (baru) — filter by teamId ─────────────────────
  Future<List<LogModel>> getLogsByTeam(String teamId) async {
    try {
      final collection = await _getSafeCollection();
      
      // DEBUG: cek semua data dulu tanpa filter
      final allData = await collection.find().toList();
      print('=== DEBUG MONGO ===');
      print('Total semua dokumen: ${allData.length}');
      for (var doc in allData.take(3)) {
        print('teamId di DB: ${doc['teamId']}, authorId: ${doc['authorId']}');
      }
      
      // Query asli
      final List<Map<String, dynamic>> data = await collection
          .find(where.eq('teamId', teamId))
          .toList();
      print('Hasil filter teamId=$teamId: ${data.length} dokumen');
      
      return data.map((json) => LogModel.fromMap(json)).toList();
    } catch (e) {
      print('ERROR getLogsByTeam: $e');
      return [];
    }
  }

  // ─── CREATE ──────────────────────────────────────────────
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

  // ─── UPDATE ──────────────────────────────────────────────
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
        upsert: true, // insert jika belum ada, update jika sudah ada
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