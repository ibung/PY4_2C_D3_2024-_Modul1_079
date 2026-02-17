// =============================
// counter_controller.dart
// =============================
class CounterController {
  int _counter = 0;
  int _step = 1;

  int get value => _counter;
  int get step => _step;

  void setStep(int newStep) {
    if (newStep > 0) _step = newStep;
  }

  void increment() => _counter += _step;
  void decrement() => _counter -= _step;
  void reset() => _counter = 0;
}