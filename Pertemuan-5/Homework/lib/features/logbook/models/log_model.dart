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
  final String timestamp; // tetap pakai timestamp, bukan date

  @HiveField(4)
  final String category; // tetap pakai category milikmu

  @HiveField(5)
  final String authorId; // tambahan dari modul (collaborative)

  @HiveField(6)
  final String teamId;

  @HiveField(7)
  final bool isPublic; // ← TASK 5: visibilitas catatan

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.category = 'Pribadi',
    required this.authorId,
    required this.teamId,
    this.isPublic = false, // ← default: Private
  });

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] != null ? map['_id'].toString() : null,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: map['timestamp'] ?? map['date'] ?? '',
      category: map['category'] ?? 'Pribadi',
      authorId: map['authorId'] ?? 'unknown_user',
      teamId: map['teamId'] ?? 'no_team',
      isPublic: map['isPublic'] ?? false, // ← TASK 5
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'category': category,
      'authorId': authorId,
      'teamId': teamId,
      'isPublic': isPublic, // ← TASK 5
    };
    if (id != null) map['_id'] = ObjectId.parse(id!);
    return map;
  }
}