import 'package:flutter/material.dart';

import 'screens/auth/auth_gate.dart';

void main() {
  runApp(const TugOfWarApp());
}

class TugOfWarApp extends StatelessWidget {
  const TugOfWarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TugOfWar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C4DFF),
        ),
      ),
      home: const AuthGate(),
    );
  }
}