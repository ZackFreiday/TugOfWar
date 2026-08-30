import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/faceoff_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/state/app_state.dart';
import '../../models/app_notification.dart';
import '../faceoff/faceoff_details_screen.dart';
import '../faceoff/faceoff_results_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
  });

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  final NotificationService _notificationService =
      NotificationService();

  final FaceOffService _faceOffService =
      FaceOffService();

  late Future<List<AppNotification>>
      _notificationsFuture;

  bool _markingAllRead = false;
  bool _deletingAll = false;

  int? _openingNotificationId;
  int? _deletingNotificationId;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    _notificationsFuture =
        _notificationService.getNotifications();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadNotifications();
    });

    await _notificationsFuture;

    if (!mounted) {
      return;
    }

    await context
        .read<AppState>()
        .loadUnreadNotificationCount();
  }

  Future<void> _markAllAsRead() async {
    if (_markingAllRead ||
        _deletingAll) {
      return;
    }

    setState(() {
      _markingAllRead = true;
    });

    try {
      await _notificationService
          .markAllAsRead();

      if (!mounted) {
        return;
      }

      await context
          .read<AppState>()
          .loadUnreadNotificationCount();

      if (!mounted) {
        return;
      }

      setState(() {
        _loadNotifications();
      });
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
          _markingAllRead = false;
        });
      }
    }
  }

  Future<void> _deleteNotification(
    AppNotification notification,
  ) async {
    if (_deletingNotificationId != null ||
        _deletingAll) {
      return;
    }

    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete notification?',
          ),
          content: const Text(
            'This notification will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true ||
        !mounted) {
      return;
    }

    setState(() {
      _deletingNotificationId =
          notification.id;
    });

    try {
      await _notificationService
          .deleteNotification(
        notification.id,
      );

      if (!mounted) {
        return;
      }

      await context
          .read<AppState>()
          .loadUnreadNotificationCount();

      if (!mounted) {
        return;
      }

      setState(() {
        _loadNotifications();
      });
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
          _deletingNotificationId = null;
        });
      }
    }
  }

  Future<void> _deleteAllNotifications() async {
    if (_deletingAll ||
        _deletingNotificationId != null) {
      return;
    }

    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Clear all notifications?',
          ),
          content: const Text(
            'All of your notifications will be permanently deleted. '
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Clear all',
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true ||
        !mounted) {
      return;
    }

    setState(() {
      _deletingAll = true;
    });

    try {
      await _notificationService
          .deleteAllNotifications();

      if (!mounted) {
        return;
      }

      await context
          .read<AppState>()
          .loadUnreadNotificationCount();

      if (!mounted) {
        return;
      }

      setState(() {
        _loadNotifications();
      });
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
          _deletingAll = false;
        });
      }
    }
  }

  Future<void> _openNotification(
    AppNotification notification,
  ) async {
    if (_openingNotificationId != null ||
        _deletingNotificationId != null ||
        _deletingAll) {
      return;
    }

    setState(() {
      _openingNotificationId =
          notification.id;
    });

    try {
      if (!notification.isRead) {
        await _notificationService
            .markAsRead(
          notification.id,
        );

        if (!mounted) {
          return;
        }

        await context
            .read<AppState>()
            .loadUnreadNotificationCount();
      }

      if (!mounted) {
        return;
      }

      if (notification.faceOffId != null) {
        final faceOff =
            await _faceOffService
                .getFaceOffById(
          notification.faceOffId!,
        );

        if (!mounted) {
          return;
        }

        if (notification.type ==
            'FaceOffClosed') {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  FaceOffResultsScreen(
                faceOff: faceOff,
              ),
            ),
          );
        } else {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  FaceOffDetailsScreen(
                faceOff: faceOff,
              ),
            ),
          );
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _loadNotifications();
      });
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
          _openingNotificationId = null;
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

  String _cleanError(
    Object error,
  ) {
    final message = error.toString();
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('socketexception') ||
        lowerMessage.contains('clientexception') ||
        lowerMessage.contains('connection refused') ||
        lowerMessage.contains('failed host lookup') ||
        lowerMessage.contains('network is unreachable') ||
        lowerMessage.contains('connection timed out') ||
        lowerMessage.contains('connection closed')) {
      return 'Couldn\'t connect to the server. Please check your connection and try again.';
    }

    return message.replaceFirst(
      'Exception: ',
      '',
    );
  }

  String _formatDate(
    DateTime value,
  ) {
    final local =
        value.toLocal();

    final day = local.day
        .toString()
        .padLeft(2, '0');

    final month = local.month
        .toString()
        .padLeft(2, '0');

    final hour = local.hour
        .toString()
        .padLeft(2, '0');

    final minute = local.minute
        .toString()
        .padLeft(2, '0');

    return '$day.$month.${local.year} '
        '$hour:$minute';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
        ),
        actions: [
          TextButton(
            onPressed:
                _markingAllRead ||
                        _deletingAll
                    ? null
                    : _markAllAsRead,
            child: _markingAllRead
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Read all',
                  ),
          ),
          PopupMenuButton<String>(
            enabled:
                !_deletingAll &&
                _deletingNotificationId ==
                    null,
            onSelected: (value) {
              if (value ==
                  'clear_all') {
                _deleteAllNotifications();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(
                      Icons
                          .delete_sweep_outlined,
                    ),
                    SizedBox(
                      width: 12,
                    ),
                    Text(
                      'Clear all',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            width: 4,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<
            List<AppNotification>>(
          future: _notificationsFuture,
          builder: (
            context,
            snapshot,
          ) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 300,
                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.all(
                  24,
                ),
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
                      setState(() {
                        _loadNotifications();
                      });
                    },
                    child: const Text(
                      'Try again',
                    ),
                  ),
                ],
              );
            }

            final notifications =
                snapshot.data ?? [];

            if (notifications.isEmpty) {
              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                children: const [
                  SizedBox(
                    height: 80,
                  ),
                  Icon(
                    Icons.notifications_none,
                    size: 56,
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Text(
                    'No notifications yet.',
                    textAlign:
                        TextAlign.center,
                  ),
                ],
              );
            }

            return ListView.builder(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.all(
                16,
              ),
              itemCount:
                  notifications.length,
              itemBuilder: (
                context,
                index,
              ) {
                final notification =
                    notifications[index];

                return _NotificationCard(
                  notification:
                      notification,
                  formattedDate:
                      _formatDate(
                    notification.createdAt,
                  ),
                  isOpening:
                      _openingNotificationId ==
                          notification.id,
                  isDeleting:
                      _deletingNotificationId ==
                          notification.id,
                  onTap: () {
                    _openNotification(
                      notification,
                    );
                  },
                  onDelete: () {
                    _deleteNotification(
                      notification,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard
    extends StatelessWidget {
  final AppNotification notification;
  final String formattedDate;
  final bool isOpening;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.formattedDate,
    required this.isOpening,
    required this.isDeleting,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final isBusy =
        isOpening || isDeleting;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      clipBehavior:
          Clip.antiAlias,
      child: InkWell(
        onTap:
            isBusy ? null : onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(
            16,
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                child: Icon(
                  notification.type ==
                          'DailyReward'
                      ? Icons.redeem_outlined
                      : notification.type ==
                              'FaceOffClosed'
                          ? Icons
                              .emoji_events_outlined
                          : Icons
                              .notifications_outlined,
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(
                              context,
                            )
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight:
                                      notification
                                              .isRead
                                          ? FontWeight
                                              .w600
                                          : FontWeight
                                              .bold,
                                ),
                          ),
                        ),
                        if (!notification
                            .isRead)
                          const Icon(
                            Icons
                                .fiber_manual_record,
                            size: 12,
                          ),
                      ],
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      notification.message,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formattedDate,
                            style: Theme.of(
                              context,
                            )
                                .textTheme
                                .bodySmall,
                          ),
                        ),
                        if (isBusy)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        else ...[
                          IconButton(
                            onPressed:
                                onDelete,
                            tooltip:
                                'Delete notification',
                            visualDensity:
                                VisualDensity
                                    .compact,
                            icon: const Icon(
                              Icons
                                  .delete_outline,
                              size: 20,
                            ),
                          ),
                          if (notification
                                  .faceOffId !=
                              null)
                            const Icon(
                              Icons
                                  .chevron_right,
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}