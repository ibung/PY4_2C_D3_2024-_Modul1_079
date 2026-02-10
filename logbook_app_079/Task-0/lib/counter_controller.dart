class CounterController {
  int _counter = 0; // Variabel private (Enkapsulasi)

  int get value => _counter; // Getter untuk akses data

  void increment() => _counter++;
  void decrement() { if (_counter > 0) _counter--; }
  void reset() => _counter = 0;
}
