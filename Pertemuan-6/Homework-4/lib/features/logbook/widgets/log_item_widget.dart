import 'package:flutter/material.dart';
import '../models/log_model.dart';

class LogItemWidget extends StatelessWidget {
  final LogModel log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LogItemWidget({
    super.key,
    required this.log,
    required this.onEdit,
    required this.onDelete,
  });

  // Warna untuk tiap kategori
  static const Map<String, Color> categoryColors = {
    'Pekerjaan': Color(0xFF3B82F6),
    'Pribadi': Color(0xFF10B981),
    'Urgent': Color(0xFFEF4444),
    'Lainnya': Color(0xFFF59E0B),
  };

  @override
  Widget build(BuildContext context) {
    final color = categoryColors[log.category] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Container(
        // Garis warna di sisi kiri berdasarkan kategori
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          title: Text(
            log.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(log.description, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
              // Badge kategori
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  log.category,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}