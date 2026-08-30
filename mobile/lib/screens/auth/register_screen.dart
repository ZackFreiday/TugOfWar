import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';

class RegisterScreen
    extends StatefulWidget {
  const RegisterScreen({
    super.key,
  });

  @override
  State<RegisterScreen>
      createState() =>
          _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final _usernameController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  final AuthService _authService =
      AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  String _friendlyErrorMessage(
    Object? error,
  ) {
    final message =
        error?.toString() ?? '';

    final lower =
        message.toLowerCase();

    if (lower.contains(
          'socketexception',
        ) ||
        lower.contains(
          'connection refused',
        ) ||
        lower.contains(
          'clientexception',
        ) ||
        lower.contains(
          'failed host lookup',
        ) ||
        lower.contains(
          'network is unreachable',
        ) ||
        lower.contains(
          'connection timed out',
        )) {
      return 'Unable to connect to TugOfWar. '
          'Check your connection and try again.';
    }

    return message.replaceFirst(
      'Exception: ',
      '',
    );
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
        ),
      );
  }

  Future<void> _register() async {
    if (_isLoading) {
      return;
    }

    final username =
        _usernameController.text
            .trim();

    final email =
        _emailController.text
            .trim();

    final password =
        _passwordController.text;

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      _showMessage(
        'Please fill in all fields.',
      );

      return;
    }

    if (username.length < 3) {
      _showMessage(
        'Username must be at least 3 characters.',
      );

      return;
    }

    if (username.length > 30) {
      _showMessage(
        'Username cannot exceed 30 characters.',
      );

      return;
    }

    if (!email.contains('@') ||
        !email.contains('.')) {
      _showMessage(
        'Please enter a valid email address.',
      );

      return;
    }

    if (password.length < 8) {
      _showMessage(
        'Password must be at least 8 characters.',
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.register(
        username: username,
        email: email,
        password: password,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Account created successfully.',
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _friendlyErrorMessage(
          error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              24,
            ),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 420,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch,
                children: [
                  const Icon(
                    Icons
                        .person_add_alt_1_rounded,
                    size: 72,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    'Create account',
                    textAlign:
                        TextAlign.center,
                    style:
                        Theme.of(
                      context,
                    )
                            .textTheme
                            .headlineLarge
                            ?.copyWith(
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    'Join TugOfWar and choose your side.',
                    textAlign:
                        TextAlign.center,
                    style:
                        Theme.of(
                      context,
                    )
                            .textTheme
                            .bodyLarge,
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  TextField(
                    controller:
                        _usernameController,
                    enabled:
                        !_isLoading,
                    textInputAction:
                        TextInputAction
                            .next,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Username',
                      prefixIcon:
                          Icon(
                        Icons
                            .person_outline,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  TextField(
                    controller:
                        _emailController,
                    enabled:
                        !_isLoading,
                    keyboardType:
                        TextInputType
                            .emailAddress,
                    textInputAction:
                        TextInputAction
                            .next,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Email',
                      prefixIcon:
                          Icon(
                        Icons
                            .email_outlined,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  TextField(
                    controller:
                        _passwordController,
                    enabled:
                        !_isLoading,
                    obscureText:
                        _obscurePassword,
                    textInputAction:
                        TextInputAction
                            .done,
                    onSubmitted:
                        (_) {
                      _register();
                    },
                    decoration:
                        InputDecoration(
                      labelText:
                          'Password',
                      prefixIcon:
                          const Icon(
                        Icons
                            .lock_outline,
                      ),
                      border:
                          const OutlineInputBorder(),
                      suffixIcon:
                          IconButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () {
                                    setState(
                                      () {
                                        _obscurePassword =
                                            !_obscurePassword;
                                      },
                                    );
                                  },
                        icon: Icon(
                          _obscurePassword
                              ? Icons
                                  .visibility_outlined
                              : Icons
                                  .visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  FilledButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _register,
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 14,
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                  width:
                                      20,
                                  height:
                                      20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : const Text(
                                  'Create account',
                                ),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  TextButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () {
                                Navigator.pop(
                                  context,
                                );
                              },
                    child:
                        const Text(
                      'Already have an account? Log in',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}