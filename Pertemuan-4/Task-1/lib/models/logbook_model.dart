import 'package:mongo_dart/mongo_dart.dart';

class Logbook {
  final ObjectId? id; // ID unik dari MongoDB
  final String title;
  final String description;
  final DateTime date;

  Logbook({
    this.id,
    required this.title,
    required this.description,
    required this.date,
  });

  // Mengubah objek ke Map (untuk dikirim ke Cloud)
  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(),
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  // Mengubah Map dari Cloud kembali ke objek Flutter
  factory Logbook.fromMap(Map<String, dynamic> map) {
    return Logbook(
      id: map['_id'] as ObjectId?,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
    );
  }
}