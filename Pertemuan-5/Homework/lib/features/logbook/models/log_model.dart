import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String timestamp; 

  @HiveField(4)
  final String category; 

  @HiveField(5)
  final String authorId; 

  @HiveField(6)
  final String teamId;

  @HiveField(7)
  final bool isPublic; 

  // --- TAMBAHAN UNTUK HOMEWORK: KATEGORI WARNA ---
  @HiveField(8)
  final int colorCode; 
  // -----------------------------------------------

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.category = 'Pribadi',
    required this.authorId,
    required this.teamId,
    this.isPublic = false, 
    this.colorCode = 0xFF9E9E9E, // Default warna Abu-abu (Colors.grey)
  });

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] != null ? map['_id'].toString() : null,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      // Support both 'timestamp' and legacy 'date' field names
      timestamp: map['timestamp'] ?? map['date'] ?? '',
      category: map['category'] ?? 'Pribadi',
      authorId: map['authorId'] ?? 'unknown_user',
      teamId: map['teamId'] ?? 'no_team',
      isPublic: map['isPublic'] ?? false,
      colorCode: map['colorCode'] ?? 0xFF9E9E9E,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'category': category,
      'authorId': authorId,
      'teamId': teamId,
      'isPublic': isPublic,
      'colorCode': colorCode, // Simpan color code ke database
    };

    if (id != null && id!.isNotEmpty) {
      try {
        map['_id'] = ObjectId.fromHexString(id!);
      } catch (e) {
        // Abaikan jika ID tidak valid
      }
    }
    return map;
  }
}