import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';
import '../main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final TextEditingController
      _emailController =
      TextEditingController();

  final TextEditingController
      _passwordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
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

  Future<void> _login() async {
    if (_isLoading) {
      return;
    }

    final email =
        _emailController.text.trim();

    final password =
        _passwordController.text;

    if (email.isEmpty ||
        password.isEmpty) {
      _showMessage(
        'Enter your email and password.',
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await context
          .read<AppState>()
          .login(
            email: email,
            password: password,
          );

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const MainShell(),
        ),
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

  void _openRegisterScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const RegisterScreen(),
      ),
    );
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
                        .compare_arrows_rounded,
                    size: 72,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    'TugOfWar',
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
                    'Choose your side. Pull the result.',
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
                        _emailController,
                    keyboardType:
                        TextInputType
                            .emailAddress,
                    textInputAction:
                        TextInputAction
                            .next,
                    enabled:
                        !_isLoading,
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
                    obscureText:
                        _obscurePassword,
                    enabled:
                        !_isLoading,
                    textInputAction:
                        TextInputAction
                            .done,
                    onSubmitted:
                        (_) {
                      _login();
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
                            : _login,
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
                                      22,
                                  height:
                                      22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : const Text(
                                  'Log in',
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
                            : _openRegisterScreen,
                    child:
                        const Text(
                      'Create an account',
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