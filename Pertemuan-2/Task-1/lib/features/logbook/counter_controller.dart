// =============================
// counter_controller.dart
// =============================
class CounterController {
  int _counter = 0;
  int _step = 1;

  // ===== HISTORY (Max 5 Data) =====
  final List<String> _history = [];

  int get value => _counter;
  int get step => _step;
  List<String> get history => List.unmodifiable(_history);

  void setStep(int newStep) {
    if (newStep > 0) _step = newStep;
  }

  // ===== PRIVATE: ADD HISTORY =====
  void _addHistory(String text) {
    _history.insert(0, text); // Tambah di atas (terbaru)

    // Batasi hanya 5 data
    if (_history.length > 5) {
      _history.removeLast();
    }
  }

  // ===== COUNTER LOGIC =====
  void increment() {
    _counter += _step;
    _addHistory("+$_step → Counter menjadi $_counter");
  }

  void decrement() {
    _counter -= _step;
    _addHistory("-$_step → Counter menjadi $_counter");
  }

  void reset() {
    _counter = 0;
    _addHistory("Reset → Counter menjadi 0");
  }
}