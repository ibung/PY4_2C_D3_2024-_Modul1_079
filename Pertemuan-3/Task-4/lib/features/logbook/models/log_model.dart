class LogModel {
  final String title;
  final String description;
  final String timestamp;

  LogModel({
    required this.title,
    required this.description,
    required this.timestamp,
  });

  // JSON ➜ Object
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      title: map['title'],
      description: map['description'],
      timestamp: map['timestamp'],
    );
  }

  // Object ➜ JSON
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp,
    };
  }
}