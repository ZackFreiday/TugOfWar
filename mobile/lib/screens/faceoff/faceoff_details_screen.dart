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

  Widget _buildCommentAvatar(
  FaceOffComment comment,
) {
  const purple =
      Color(0xFF6C4DFF);

  final profileImageUrl =
      comment.profileImageUrl?.trim();

  if (profileImageUrl == null ||
      profileImageUrl.isEmpty) {
    return const CircleAvatar(
      radius: 20,
      backgroundColor:
          Color(0xFFEDE9FF),
      child: Icon(
        Icons.person,
        size: 23,
        color: purple,
      ),
    );
  }

  return CircleAvatar(
    radius: 20,
    backgroundColor:
        const Color(0xFFEDE9FF),
    child: ClipOval(
      child: Image.network(
        profileImageUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return const SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.person,
              size: 23,
              color: purple,
            ),
          );
        },
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
                           _buildCommentAvatar(
                             comment,
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
    const purple =
        Color(0xFF6C4DFF);

    const blue =
        Color(0xFF147BFF);

    const blueLight =
        Color(0xFFEAF3FF);

    const red =
        Color(0xFFFF3158);

    const redLight =
        Color(0xFFFFEDF1);

    const secondaryText =
        Color(0xFF686570);

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
          title: const Text(
            'Face-off',
          ),
        ),
        body: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            24,
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
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
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
                                        .w800,
                              ),
                        ),
                      ),
                      if (faceOff
                          .isFeatured)
                        Container(
                          width: 36,
                          height: 36,
                          decoration:
                              const BoxDecoration(
                            color: Color(
                              0xFFEDE9FF,
                            ),
                            shape:
                                BoxShape.circle,
                          ),
                          child:
                              const Icon(
                            Icons
                                .star_rounded,
                            color: purple,
                            size: 22,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    faceOff.description,
                    style: Theme.of(
                      context,
                    )
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                          color:
                              secondaryText,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),

                  Align(
                    alignment:
                        Alignment.centerLeft,
                    child:
                        _FaceOffStatusBadge(
                      text: _statusText,
                      isLive:
                          faceOff.isLive,
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // Side A vs Side B
                  Stack(
                    alignment:
                        Alignment.center,
                    children: [
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
                              accentColor:
                                  blue,
                              tintColor:
                                  blueLight,
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
                              accentColor:
                                  red,
                              tintColor:
                                  redLight,
                            ),
                          ),
                        ],
                      ),

                      Container(
                        width: 48,
                        height: 48,
                        alignment:
                            Alignment.center,
                        decoration:
                            BoxDecoration(
                          color: purple,
                          shape:
                              BoxShape.circle,
                          border: Border.all(
                            color:
                                Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: purple
                                  .withValues(
                                alpha: 0.28,
                              ),
                              blurRadius: 18,
                              offset:
                                  const Offset(
                                0,
                                5,
                              ),
                            ),
                          ],
                        ),
                        child:
                            const Text(
                          'VS',
                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontWeight:
                                FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 22,
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

                  // LIVE + NOT VOTED
                  else if (faceOff
                          .isLive &&
                      !_voteSubmitted) ...[
                    const Text(
                      'Choose your side',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),

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
                            accentColor:
                                blue,
                            tintColor:
                                blueLight,
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
                          width: 12,
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
                            accentColor:
                                red,
                            tintColor:
                                redLight,
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
                      height: 26,
                    ),

                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration:
                              const BoxDecoration(
                            color: Color(
                              0xFFEDE9FF,
                            ),
                            shape:
                                BoxShape.circle,
                          ),
                          child:
                              const Icon(
                            Icons
                                .monetization_on_outlined,
                            color: purple,
                            size: 20,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
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
                                        .w800,
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
                        0,
                        10,
                        25,
                        50,
                      ].map(
                        (boost) {
                          final selected =
                              _coinBoost ==
                                  boost;

                          return ChoiceChip(
                            label: Text(
                              boost == 0
                                  ? 'No boost'
                                  : '+$boost support',
                            ),
                            selected:
                                selected,
                            selectedColor:
                                purple,
                            backgroundColor:
                                Colors.white,
                            checkmarkColor:
                                Colors.white,
                            side: BorderSide(
                              color: selected
                                  ? purple
                                  : const Color(
                                      0xFFE4E1EA,
                                    ),
                            ),
                            labelStyle:
                                TextStyle(
                              color: selected
                                  ? Colors
                                      .white
                                  : const Color(
                                      0xFF3C3942,
                                    ),
                              fontWeight:
                                  selected
                                      ? FontWeight
                                          .w700
                                      : FontWeight
                                          .w500,
                            ),
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
                      height: 26,
                    ),

                    SizedBox(
                      height: 54,
                      child:
                          FilledButton.icon(
                        onPressed:
                            _isSubmitting
                                ? null
                                : _submitVote,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .how_to_vote_rounded,
                              ),
                        label: Text(
                          _isSubmitting
                              ? 'Submitting...'
                              : 'Submit vote',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ),
                    ),
                  ]

                  // LIVE + ALREADY VOTED
                  else if (faceOff
                          .isLive &&
                      _voteSubmitted) ...[
                    _VoteRecordedCard(
                      selectedSide:
                          _selectedSide,
                      sideAName:
                          faceOff
                              .sideAName,
                      sideBName:
                          faceOff
                              .sideBName,
                      coinBoost:
                          _coinBoost,
                    ),
                  ]

                  // SCHEDULED
                  else if (DateTime.now()
                      .toUtc()
                      .isBefore(
                        faceOff
                            .startTime,
                      )) ...[
                    Container(
                      padding:
                          const EdgeInsets
                              .all(
                        16,
                      ),
                      decoration:
                          BoxDecoration(
                        color: purple
                            .withValues(
                          alpha: 0.07,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                        border:
                            Border.all(
                          color: purple
                              .withValues(
                            alpha: 0.18,
                          ),
                        ),
                      ),
                      child:
                          const Row(
                        children: [
                          Icon(
                            Icons
                                .schedule_outlined,
                            color: purple,
                          ),
                          SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: Text(
                              'Voting has not started yet.',
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
                    ),
                  ]

                  // CLOSED
                  else ...[
                    SizedBox(
                      height: 52,
                      child:
                          OutlinedButton
                              .icon(
                        onPressed:
                            _openResults,
                        icon: const Icon(
                          Icons
                              .bar_chart_rounded,
                        ),
                        label:
                            const Text(
                          'View results',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 28,
                  ),
                  const Divider(),
                  const SizedBox(
                    height: 18,
                  ),

                  if (_voteLoading)
                    const SizedBox
                        .shrink()
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
  final Color accentColor;
  final Color tintColor;
  final VoidCallback? onPressed;

  const _SideButton({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.tintColor,
    required this.onPressed,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              accentColor,
          backgroundColor: selected
              ? accentColor
              : tintColor,
          disabledForegroundColor:
              accentColor.withValues(
            alpha: 0.45,
          ),
          side: BorderSide(
            color: selected
                ? accentColor
                : accentColor
                    .withValues(
                    alpha: 0.55,
                  ),
            width: selected
                ? 2
                : 1.3,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            if (selected) ...[
              const Icon(
                Icons
                    .check_circle_rounded,
                color: Colors.white,
                size: 19,
              ),
              const SizedBox(
                width: 7,
              ),
            ],
            Flexible(
              child: Text(
                label,
                textAlign:
                    TextAlign.center,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : accentColor,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionalSideImage
    extends StatelessWidget {
  final String? imageUrl;
  final String label;
  final IconData fallbackIcon;
  final Color accentColor;
  final Color tintColor;

  const _OptionalSideImage({
    required this.imageUrl,
    required this.label,
    required this.fallbackIcon,
    required this.accentColor,
    required this.tintColor,
  });

  bool get _hasImage =>
      imageUrl != null &&
      imageUrl!.trim().isNotEmpty;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration:
                BoxDecoration(
              color: tintColor,
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
              border: Border.all(
                color: accentColor
                    .withValues(
                  alpha: 0.55,
                ),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor
                      .withValues(
                    alpha: 0.09,
                  ),
                  blurRadius: 14,
                  offset:
                      const Offset(
                    0,
                    5,
                  ),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                16.5,
              ),
              child: _hasImage
                  ? Image.network(
                      imageUrl!,
                      fit:
                          BoxFit.cover,
                      errorBuilder:
                          (_, _, _) {
                        return _placeholder();
                      },
                    )
                  : _placeholder(),
            ),
          ),
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
          style: TextStyle(
            color: accentColor,
            fontSize: 14,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: tintColor,
      child: Center(
        child: Container(
          width: 68,
          height: 68,
          decoration:
              BoxDecoration(
            color: Colors.white
                .withValues(
              alpha: 0.92,
            ),
            shape:
                BoxShape.circle,
            border: Border.all(
              color: accentColor
                  .withValues(
                alpha: 0.13,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor
                    .withValues(
                  alpha: 0.09,
                ),
                blurRadius: 12,
              ),
            ],
          ),
          child: Icon(
            fallbackIcon,
            color: accentColor,
            size: 46,
          ),
        ),
      ),
    );
  }
}

class _FaceOffStatusBadge
    extends StatelessWidget {
  final String text;
  final bool isLive;

  const _FaceOffStatusBadge({
    required this.text,
    required this.isLive,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    const purple =
        Color(0xFF6C4DFF);

    const green =
        Color(0xFF13A864);

    const gray =
        Color(0xFF5E5B66);

    final Color color;

    if (isLive) {
      color = green;
    } else if (text ==
        'Scheduled') {
      color = purple;
    } else {
      color = gray;
    }

    final IconData icon;

    if (isLive) {
      icon = Icons.circle;
    } else if (text ==
        'Scheduled') {
      icon =
          Icons.schedule_outlined;
    } else {
      icon =
          Icons.lock_outline_rounded;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: isLive ? 9 : 15,
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteRecordedCard
    extends StatelessWidget {
  final int? selectedSide;
  final String sideAName;
  final String sideBName;
  final int coinBoost;

  const _VoteRecordedCard({
    required this.selectedSide,
    required this.sideAName,
    required this.sideBName,
    required this.coinBoost,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    const blue =
        Color(0xFF147BFF);

    const red =
        Color(0xFFFF3158);

    final sideColor =
        selectedSide == 1
            ? blue
            : red;

    final sideName =
        selectedSide == 1
            ? sideAName
            : sideBName;

    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: sideColor
            .withValues(
          alpha: 0.06,
        ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: sideColor
              .withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration:
                    BoxDecoration(
                  color: sideColor
                      .withValues(
                    alpha: 0.13,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child: Icon(
                  Icons
                      .check_rounded,
                  color: sideColor,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              const Expanded(
                child: Text(
                  'Your vote has been recorded.',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 14,
          ),
          Row(
            children: [
              Icon(
                Icons
                    .how_to_vote_outlined,
                color: sideColor,
                size: 20,
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Text(
                  'Your side: $sideName',
                  style:
                      TextStyle(
                    color: sideColor,
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 9,
          ),
          Row(
            children: [
              const Icon(
                Icons
                    .monetization_on_outlined,
                size: 20,
                color:
                    Color(
                  0xFF6C4DFF,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Text(
                  coinBoost > 0
                      ? 'TugCoin boost: +$coinBoost support'
                      : 'TugCoin boost: None',
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 14,
          ),
          const Text(
            'Final results will be available when the face-off closes.',
            style: TextStyle(
              color:
                  Color(
                0xFF686570,
              ),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}