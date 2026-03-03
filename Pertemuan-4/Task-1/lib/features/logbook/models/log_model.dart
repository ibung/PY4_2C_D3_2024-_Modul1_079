import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  final String? id; // optional MongoDB document id (hex string)
  final String title;
  final String description;
  final String timestamp;
  final String category;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.category = 'Pribadi',
  });

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] != null ? map['_id'].toString() : null,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: map['timestamp'] ?? map['date'] ?? '',
      category: map['category'] ?? 'Pribadi',
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'category': category,
    };
    if (id != null) map['_id'] = ObjectId.parse(id!);
    return map;
  }
}