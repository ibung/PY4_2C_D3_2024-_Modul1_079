// =============================
// counter_view.dart
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
        child: Column(children: [

          // ===== COUNTER =====
          Card(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(children: [
                const Text("Total Hitungan"),
                Text('${_controller.value}', style: const TextStyle(fontSize: 40)),
              ]),
            ),
          ),

          const SizedBox(height: 20),

          // ===== STEP =====
          Slider(
            min: 1,
            max: 20,
            divisions: 19,
            value: _controller.step.toDouble(),
            label: _controller.step.toString(),
            onChanged: (v) => setState(() => _controller.setStep(v.round())),
          ),

          Text("Step: ${_controller.step}"),

          const SizedBox(height: 20),

          // ===== BUTTON =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _controller.decrement()),
                child: const Text("-"),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _controller.increment()),
                child: const Text("+"),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _controller.reset()),
                child: const Text("Reset"),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ===== HISTORY (MAX 5) =====
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Riwayat (5 Terakhir)"),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: _controller.history.length,
              itemBuilder: (context, i) => ListTile(
                leading: const Icon(Icons.history),
                title: Text(_controller.history[i]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}