import 'package:mongo_dart/mongo_dart.dart';

class Logbook {
  final ObjectId? id;
  final String title;
  final String description;
  final DateTime date;
  final String? category;
  final String? authorId; 
  final String? teamId;   

  Logbook({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    this.category,
    this.authorId, 
    this.teamId,   
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(),
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      if (category != null) 'category': category,
      if (authorId != null) 'authorId': authorId, 
      if (teamId != null) 'teamId': teamId,      
    };
  }

  factory Logbook.fromMap(Map<String, dynamic> map) {
    ObjectId? parsedId;
    if (map['_id'] is ObjectId) {
      parsedId = map['_id'] as ObjectId;
    } else if (map['_id'] is String) {
      parsedId = ObjectId.parse(map['_id'] as String);
    }

    return Logbook(
      id: parsedId,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      category: map['category'] as String?,
      authorId: map['authorId'] as String?,  
      teamId: map['teamId'] as String?,      
    );
  }

  @override
  String toString() =>
      'Logbook(id: $id, title: $title, category: $category, date: $date)';
}