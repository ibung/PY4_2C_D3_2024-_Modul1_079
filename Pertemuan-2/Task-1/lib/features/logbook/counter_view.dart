import 'package:flutter/material.dart';
import 'counter_controller.dart';
import 'package:logbook_app_079/features/onboarding/onboarding_view.dart';

class CounterView extends StatefulWidget {
  final String username;
  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  void _confirmLogout() => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Konfirmasi Logout"),
          content: const Text("Yakin ingin keluar? Data akan hilang."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const OnboardingView()),
                (route) => false,
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white),
              child: const Text("Keluar"),
            ),
          ],
        ),
      );

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Konfirmasi Reset"),
        content: const Text("Yakin ingin mereset counter?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Reset")),
        ],
      ),
    );
    if (ok == true) setState(() => _controller.reset());
  }

  Widget _btn(IconData icon, Color color, VoidCallback fn) => ElevatedButton(
        onPressed: fn,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(20),
          elevation: 4,
        ),
        child: Icon(icon, size: 26),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text("Logbook: ${widget.username}"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _confirmLogout)],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(children: [

          // ===== GREETING =====
          Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.person, size: 20, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 10),
            Text("Hai, ${widget.username} 👋",
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ]),

          const SizedBox(height: 12),

          // ===== COUNTER DISPLAY =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade700]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Column(children: [
              const Text("Total Hitungan", style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text('${_controller.value}',
                  style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold)),
              Text("step: ${_controller.step}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          ),

          const SizedBox(height: 12),

          // ===== SLIDER =====
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("Step Increment", style: TextStyle(fontSize: 14)),
                Text("${_controller.step}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
              ]),
              Slider(
                min: 1, max: 20, divisions: 19,
                value: _controller.step.toDouble(),
                onChanged: (v) => setState(() => _controller.setStep(v.round())),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // ===== BUTTONS =====
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _btn(Icons.remove, const Color.fromARGB(255, 217, 83, 79), () => setState(() => _controller.decrement())),
            _btn(Icons.refresh, const Color.fromARGB(255, 240, 173, 78), _confirmReset),
            _btn(Icons.add, const Color.fromARGB(255, 92, 184, 92), () => setState(() => _controller.increment())),
          ]),

          const SizedBox(height: 16),

          // ===== HISTORY HEADER =====
          Row(children: [
            Icon(Icons.history, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text("Riwayat (5 Terakhir)",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          ]),

          const SizedBox(height: 8),

          // ===== HISTORY LIST =====
          Expanded(
            child: _controller.history.isEmpty
                ? Center(child: Text("Belum ada riwayat", style: TextStyle(color: Colors.grey.shade400)))
                : ListView.builder(
                    itemCount: _controller.history.length,
                    itemBuilder: (context, i) => Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue.shade50,
                          child: Icon(Icons.history, size: 16, color: Colors.blue.shade400),
                        ),
                        title: Text(_controller.history[i], style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}