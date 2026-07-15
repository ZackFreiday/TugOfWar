import 'package:flutter/material.dart';

import '../../core/services/profile_service.dart';
import '../../models/profile.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile profile;

  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileService _profileService = ProfileService();

  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final TextEditingController _countryController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _usernameController = TextEditingController(
      text: widget.profile.username,
    );

    _bioController = TextEditingController(
      text: widget.profile.bio ?? '',
    );

    _countryController = TextEditingController(
      text: widget.profile.country ?? '',
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      _showMessage('Username is required.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedProfile =
          await _profileService.updateProfile(
        username: username,
        bio: _bioController.text,
        country: _countryController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, updatedProfile);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _usernameController,
                  enabled: !_isSaving,
                  maxLength: 30,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bioController,
                  enabled: !_isSaving,
                  maxLength: 300,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _countryController,
                  enabled: !_isSaving,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}