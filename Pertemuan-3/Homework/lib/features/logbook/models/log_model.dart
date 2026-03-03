class LogModel {
  final String title;
  final String description;
  final String timestamp;
  final String category;

  LogModel({
    required this.title,
    required this.description,
    required this.timestamp,
    this.category = 'Pribadi',
  });

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: map['timestamp'] ?? '',
      category: map['category'] ?? 'Pribadi',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'category': category,
    };
  }
}