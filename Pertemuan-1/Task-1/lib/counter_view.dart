

// =============================
// counter_view.dart
// =============================
// =============================
import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Multi‑Step Counter"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // ===== COUNTER CARD =====
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 40),
                child: Column(children: [
                  const Text("Total Hitungan", style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  Text('${_controller.value}', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),

            const SizedBox(height: 40),

            // ===== STEP CONTROLLER =====
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Atur Besar Step", style: Theme.of(context).textTheme.titleMedium),
            ),

            Row(children: [
              const Text("1"),
              Expanded(
                child: Slider(
                  min: 1,
                  max: 20,
                  divisions: 19,
                  value: _controller.step.toDouble(),
                  label: _controller.step.toString(),
                  onChanged: (value) {
                    setState(() {
                      _controller.setStep(value.round());
                    });
                  },
                ),
              ),
              const Text("20"),
            ]),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text("Step Aktif: ${_controller.step}", style: const TextStyle(fontWeight: FontWeight.w600)),
            ),

            const SizedBox(height: 40),

            // ===== BUTTONS =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(() => _controller.decrement()),
                  icon: const Icon(Icons.remove),
                  label: const Text("Kurang"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _controller.increment()),
                  icon: const Icon(Icons.add),
                  label: const Text("Tambah"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
