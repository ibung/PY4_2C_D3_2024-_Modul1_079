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

  // ===== KEYS =====
  static const _keyCounter = 'counter_value';
  static const _keyHistory = 'counter_history';

  // ===== LOAD dari SharedPreferences =====
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _counter = prefs.getInt(_keyCounter) ?? 0;

    final saved = prefs.getStringList(_keyHistory) ?? [];
    _history
      ..clear()
      ..addAll(saved);
  }

  // ===== SAVE ke SharedPreferences =====
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCounter, _counter);
    await prefs.setStringList(_keyHistory, _history);
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
    await _save();
  }

  Future<void> decrement(String username) async {
    _counter -= _step;
    _addHistory(username, "mengurangi -$_step → $_counter");
    await _save();
  }

  Future<void> reset(String username) async {
    _counter = 0;
    _addHistory(username, "mereset counter → 0");
    await _save();
  }
}