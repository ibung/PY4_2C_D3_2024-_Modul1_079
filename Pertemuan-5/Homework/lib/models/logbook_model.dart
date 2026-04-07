import 'package:mongo_dart/mongo_dart.dart';

class Logbook {
  final ObjectId? id;
  final String title;
  final String description;
  final DateTime date;
  final String? category;
  final String? authorId;
  final String? teamId;
  final bool? isPublic; // ← TASK 5: visibilitas catatan

  Logbook({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    this.category,
    this.authorId,
    this.teamId,
    this.isPublic, // ← TASK 5
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(),
      'title': title,
      'description': description,
      'timestamp': date.toIso8601String(), // unified key, same as LogModel
      if (category != null) 'category': category,
      if (authorId != null) 'authorId': authorId,
      if (teamId != null) 'teamId': teamId,
      'isPublic': isPublic ?? false,
    };
  }

  factory Logbook.fromMap(Map<String, dynamic> map) {
    ObjectId? parsedId;
    if (map['_id'] is ObjectId) {
      parsedId = map['_id'] as ObjectId;
    } else if (map['_id'] is String) {
      parsedId = ObjectId.parse(map['_id'] as String);
    }

    // Support both 'timestamp' (LogModel) and 'date' (Logbook) field names
    final rawDate = map['timestamp'] ?? map['date'];

    return Logbook(
      id: parsedId,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      date: rawDate != null
          ? DateTime.tryParse(rawDate.toString()) ?? DateTime.now()
          : DateTime.now(),
      category: map['category'] as String?,
      authorId: map['authorId'] as String?,
      teamId: map['teamId'] as String?,
      isPublic: map['isPublic'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'Logbook(id: $id, title: $title, category: $category, date: $date)';
}