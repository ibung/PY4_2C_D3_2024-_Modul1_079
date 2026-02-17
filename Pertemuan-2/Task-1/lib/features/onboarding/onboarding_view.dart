import 'package:flutter/material.dart';
import 'package:logbook_app_079/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int step = 1;

  void _nextStep() {
    setState(() => step++);
    if (step > 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
  }

  Widget _buildContent() {
    final data = [
      {
        'icon': Icons.menu_book,
        'title': 'Selamat Datang di Logbook App',
        'desc': 'Aplikasi untuk mencatat aktivitas harianmu dengan mudah.',
        'color': Colors.blue,
      },
      {
        'icon': Icons.track_changes,
        'title': 'Pantau Progress',
        'desc': 'Hitung dan monitor progres kegiatanmu setiap hari.',
        'color': Colors.green,
      },
      {
        'icon': Icons.emoji_events,
        'title': 'Capai Target',
        'desc': 'Tetapkan target dan capai pencapaian terbaikmu.',
        'color': Colors.orange,
      },
    ];

    if (step < 1 || step > 3) return const SizedBox();

    final item = data[step - 1];
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (item['color'] as Color).withOpacity(0.2),
                (item['color'] as Color).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            item['icon'] as IconData,
            size: 100,
            color: item['color'] as Color,
          ),
        ),
        const SizedBox(height: 50),
        Text(
          item['title'] as String,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            item['desc'] as String,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: step == index + 1 ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: step == index + 1
                    ? item['color'] as Color
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginView()),
                    );
                  },
                  child: const Text("Lewati"),
                ),
              ),
              Expanded(child: _buildContent()),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: step == 1
                        ? Colors.blue
                        : step == 2
                            ? Colors.green
                            : Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
            ],
          ),
        ),
      ),
    );
  }
}