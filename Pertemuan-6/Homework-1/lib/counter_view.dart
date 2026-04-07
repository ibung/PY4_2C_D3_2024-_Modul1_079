import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  Future<void> _confirmReset() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Reset"),
        content: const Text("Yakin ingin mereset counter?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Reset")),
        ],
      ),
    );
    if (konfirmasi == true) setState(() => _controller.reset());
  }

  Widget _btn(IconData icon, Color color, VoidCallback onPressed) => ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(24),
        ),
        child: Icon(icon, size: 28),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Multi-Step Counter"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(children: [
              const Text("Total Hitungan", style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 10),
              Text('${_controller.value}', style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("Step Increment", style: TextStyle(fontSize: 16)),
                Text("${_controller.step}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
              ]),
              Slider(
                min: 1,
                max: 20,
                divisions: 19,
                value: _controller.step.toDouble(),
                onChanged: (v) => setState(() => _controller.setStep(v.round())),
              ),
            ]),
          ),
          const SizedBox(height: 30),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _btn(Icons.remove, const Color.fromARGB(255, 217, 83, 79), () => setState(() => _controller.decrement())),
            _btn(Icons.refresh, const Color.fromARGB(255, 240, 173, 78), _confirmReset),
            _btn(Icons.add, const Color.fromARGB(255, 92, 184, 92), () => setState(() => _controller.increment())),
          ]),
          const SizedBox(height: 30),
          const Align(alignment: Alignment.centerLeft, child: Text("Riwayat (5 Terakhir)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          const SizedBox(height: 10),
          Expanded(
            child: _controller.history.isEmpty
                ? Center(child: Text("Belum ada riwayat", style: TextStyle(color: Colors.grey.shade500)))
                : ListView.builder(
                    itemCount: _controller.history.length,
                    itemBuilder: (context, i) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.blue.shade100, child: Icon(Icons.history, color: Colors.blue.shade700)),
                        title: Text(_controller.history[i]),
                      ),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}