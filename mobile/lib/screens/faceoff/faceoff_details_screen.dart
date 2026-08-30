import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/comment_service.dart';
import '../../core/services/vote_service.dart';
import '../../core/state/app_state.dart';
import '../../models/faceoff.dart';
import '../../models/faceoff_comment.dart';
import 'faceoff_results_screen.dart';

class FaceOffDetailsScreen extends StatefulWidget {
  final FaceOff faceOff;

  const FaceOffDetailsScreen({
    super.key,
    required this.faceOff,
  });

  @override
  State<FaceOffDetailsScreen> createState() =>
      _FaceOffDetailsScreenState();
}

class _FaceOffDetailsScreenState
    extends State<FaceOffDetailsScreen> {
  final VoteService _voteService = VoteService();
  final CommentService _commentService = CommentService();

  final TextEditingController _commentController =
      TextEditingController();

  List<FaceOffComment> _comments = [];

  bool _commentsLoading = false;
  bool _commentSubmitting = false;

  String? _commentsError;

  int? _selectedSide;
  int _coinBoost = 0;

  bool _isSubmitting = false;
  bool _voteSubmitted = false;
  bool _voteLoading = true;

  bool _balanceMayHaveChanged = false;

  FaceOff get faceOff => widget.faceOff;

  String get _statusText {
    final now = DateTime.now().toUtc();

    if (faceOff.status == 4) {
      return 'Archived';
    }

    if (now.isBefore(faceOff.startTime)) {
      return 'Scheduled';
    }

    if (!now.isBefore(faceOff.endTime)) {
      return 'Closed';
    }

    return 'Live';
  }

  bool get _canViewDiscussion {
    // Archived face-offs are not available
    // to normal users.
    if (faceOff.status == 4) {
      return false;
    }

    // Closed face-offs always keep their
    // discussion open.
    if (faceOff.status == 3) {
      return true;
    }

    // While live, discussion is available
    // only after the user has voted.
    if (faceOff.status == 2) {
      return _voteSubmitted;
    }

    // Scheduled face-offs do not have
    // an open discussion.
    return false;
  }

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await _loadMyVote();

    if (!mounted) {
      return;
    }

    if (_canViewDiscussion) {
      await _loadComments();
    }
  }

  Future<void> _loadMyVote() async {
    try {
      final voteData =
          await _voteService.getMyVote(faceOff.id);

      if (!mounted) {
        return;
      }

      final hasVoted =
          voteData['hasVoted'] == true;

      setState(() {
        _voteSubmitted = hasVoted;

        if (hasVoted) {
          _selectedSide =
              voteData['chosenSide'] as int?;

          _coinBoost =
              voteData['coinBoostSupport'] as int? ??
                  0;
        }
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
          _voteLoading = false;
        });
      }
    }
  }

  Future<void> _loadComments() async {
    if (!_canViewDiscussion) {
      return;
    }

    setState(() {
      _commentsLoading = true;
      _commentsError = null;
    });

    try {
      final comments =
          await _commentService.getComments(
        faceOff.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _comments = comments;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _commentsError =
            _cleanError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _commentsLoading = false;
        });
      }
    }
  }

  Future<void> _createComment() async {
    final content =
        _commentController.text.trim();

    if (!_canViewDiscussion) {
      _showMessage(
        'You must vote before joining the discussion.',
      );

      return;
    }

    if (content.isEmpty) {
      _showMessage(
        'Write a comment first.',
      );

      return;
    }

    setState(() {
      _commentSubmitting = true;
    });

    try {
      final comment =
          await _commentService.createComment(
        faceOffId: faceOff.id,
        content: content,
      );

      if (!mounted) {
        return;
      }

      _commentController.clear();

      setState(() {
        _comments.insert(
          0,
          comment,
        );
      });

      await context
          .read<AppState>()
          .loadUnreadNotificationCount();
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
          _commentSubmitting = false;
        });
      }
    }
  }

  Future<void> _editComment(
    FaceOffComment comment,
  ) async {
    if (!_canManageComment(comment)) {
      _showMessage(
        'You cannot edit this comment.',
      );

      return;
    }

    final controller =
        TextEditingController(
      text: comment.content,
    );

    final newContent =
        await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Edit comment',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            maxLength: 500,
            decoration:
                const InputDecoration(
              hintText:
                  'Write your comment...',
              border:
                  OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                final content =
                    controller.text.trim();

                if (content.isEmpty) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  content,
                );
              },
              child:
                  const Text(
                'Save',
              ),
            ),
          ],
        );
      },
    );

    if (newContent == null ||
        newContent == comment.content) {
      return;
    }

    try {
      final updatedComment =
          await _commentService
              .updateComment(
        faceOffId: faceOff.id,
        commentId: comment.id,
        content: newContent,
      );

      if (!mounted) {
        return;
      }

      final index =
          _comments.indexWhere(
        (item) =>
            item.id == comment.id,
      );

      if (index == -1) {
        return;
      }

      setState(() {
        _comments[index] =
            updatedComment;
      });

      _showMessage(
        'Comment updated.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(error),
      );
    }
  }

  Future<void> _deleteComment(
    FaceOffComment comment,
  ) async {
    if (!_canManageComment(comment)) {
      _showMessage(
        'You cannot delete this comment.',
      );

      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete comment?',
          ),
          content: const Text(
            'This action cannot be undone.',
          ),
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
                  const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _commentService
          .deleteComment(
        faceOffId: faceOff.id,
        commentId: comment.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _comments.removeWhere(
          (item) =>
              item.id == comment.id,
        );
      });

      _showMessage(
        'Comment deleted.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(error),
      );
    }
  }

  Future<void> _toggleCommentLike(
    FaceOffComment comment,
  ) async {
    try {
      final updatedComment =
          await _commentService
              .toggleLike(
        faceOffId: faceOff.id,
        commentId: comment.id,
      );

      if (!mounted) {
        return;
      }

      final index =
          _comments.indexWhere(
        (item) =>
            item.id == comment.id,
      );

      if (index == -1) {
        return;
      }

      setState(() {
        _comments[index] =
            updatedComment;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(error),
      );
    }
  }

  Future<void> _reportComment(
    FaceOffComment comment,
  ) async {
    if (_canManageComment(comment)) {
      _showMessage(
        'You cannot report your own comment.',
      );

      return;
    }

    final reason =
        await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text(
            'Report comment',
          ),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  'Spam',
                );
              },
              child: const Text(
                'Spam',
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  'Harassment',
                );
              },
              child: const Text(
                'Harassment',
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  'Hate or abuse',
                );
              },
              child: const Text(
                'Hate or abuse',
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  'Inappropriate content',
                );
              },
              child: const Text(
                'Inappropriate content',
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  'Other',
                );
              },
              child: const Text(
                'Other',
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child: const Text(
                  'Cancel',
                ),
              ),
            ),
          ],
        );
      },
    );

    if (reason == null) {
      return;
    }

    try {
      await _commentService
          .reportComment(
        faceOffId: faceOff.id,
        commentId: comment.id,
        reason: reason,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Comment reported.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(error),
      );
    }
  }

  bool _canManageComment(
    FaceOffComment comment,
  ) {
    final appState =
        context.read<AppState>();

    if (appState.isAdmin) {
      return true;
    }

    return appState.isLoggedIn &&
        appState.username.isNotEmpty &&
        comment.username ==
            appState.username;
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

  String _formatCommentTime(
    DateTime dateTime,
  ) {
    final local =
        dateTime.toLocal();

    final day =
        local.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final month =
        local.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final hour =
        local.hour
            .toString()
            .padLeft(
              2,
              '0',
            );

    final minute =
        local.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$day.$month.${local.year} '
        '$hour:$minute';
  }

  String? _supportedSideName(
    FaceOffComment comment,
  ) {
    if (comment.chosenSide == 1) {
      return faceOff.sideAName;
    }

    if (comment.chosenSide == 2) {
      return faceOff.sideBName;
    }

    return null;
  }

  Future<void> _submitVote() async {
    if (_selectedSide == null) {
      _showMessage(
        'Choose a side first.',
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result =
          await _voteService.submitVote(
        faceOffId: faceOff.id,
        chosenSide: _selectedSide!,
        coinBoostSupport: _coinBoost,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _voteSubmitted = true;
        _balanceMayHaveChanged = true;
      });

      // Refresh the global profile so
      // the Tug Coin balance updates
      // everywhere immediately.
      await context
          .read<AppState>()
          .loadProfile();

      if (!mounted) {
        return;
      }

      // Voting may unlock an achievement,
      // so refresh the notification badge.
      await context
          .read<AppState>()
          .loadUnreadNotificationCount();

      if (!mounted) {
        return;
      }

      // The discussion becomes available
      // immediately after voting.
      await _loadComments();

      if (!mounted) {
        return;
      }

      if (result.dailyRewardEarned) {
        _showMessage(
          'Daily reward earned: '
          '+${result.dailyRewardCoins} Tug Coins! '
          'Daily progress: '
          '${result.votesToday} / '
          '${result.votesRequired}.',
        );
      } else {
        _showMessage(
          'Vote submitted. Daily progress: '
          '${result.votesToday} / '
          '${result.votesRequired}.',
        );
      }
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
          _isSubmitting = false;
        });
      }
    }
  }

  void _openResults() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FaceOffResultsScreen(
          faceOff: faceOff,
        ),
      ),
    );
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  Widget _buildDiscussion() {
    final appState =
        context.watch<AppState>();

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Discussion',
                style: Theme.of(
                  context,
                )
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),
            ),
            IconButton(
              onPressed:
                  _commentsLoading
                      ? null
                      : _loadComments,
              tooltip:
                  'Refresh comments',
              icon:
                  const Icon(
                Icons.refresh,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        TextField(
          controller:
              _commentController,
          enabled:
              !_commentSubmitting,
          minLines: 2,
          maxLines: 5,
          maxLength: 500,
          decoration:
              const InputDecoration(
            hintText:
                'Write a comment...',
            border:
                OutlineInputBorder(),
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Align(
          alignment:
              Alignment.centerRight,
          child: FilledButton.icon(
            onPressed:
                _commentSubmitting
                    ? null
                    : _createComment,
            icon: _commentSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.send_outlined,
                  ),
            label:
                const Text(
              'Post',
            ),
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        if (_commentsLoading)
          const Center(
            child: Padding(
              padding:
                  EdgeInsets.all(
                24,
              ),
              child:
                  CircularProgressIndicator(),
            ),
          )
        else if (_commentsError != null)
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                20,
              ),
              child: Column(
                children: [
                  Text(
                    _commentsError!,
                    textAlign:
                        TextAlign.center,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  OutlinedButton(
                    onPressed:
                        _loadComments,
                    child:
                        const Text(
                      'Try again',
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_comments.isEmpty)
          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(
                20,
              ),
              child: Text(
                'No comments yet. '
                'Start the discussion.',
                textAlign:
                    TextAlign.center,
              ),
            ),
          )
        else
          ..._comments.map(
            (comment) {
              final canManage =
                  appState.isAdmin ||
                      (
                        appState
                                .isLoggedIn &&
                            appState
                                .username
                                .isNotEmpty &&
                            comment
                                    .username ==
                                appState
                                    .username
                      );

              return Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
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
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const CircleAvatar(
                            child: Icon(
                              Icons
                                  .person_outline,
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
                                  comment.username,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment:
                                      WrapCrossAlignment
                                          .center,
                                  children: [
                                    if (_supportedSideName(
                                          comment,
                                        ) !=
                                        null)
                                      Container(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal:
                                              8,
                                          vertical:
                                              3,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          )
                                              .colorScheme
                                              .secondaryContainer,
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          _supportedSideName(
                                            comment,
                                          )!,
                                          style:
                                              TextStyle(
                                            fontSize:
                                                12,
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                            color: Theme.of(
                                              context,
                                            )
                                                .colorScheme
                                                .onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      _formatCommentTime(
                                        comment.createdAt,
                                      ),
                                      style: Theme.of(
                                        context,
                                      )
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          if (comment.updatedAt !=
                              null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(
                                top: 4,
                              ),
                              child: Text(
                                'Edited',
                                style: Theme.of(
                                  context,
                                )
                                    .textTheme
                                    .bodySmall,
                              ),
                            ),

                          PopupMenuButton<String>(
                            tooltip:
                                'Comment options',
                            onSelected: (value) {
                              if (value ==
                                  'edit') {
                                _editComment(
                                  comment,
                                );
                              }

                              if (value ==
                                  'delete') {
                                _deleteComment(
                                  comment,
                                );
                              }

                              if (value ==
                                  'report') {
                                _reportComment(
                                  comment,
                                );
                              }
                            },
                            itemBuilder:
                                (context) {
                              if (canManage) {
                                return const [
                                  PopupMenuItem<String>(
                                    value:
                                        'edit',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons
                                              .edit_outlined,
                                        ),
                                        SizedBox(
                                          width:
                                              12,
                                        ),
                                        Text(
                                          'Edit',
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value:
                                        'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons
                                              .delete_outline,
                                        ),
                                        SizedBox(
                                          width:
                                              12,
                                        ),
                                        Text(
                                          'Delete',
                                        ),
                                      ],
                                    ),
                                  ),
                                ];
                              }

                              return const [
                                PopupMenuItem<String>(
                                  value:
                                      'report',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons
                                            .flag_outlined,
                                      ),
                                      SizedBox(
                                        width:
                                            12,
                                      ),
                                      Text(
                                        'Report',
                                      ),
                                    ],
                                  ),
                                ),
                              ];
                            },
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      Text(
                        comment.content,
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                _toggleCommentLike(
                              comment,
                            ),
                            tooltip: comment
                                    .isLikedByCurrentUser
                                ? 'Unlike'
                                : 'Like',
                            icon: Icon(
                              comment
                                      .isLikedByCurrentUser
                                  ? Icons
                                      .favorite
                                  : Icons
                                      .favorite_border,
                            ),
                          ),
                          Text(
                            '${comment.likeCount}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDiscussionLockedCard() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          20,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline,
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Text(
                'Vote before viewing '
                'or joining the discussion.',
                style: Theme.of(
                  context,
                )
                    .textTheme
                    .bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult:
          (didPop, result) {
        if (didPop) {
          return;
        }

        Navigator.pop(
          context,
          _balanceMayHaveChanged,
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title:
              const Text(
            'Face-off',
          ),
        ),
        body: SingleChildScrollView(
          padding:
              const EdgeInsets.all(
            20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 700,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          faceOff.title,
                          style: Theme.of(
                            context,
                          )
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                        ),
                      ),
                      if (faceOff.isFeatured)
                        const Icon(
                          Icons.star_rounded,
                          size: 30,
                        ),
                    ],
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Text(
                    faceOff.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Align(
                    alignment:
                        Alignment.centerLeft,
                    child: Chip(
                      label:
                          Text(
                        _statusText,
                      ),
                      avatar: Icon(
                        faceOff.isLive
                            ? Icons.circle
                            : Icons
                                .schedule_outlined,
                        size: 16,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Expanded(
                        child:
                            _OptionalSideImage(
                          imageUrl:
                              faceOff
                                  .sideAImageUrl,
                          label:
                              faceOff
                                  .sideAName,
                          fallbackIcon:
                              Icons
                                  .chevron_left_rounded,
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Expanded(
                        child:
                            _OptionalSideImage(
                          imageUrl:
                              faceOff
                                  .sideBImageUrl,
                          label:
                              faceOff
                                  .sideBName,
                          fallbackIcon:
                              Icons
                                  .chevron_right_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  if (_voteLoading)
                    const Center(
                      child: Padding(
                        padding:
                            EdgeInsets.all(
                          24,
                        ),
                        child:
                            CircularProgressIndicator(),
                      ),
                    )
                  else if (faceOff.isLive &&
                      !_voteSubmitted) ...[
                    Row(
                      children: [
                        Expanded(
                          child:
                              _SideButton(
                            label:
                                faceOff
                                    .sideAName,
                            selected:
                                _selectedSide ==
                                    1,
                            onPressed:
                                _isSubmitting
                                    ? null
                                    : () {
                                        setState(
                                          () {
                                            _selectedSide =
                                                1;
                                          },
                                        );
                                      },
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        Expanded(
                          child:
                              _SideButton(
                            label:
                                faceOff
                                    .sideBName,
                            selected:
                                _selectedSide ==
                                    2,
                            onPressed:
                                _isSubmitting
                                    ? null
                                    : () {
                                        setState(
                                          () {
                                            _selectedSide =
                                                2;
                                          },
                                        );
                                      },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    Text(
                      'Coin boost',
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        0,
                        10,
                        25,
                        50,
                      ].map(
                        (boost) {
                          return ChoiceChip(
                            label: Text(
                              boost == 0
                                  ? 'No boost'
                                  : '+$boost support',
                            ),
                            selected:
                                _coinBoost ==
                                    boost,
                            onSelected:
                                _isSubmitting
                                    ? null
                                    : (_) {
                                        setState(
                                          () {
                                            _coinBoost =
                                                boost;
                                          },
                                        );
                                      },
                          );
                        },
                      ).toList(),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    FilledButton(
                      onPressed:
                          _isSubmitting
                              ? null
                              : _submitVote,
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 14,
                        ),
                        child:
                            _isSubmitting
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
                                    'Submit vote',
                                  ),
                      ),
                    ),
                  ] else if (faceOff.isLive &&
                      _voteSubmitted) ...[
                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          20,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons
                                      .check_circle_outline,
                                ),
                                SizedBox(
                                  width: 12,
                                ),
                                Expanded(
                                  child: Text(
                                    'Your vote has been recorded.',
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            Row(
                              children: [
                                const Icon(
                                  Icons
                                      .how_to_vote_outlined,
                                  size: 20,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Expanded(
                                  child: Text(
                                    'Your side: '
                                    '${_selectedSide == 1 ? faceOff.sideAName : faceOff.sideBName}',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 10,
                            ),

                            Row(
                              children: [
                                const Icon(
                                  Icons
                                      .monetization_on_outlined,
                                  size: 20,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Expanded(
                                  child: Text(
                                    _coinBoost >
                                            0
                                        ? 'TugCoin boost: +$_coinBoost support'
                                        : 'TugCoin boost: None',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            Text(
                              'Final results will be available when the face-off closes.',
                              style: Theme.of(
                                context,
                              )
                                  .textTheme
                                  .bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (DateTime.now()
                      .toUtc()
                      .isBefore(
                        faceOff
                            .startTime,
                      )) ...[
                    const Card(
                      child: Padding(
                        padding:
                            EdgeInsets.all(
                          20,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .schedule_outlined,
                            ),
                            SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child: Text(
                                'Voting has not started yet.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    OutlinedButton(
                      onPressed:
                          _openResults,
                      child:
                          const Padding(
                        padding:
                            EdgeInsets
                                .symmetric(
                          vertical: 14,
                        ),
                        child: Text(
                          'View results',
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 32,
                  ),
                  const Divider(),
                  const SizedBox(
                    height: 20,
                  ),

                  if (_voteLoading)
                    const SizedBox.shrink()
                  else if (_canViewDiscussion)
                    _buildDiscussion()
                  else if (faceOff.isLive)
                    _buildDiscussionLockedCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SideButton
    extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  const _SideButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final child = Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 8,
      ),
      child: Text(
        label,
        textAlign:
            TextAlign.center,
      ),
    );

    if (selected) {
      return FilledButton(
        onPressed:
            onPressed,
        child:
            child,
      );
    }

    return OutlinedButton(
      onPressed:
          onPressed,
      child:
          child,
    );
  }
}

class _OptionalSideImage
    extends StatelessWidget {
  final String? imageUrl;
  final String label;
  final IconData fallbackIcon;

  const _OptionalSideImage({
    required this.imageUrl,
    required this.label,
    required this.fallbackIcon,
  });

  bool get _hasImage =>
      imageUrl != null &&
      imageUrl!.trim().isNotEmpty;

  @override
  Widget build(
    BuildContext context,
  ) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        child: _hasImage
            ? Image.network(
                imageUrl!,
                fit:
                    BoxFit.cover,
                errorBuilder:
                    (_, _, _) {
                  return _placeholder(
                    context,
                  );
                },
              )
            : _placeholder(
                context,
              ),
      ),
    );
  }

  Widget _placeholder(
    BuildContext context,
  ) {
    return ColoredBox(
      color: Theme.of(
        context,
      )
          .colorScheme
          .surfaceContainerHighest,
      child: Padding(
        padding:
            const EdgeInsets.all(
          12,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              fallbackIcon,
              size: 52,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              label,
              textAlign:
                  TextAlign.center,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}