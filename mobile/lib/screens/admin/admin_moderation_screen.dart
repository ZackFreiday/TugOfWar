import 'package:flutter/material.dart';

import '../../core/services/admin_moderation_service.dart';
import '../../core/services/admin_user_service.dart';
import '../../models/comment_report.dart';

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({
    super.key,
  });

  @override
  State<AdminModerationScreen> createState() =>
      _AdminModerationScreenState();
}

class _AdminModerationScreenState
    extends State<AdminModerationScreen> {
  final AdminModerationService _service =
      AdminModerationService();

  final AdminUserService _adminUserService =
      AdminUserService();

  late Future<List<CommentReport>> _reportsFuture;

  final Set<int> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    _reportsFuture = _service.getReports();
  }

  Future<void> _refresh() async {
    setState(_loadReports);
    await _reportsFuture;
  }

  Future<void> _dismiss(
    CommentReport report,
  ) async {
    final confirmed = await _confirmAction(
      title: 'Dismiss report?',
      message:
          'The comment will remain visible and this report will be marked as resolved.',
      confirmLabel: 'Dismiss',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _runAction(
      report.id,
      () => _service.dismissReport(
        report.id,
      ),
      'Report dismissed.',
    );
  }

  Future<void> _deleteComment(
    CommentReport report,
  ) async {
    final confirmed = await _confirmAction(
      title: 'Delete reported comment?',
      message:
          'The comment will be removed and all reports for this comment will be resolved.',
      confirmLabel: 'Delete comment',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _runAction(
      report.id,
      () => _service.deleteReportedComment(
        report.id,
      ),
      'Comment deleted.',
    );
  }

  Future<void> _suspendUser(
    CommentReport report,
  ) async {
    final confirmed = await _confirmAction(
      title: 'Suspend user?',
      message:
          '${report.commentUsername} will no longer be able to log in until an admin unsuspends the account.',
      confirmLabel: 'Suspend',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _processingIds.add(
        report.id,
      );
    });

    try {
      await _adminUserService.suspendUser(
        report.commentUserId,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        '${report.commentUsername} suspended.',
      );
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
          _processingIds.remove(
            report.id,
          );
        });
      }
    }
  }

  Future<void> _runAction(
    int reportId,
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() {
      _processingIds.add(
        reportId,
      );
    });

    try {
      await action();

      if (!mounted) {
        return;
      }

      _showMessage(
        successMessage,
      );

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
          _processingIds.remove(
            reportId,
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
          title: Text(
            title,
          ),
          content: Text(
            message,
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
          content: Text(
            message,
          ),
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

  String _formatDate(
    DateTime value,
  ) {
    final local = value.toLocal();

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
          'Moderation',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<CommentReport>>(
          future: _reportsFuture,
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
                      setState(
                        _loadReports,
                      );
                    },
                    child: const Text(
                      'Try again',
                    ),
                  ),
                ],
              );
            }

            final reports =
                snapshot.data ?? [];

            if (reports.isEmpty) {
              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                children: const [
                  SizedBox(
                    height: 120,
                  ),
                  Icon(
                    Icons.verified_user_outlined,
                    size: 56,
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Text(
                    'No unresolved reports.',
                    textAlign:
                        TextAlign.center,
                  ),
                ],
              );
            }

            return ListView.separated(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.all(
                16,
              ),
              itemCount:
                  reports.length,
              separatorBuilder: (
                context,
                index,
              ) =>
                  const SizedBox(
                height: 12,
              ),
              itemBuilder: (
                context,
                index,
              ) {
                final report =
                    reports[index];

                final isProcessing =
                    _processingIds.contains(
                  report.id,
                );

                return Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.flag_outlined,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Text(
                                report.reason,
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
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          report.commentContent,
                          style: Theme.of(
                            context,
                          )
                              .textTheme
                              .bodyLarge,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          'Comment by: '
                          '${report.commentUsername}',
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          'Reported by: '
                          '${report.reporterUsername}',
                        ),
                        if (report
                            .faceOffTitle
                            .isNotEmpty) ...[
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            'Face-off: '
                            '${report.faceOffTitle}',
                          ),
                        ],
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          'Reported: '
                          '${_formatDate(report.createdAt)}',
                          style: Theme.of(
                            context,
                          )
                              .textTheme
                              .bodySmall,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        if (isProcessing)
                          const Center(
                            child:
                                CircularProgressIndicator(),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  _dismiss(
                                    report,
                                  );
                                },
                                icon: const Icon(
                                  Icons.check_outlined,
                                ),
                                label:
                                    const Text(
                                  'Dismiss',
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: () {
                                  _deleteComment(
                                    report,
                                  );
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                ),
                                label:
                                    const Text(
                                  'Delete comment',
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  _suspendUser(
                                    report,
                                  );
                                },
                                icon: const Icon(
                                  Icons.block_outlined,
                                ),
                                label:
                                    const Text(
                                  'Suspend user',
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}