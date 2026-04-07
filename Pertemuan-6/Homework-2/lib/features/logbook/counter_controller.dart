// counter_controller.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CounterController {
  int _counter = 0;
  int _step = 1;
  final List<String> _history = [];

  int get value => _counter;
  int get step => _step;
  List<String> get history => List.unmodifiable(_history);

  // ===== GREETING BERDASARKAN WAKTU =====
  String getGreeting(String username) {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour >= 0 && hour < 11) {
      greeting = "Selamat Pagi";
    } else if (hour >= 11 && hour < 15) {
      greeting = "Selamat Siang";
    } else if (hour >= 15 && hour < 18) {
      greeting = "Selamat Sore";
    } else {
      greeting = "Selamat Malam";
    }

    return "$greeting, $username 👋";
  }

  // ===== KEYS PER-USER =====
  String _keyCounter(String username) => 'counter_value_$username';
  String _keyHistory(String username) => 'counter_history_$username';

  // ===== LOAD dari SharedPreferences (PER-USER) =====
  Future<void> load(String username) async {
    final prefs = await SharedPreferences.getInstance();
    _counter = prefs.getInt(_keyCounter(username)) ?? 0;

    final saved = prefs.getStringList(_keyHistory(username)) ?? [];
    _history
      ..clear()
      ..addAll(saved);
  }

  // ===== SAVE ke SharedPreferences (PER-USER) =====
  Future<void> _save(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCounter(username), _counter);
    await prefs.setStringList(_keyHistory(username), _history);
  }

  // ===== TIMESTAMP =====
  String get _now => DateFormat('HH:mm').format(DateTime.now());

  // ===== HISTORY (Max 5) =====
  void _addHistory(String username, String action) {
    _history.insert(0, "[$_now] $username $action");
    if (_history.length > 5) _history.removeLast();
  }

  void setStep(int newStep) {
    if (newStep > 0) _step = newStep;
  }

  // ===== COUNTER LOGIC =====
  Future<void> increment(String username) async {
    _counter += _step;
    _addHistory(username, "menambah +$_step → $_counter");
    await _save(username);
  }

  Future<void> decrement(String username) async {
    _counter -= _step;
    _addHistory(username, "mengurangi -$_step → $_counter");
    await _save(username);
  }

  Future<void> reset(String username) async {
    _counter = 0;
    _addHistory(username, "mereset counter → 0");
    await _save(username);
  }
}