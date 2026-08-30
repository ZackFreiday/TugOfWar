import 'package:flutter/material.dart';

import '../../core/services/admin_user_service.dart';
import '../../models/admin_user.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({
    super.key,
  });

  @override
  State<AdminUsersScreen> createState() =>
      _AdminUsersScreenState();
}

class _AdminUsersScreenState
    extends State<AdminUsersScreen> {
  final AdminUserService _adminUserService =
      AdminUserService();

  late Future<List<AdminUser>>
      _usersFuture;

  final Set<int> _processingUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    _usersFuture =
        _adminUserService.getUsers();
  }

  Future<void> _refresh() async {
    setState(_loadUsers);
    await _usersFuture;
  }

  Future<void> _suspendUser(
    AdminUser user,
  ) async {
    final confirmed =
        await _confirmAction(
      title: 'Suspend user?',
      message:
          '${user.username} will no longer be able to use the account until it is unsuspended.',
      confirmLabel: 'Suspend',
    );

    if (confirmed != true) {
      return;
    }

    await _runAction(
      user.id,
      () => _adminUserService
          .suspendUser(user.id),
      'User suspended.',
    );
  }

  Future<void> _unsuspendUser(
    AdminUser user,
  ) async {
    final confirmed =
        await _confirmAction(
      title: 'Unsuspend user?',
      message:
          '${user.username} will regain access to the account.',
      confirmLabel: 'Unsuspend',
    );

    if (confirmed != true) {
      return;
    }

    await _runAction(
      user.id,
      () => _adminUserService
          .unsuspendUser(user.id),
      'User unsuspended.',
    );
  }

  Future<void> _runAction(
    int userId,
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() {
      _processingUserIds.add(userId);
    });

    try {
      await action();

      if (!mounted) {
        return;
      }

      _showMessage(successMessage);

      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingUserIds.remove(
            userId,
          );
        });
      }
    }
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: Text(
                confirmLabel,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  String _cleanError(
    Object error,
  ) {
    final message =
        error.toString();

    final lowerMessage =
        message.toLowerCase();

    if (lowerMessage.contains(
          'socketexception',
        ) ||
        lowerMessage.contains(
          'clientexception',
        ) ||
        lowerMessage.contains(
          'connection refused',
        ) ||
        lowerMessage.contains(
          'failed host lookup',
        ) ||
        lowerMessage.contains(
          'network is unreachable',
        ) ||
        lowerMessage.contains(
          'connection timed out',
        ) ||
        lowerMessage.contains(
          'connection closed',
        )) {
      return 'Couldn\'t connect to the server. '
          'Please check your connection and try again.';
    }

    return message.replaceFirst(
      'Exception: ',
      '',
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Users',
        ),
      ),
      body: FutureBuilder<List<AdminUser>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      _cleanError(
                        snapshot.error!,
                      ),
                      textAlign:
                          TextAlign.center,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    FilledButton(
                      onPressed: () {
                        setState(
                          _loadUsers,
                        );
                      },
                      child: const Text(
                        'Try again',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final users =
              snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text(
                'No users found.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.all(16),
              itemCount:
                  users.length,
              separatorBuilder:
                  (_, _) =>
                      const SizedBox(
                height: 12,
              ),
              itemBuilder:
                  (context, index) {
                final user =
                    users[index];

                final isProcessing =
                    _processingUserIds
                        .contains(
                  user.id,
                );

                return Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              child: Icon(
                                Icons.person_outline,
                              ),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    user.username,
                                    style: Theme.of(
                                      context,
                                    )
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    user.email,
                                    style: Theme.of(
                                      context,
                                    )
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (user.isAdmin)
                              const Chip(
                                avatar: Icon(
                                  Icons
                                      .admin_panel_settings_outlined,
                                  size: 16,
                                ),
                                label: Text(
                                  'Admin',
                                ),
                              ),
                            Chip(
                              avatar: Icon(
                                user.isSuspended
                                    ? Icons
                                        .block_outlined
                                    : Icons
                                        .check_circle_outline,
                                size: 16,
                              ),
                              label: Text(
                                user.isSuspended
                                    ? 'Suspended'
                                    : 'Active',
                              ),
                            ),
                          ],
                        ),
                        if (!user.isAdmin) ...[
                          const SizedBox(
                            height: 12,
                          ),
                          if (isProcessing)
                            const Center(
                              child: Padding(
                                padding:
                                    EdgeInsets.all(
                                  8,
                                ),
                                child:
                                    CircularProgressIndicator(),
                              ),
                            )
                          else if (user
                              .isSuspended)
                            OutlinedButton.icon(
                              onPressed: () {
                                _unsuspendUser(
                                  user,
                                );
                              },
                              icon: const Icon(
                                Icons
                                    .check_circle_outline,
                              ),
                              label:
                                  const Text(
                                'Unsuspend',
                              ),
                            )
                          else
                            FilledButton.icon(
                              onPressed: () {
                                _suspendUser(
                                  user,
                                );
                              },
                              icon: const Icon(
                                Icons
                                    .block_outlined,
                              ),
                              label:
                                  const Text(
                                'Suspend',
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}