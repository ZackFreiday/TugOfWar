import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/state/app_state.dart';
import 'screens/auth/auth_gate.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) =>
          AppState()..initialize(),
      child: const TugVoteApp(),
    ),
  );
}

class TugVoteApp extends StatelessWidget {
  const TugVoteApp({
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
      title: 'TugVote',
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