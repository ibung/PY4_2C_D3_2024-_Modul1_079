import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_079/services/mongo_service.dart';
import 'package:logbook_app_079/helpers/log_helper.dart';
import 'features/onboarding/onboarding_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // HW 3: Inisialisasi locale Indonesia untuk intl timestamp formatting
  await initializeDateFormatting('id_ID', null);

  // Load .env terlebih dahulu sebelum semua service lain
  await dotenv.load(fileName: ".env");

  await LogHelper.writeLog(
    "App dimulai. Memuat konfigurasi .env...",
    source: "main.dart",
    level: 2,
  );

  // Task 2: Inisialisasi koneksi ke MongoDB Atlas via Singleton
  // Koneksi dilakukan di sini agar siap sebelum UI pertama dibuka
  try {
    await MongoService().connect();
  } catch (e) {
    // Koneksi gagal tidak crash app — MongoService akan retry via _getSafeCollection
    await LogHelper.writeLog(
      "Peringatan: Koneksi awal Atlas gagal: $e",
      source: "main.dart",
      level: 1,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Logbook App',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const OnboardingView(),
    );
  }
}