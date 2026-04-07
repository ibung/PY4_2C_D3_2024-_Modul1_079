import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart'; // ← TAMBAH INI
import 'package:logbook_app_079/services/mongo_service.dart';
import 'package:logbook_app_079/helpers/log_helper.dart';
import 'package:logbook_app_079/features/logbook/models/log_model.dart'; // ← TAMBAH INI
import 'features/onboarding/onboarding_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);
  await dotenv.load(fileName: ".env");

  await LogHelper.writeLog(
    "App dimulai. Memuat konfigurasi .env...",
    source: "main.dart",
    level: 2,
  );

  // ← TAMBAH BLOK INI (Hive init)
  await Hive.initFlutter();
  Hive.registerAdapter(LogModelAdapter());
  await Hive.openBox<LogModel>('offline_logs');

  try {
    await MongoService().connect();
  } catch (e) {
    await LogHelper.writeLog(
      "Peringatan: Koneksi awal Atlas gagal: $e",
      source: "main.dart",
      level: 1,
    );
  }

  runApp(const MyApp());
}

// MyApp tetap sama persis, tidak ada yang berubah
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