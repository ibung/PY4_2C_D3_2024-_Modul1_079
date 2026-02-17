// =============================
// main.dart
// =============================
import 'package:flutter/material.dart';
import 'counter_view.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CounterView(),
    );
  }
}