import 'package:flutter/material.dart';

import '../../core/services/admin_faceoff_service.dart';
import '../../models/faceoff.dart';
import 'admin_faceoff_form_screen.dart';
import 'admin_moderation_screen.dart';
import 'admin_users_screen.dart';

class AdminFaceOffsScreen extends StatefulWidget {
  const AdminFaceOffsScreen({
    super.key,
  });

  @override
  State<AdminFaceOffsScreen> createState() =>
      _AdminFaceOffsScreenState();
}

class _AdminFaceOffsScreenState
    extends State<AdminFaceOffsScreen> {
  final AdminFaceOffService _adminService =
      AdminFaceOffService();

  late Future<List<FaceOff>> _faceOffsFuture;

  final Set<int> _processingFaceOffIds = {};

  @override
  void initState() {
    super.initState();
    _loadFaceOffs();
  }

  void _loadFaceOffs() {
    _faceOffsFuture =
        _adminService.getFaceOffs();
  }

  Future<void> _refresh() async {
    setState(_loadFaceOffs);
    await _faceOffsFuture;
  }

  Future<void> _createFaceOff() async {
    final changed =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AdminFaceOffFormScreen(),
      ),
    );

    if (changed == true && mounted) {
      await _refresh();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Face-off created.',
      );
    }
  }

  Future<void> _editFaceOff(
    FaceOff faceOff,
  ) async {
    final changed =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AdminFaceOffFormScreen(
          faceOff: faceOff,
        ),
      ),
    );

    if (changed == true && mounted) {
      await _refresh();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Face-off updated.',
      );
    }
  }

  Future<void> _closeFaceOff(
    FaceOff faceOff,
  ) async {
    final confirmed =
        await _confirmAction(
      title:
          'Close face-off?',
      message:
          'Voting will end immediately and results will become available.',
      confirmLabel:
          'Close',
    );

    if (confirmed != true) {
      return;
    }

    await _runAction(
      faceOff.id,
      () =>
          _adminService.closeFaceOff(
        faceOff.id,
      ),
      'Face-off closed.',
    );
  }

  Future<void> _archiveFaceOff(
    FaceOff faceOff,
  ) async {
    final confirmed =
        await _confirmAction(
      title:
          'Archive face-off?',
      message:
          'The face-off will no longer be active or featured.',
      confirmLabel:
          'Archive',
    );

    if (confirmed != true) {
      return;
    }

    await _runAction(
      faceOff.id,
      () =>
          _adminService.archiveFaceOff(
        faceOff.id,
      ),
      'Face-off archived.',
    );
  }

  Future<void> _openModeration() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const AdminModerationScreen(),
      ),
    );
  }

  Future<void> _openUsers() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const AdminUsersScreen(),
      ),
    );
  }

  Future<void> _runAction(
    int faceOffId,
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() {
      _processingFaceOffIds.add(
        faceOffId,
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
          _processingFaceOffIds.remove(
            faceOffId,
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
          title:
              Text(title),
          content:
              Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text(
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
              child:
                  Text(
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
          content:
              Text(message),
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

  String _statusText(
    FaceOff faceOff,
  ) {
    final now =
        DateTime.now().toUtc();

    if (faceOff.status == 4) {
      return 'Archived';
    }

    if (now.isBefore(
      faceOff.startTime,
    )) {
      return 'Scheduled';
    }

    if (!now.isBefore(
          faceOff.endTime,
        ) ||
        faceOff.status == 3) {
      return 'Closed';
    }

    if (faceOff.status == 2) {
      return 'Live';
    }

    return 'Unavailable';
  }

  IconData _statusIcon(
    FaceOff faceOff,
  ) {
    switch (_statusText(faceOff)) {
      case 'Live':
        return Icons.circle;

      case 'Scheduled':
        return Icons
            .schedule_outlined;

      case 'Closed':
        return Icons
            .lock_clock_outlined;

      case 'Archived':
        return Icons
            .archive_outlined;

      default:
        return Icons
            .help_outline;
    }
  }

  bool _canClose(
    FaceOff faceOff,
  ) {
    return _statusText(
          faceOff,
        ) ==
        'Live';
  }

  bool _canArchive(
    FaceOff faceOff,
  ) {
    return faceOff.status != 4;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _createFaceOff,
        icon:
            const Icon(
          Icons.add,
        ),
        label:
            const Text(
          'Create',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        _openModeration,
                    icon:
                        const Icon(
                      Icons
                          .flag_outlined,
                    ),
                    label:
                        const Text(
                      'Moderation',
                    ),
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        _openUsers,
                    icon:
                        const Icon(
                      Icons
                          .people_outline,
                    ),
                    label:
                        const Text(
                      'Users',
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child:
                FutureBuilder<
                    List<FaceOff>>(
              future:
                  _faceOffsFuture,
              builder:
                  (context, snapshot) {
                if (snapshot
                        .connectionState ==
                    ConnectionState
                        .waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .all(
                        24,
                      ),
                      child: Column(
                        mainAxisSize:
                            MainAxisSize
                                .min,
                        children: [
                          const Icon(
                            Icons
                                .error_outline,
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
                                TextAlign
                                    .center,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          FilledButton(
                            onPressed:
                                () {
                              setState(
                                _loadFaceOffs,
                              );
                            },
                            child:
                                const Text(
                              'Try again',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final faceOffs =
                    snapshot.data ??
                        [];

                if (faceOffs.isEmpty) {
                  return RefreshIndicator(
                    onRefresh:
                        _refresh,
                    child: ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets
                              .all(
                        24,
                      ),
                      children:
                          const [
                        SizedBox(
                          height: 150,
                        ),
                        Icon(
                          Icons
                              .compare_arrows_outlined,
                          size: 48,
                        ),
                        SizedBox(
                          height: 12,
                        ),
                        Center(
                          child: Text(
                            'No face-offs have been created.',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh:
                      _refresh,
                  child:
                      ListView.separated(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      16,
                      16,
                      16,
                      96,
                    ),
                    itemCount:
                        faceOffs
                            .length,
                    separatorBuilder:
                        (_, _) =>
                            const SizedBox(
                      height: 12,
                    ),
                    itemBuilder:
                        (
                      context,
                      index,
                    ) {
                      final faceOff =
                          faceOffs[
                              index];

                      final isProcessing =
                          _processingFaceOffIds
                              .contains(
                        faceOff.id,
                      );

                      return Card(
                        child:
                            Padding(
                          padding:
                              const EdgeInsets
                                  .all(
                            16,
                          ),
                          child:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child:
                                        Text(
                                      faceOff
                                          .title,
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
                                  if (faceOff
                                      .isFeatured)
                                    const Icon(
                                      Icons
                                          .star_rounded,
                                    ),
                                ],
                              ),

                              const SizedBox(
                                height:
                                    8,
                              ),

                              Text(
                                faceOff
                                    .description,
                              ),

                              const SizedBox(
                                height:
                                    12,
                              ),

                              Text(
                                '${faceOff.sideAName} vs '
                                '${faceOff.sideBName}',
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),

                              const SizedBox(
                                height:
                                    12,
                              ),

                              Chip(
                                avatar:
                                    Icon(
                                  _statusIcon(
                                    faceOff,
                                  ),
                                  size:
                                      16,
                                ),
                                label:
                                    Text(
                                  _statusText(
                                    faceOff,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height:
                                    12,
                              ),

                              if (isProcessing)
                                const Center(
                                  child:
                                      Padding(
                                    padding:
                                        EdgeInsets
                                            .all(
                                      8,
                                    ),
                                    child:
                                        CircularProgressIndicator(),
                                  ),
                                )
                              else
                                Wrap(
                                  spacing:
                                      8,
                                  runSpacing:
                                      8,
                                  children: [
                                    OutlinedButton
                                        .icon(
                                      onPressed:
                                          () {
                                        _editFaceOff(
                                          faceOff,
                                        );
                                      },
                                      icon:
                                          const Icon(
                                        Icons
                                            .edit_outlined,
                                      ),
                                      label:
                                          const Text(
                                        'Edit',
                                      ),
                                    ),

                                    if (_canClose(
                                      faceOff,
                                    ))
                                      FilledButton
                                          .icon(
                                        onPressed:
                                            () {
                                          _closeFaceOff(
                                            faceOff,
                                          );
                                        },
                                        icon:
                                            const Icon(
                                          Icons
                                              .lock_clock_outlined,
                                        ),
                                        label:
                                            const Text(
                                          'Close',
                                        ),
                                      ),

                                    if (_canArchive(
                                      faceOff,
                                    ))
                                      OutlinedButton
                                          .icon(
                                        onPressed:
                                            () {
                                          _archiveFaceOff(
                                            faceOff,
                                          );
                                        },
                                        icon:
                                            const Icon(
                                          Icons
                                              .archive_outlined,
                                        ),
                                        label:
                                            const Text(
                                          'Archive',
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}