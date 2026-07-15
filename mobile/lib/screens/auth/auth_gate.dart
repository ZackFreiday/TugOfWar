import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/profile_service.dart';
import '../../models/profile.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  late Future<Profile?> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _checkExistingSession();
  }

  Future<Profile?> _checkExistingSession() async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      return await _profileService.getProfile();
    } catch (_) {
      await _authService.logout();
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile?>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final profile = snapshot.data;

        if (profile == null) {
          return const LoginScreen();
        }

        return HomeScreen(
          username: profile.username,
          coinBalance: profile.coinBalance,
        );
      },
    );
  }
}