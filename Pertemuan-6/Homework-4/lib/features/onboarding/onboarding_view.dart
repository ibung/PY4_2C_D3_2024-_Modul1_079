import 'package:flutter/material.dart';
import 'package:logbook_app_079/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int step = 1;

  static const Color _primary = Color(0xFF1E3A5F);

  // Gradasi biru gelap → terang (sama untuk semua step)
  static const List<Color> _gradient = [
    Color(0xFF0A1A2F), // Biru sangat gelap
    Color(0xFF1E3A5F), // Biru navy (seragam login)
    Color(0xFF2980B9), // Biru terang
  ];

  void _nextStep() {
    if (step >= 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    } else {
      setState(() => step++);
    }
  }

  final List<Map<String, dynamic>> _data = [
    {
      'image': 'assets/images/onboard1.jpeg',
      'title': 'Selamat Datang di\nLogbook App',
      'desc': 'Aplikasi untuk mencatat aktivitas harianmu dengan mudah.',
      'icon': Icons.book_outlined,
    },
    {
      'image': 'assets/images/onboard2.jpg',
      'title': 'Pantau Progress',
      'desc': 'Hitung dan monitor progres kegiatanmu setiap hari.',
      'icon': Icons.bar_chart_rounded,
    },
    {
      'image': 'assets/images/onboard3.jpeg',
      'title': 'Capai Target',
      'desc': 'Tetapkan target dan capai pencapaian terbaikmu.',
      'icon': Icons.emoji_events_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final item = _data[step - 1];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradient,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── TOMBOL LEWATI ─────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8),
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginView()),
                    ),
                    child: const Text(
                      "Lewati",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // ── KONTEN TENGAH ─────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Gambar kotak rounded seperti versi awal
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            item['image'] as String,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Icon kecil dekoratif
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: Colors.white70,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Judul — gaya sama dengan "Logbook App" di login
                      Text(
                        item['title'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Deskripsi — gaya sama dengan subtitle login
                      Text(
                        item['desc'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Dot indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final bool active = step == i + 1;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active ? Colors.white : Colors.white30,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              // ── CARD BAWAH — persis seperti form card login ───
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      step == 3 ? "Mulai Sekarang" : "Lanjut",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}