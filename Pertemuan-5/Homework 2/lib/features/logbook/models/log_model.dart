import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel extends HiveObject {
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

  // HiveField(7): penanda apakah data sudah terupload ke Atlas.
  // defaultValue: true supaya data lama (sebelum field ini ada)
  // tidak dianggap pending sync semua.
  @HiveField(7, defaultValue: true)
  final bool isSynced;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.category,
    required this.authorId,
    required this.teamId,
    this.isSynced = true,
  });

  Map<String, dynamic> toMap() => {
        '_id': id != null ? ObjectId.fromHexString(id!) : ObjectId(),
        'title': title,
        'description': description,
        'timestamp': timestamp,
        'category': category,
        'authorId': authorId,
        'teamId': teamId,
        // isSynced tidak perlu dikirim ke MongoDB
      };

  factory LogModel.fromMap(Map<String, dynamic> map) => LogModel(
        id: (map['_id'] as ObjectId?)?.oid ?? map['_id']?.toString(),
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        timestamp: map['timestamp'] ?? '',
        category: map['category'] ?? '',
        authorId: map['authorId'] ?? 'unknown_user',
        teamId: map['teamId'] ?? 'no_team',
        isSynced: true,
      );

  LogModel copyWith({
    String? id,
    String? title,
    String? description,
    String? timestamp,
    String? category,
    String? authorId,
    String? teamId,
    bool? isSynced,
  }) =>
      LogModel(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        timestamp: timestamp ?? this.timestamp,
        category: category ?? this.category,
        authorId: authorId ?? this.authorId,
        teamId: teamId ?? this.teamId,
        isSynced: isSynced ?? this.isSynced,
      );
}