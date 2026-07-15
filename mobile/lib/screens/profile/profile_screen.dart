import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/profile_service.dart';
import '../../models/profile.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();

  late Future<Profile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileService.getProfile();
  }

  void _reload() {
    setState(() {
      _profileFuture = _profileService.getProfile();
    });
  }

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _openEditProfile(Profile profile) async {
    final updatedProfile = await Navigator.push<Profile>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          profile: profile,
        ),
      ),
    );

    if (updatedProfile != null && mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: FutureBuilder<Profile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error
                          .toString()
                          .replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final profile = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 44,
                      child: Icon(
                        Icons.person,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.username,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.email,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _openEditProfile(profile),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit profile'),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              profile.bio?.isNotEmpty == true
                                  ? profile.bio!
                                  : 'No bio added yet.',
                            ),
                            const SizedBox(height: 12),
                            Text(
                              profile.country?.isNotEmpty == true
                                  ? 'Country: ${profile.country}'
                                  : 'Country not set.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _ProfileStatRow(
                              label: 'Tug Coins',
                              value: '${profile.coinBalance}',
                            ),
                            const Divider(),
                            _ProfileStatRow(
                              label: 'Face-offs participated',
                              value: '${profile.faceOffsParticipated}',
                            ),
                            const Divider(),
                            _ProfileStatRow(
                              label: 'Comments created',
                              value: '${profile.commentsCreated}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Log out'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileStatRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStatRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}