import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/state/app_state.dart';
import 'screens/auth/auth_gate.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) =>
          AppState()..initialize(),
      child: const TugOfWarApp(),
    ),
  );
}

class TugOfWarApp extends StatelessWidget {
  const TugOfWarApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final appState =
        context.watch<AppState>();

    return MaterialApp(
      key: ValueKey(
        '${appState.isInitializing}-'
        '${appState.isLoggedIn}',
      ),
      title: 'TugOfWar',
      debugShowCheckedModeBanner:
          false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              const Color(
            0xFF6C4DFF,
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}