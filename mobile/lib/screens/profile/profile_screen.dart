import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/faceoff_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/state/app_state.dart';
import '../../models/achievement.dart';
import '../../models/coin_transaction_history.dart';
import '../../models/comment_history.dart';
import '../../models/daily_progress.dart';
import '../../models/profile.dart';
import '../../models/vote_history.dart';
import '../auth/login_screen.dart';
import '../faceoff/faceoff_details_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool showAppBar;

  const ProfileScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final ProfileService _profileService =
      ProfileService();

  final FaceOffService _faceOffService =
      FaceOffService();

  late Future<_ProfilePageData>
      _pageFuture;

  int? _openingFaceOffId;

  @override
  void initState() {
    super.initState();

    _pageFuture = _loadPageData();
  }

  Future<_ProfilePageData>
      _loadPageData() async {
    final results = await Future.wait<dynamic>([
      context
          .read<AppState>()
          .loadProfile(),
      _profileService
          .getVoteHistory(),
      _profileService
          .getAchievements(),
      _profileService
          .getDailyProgress(),
      _profileService
          .getCoinTransactions(),
      _profileService
          .getCommentHistory(),
    ]);

    return _ProfilePageData(
      votes:
          results[1]
              as List<VoteHistory>,
      achievements:
          results[2]
              as List<Achievement>,
      dailyProgress:
          results[3]
              as DailyProgress,
      coinTransactions:
          results[4]
              as List<
                  CoinTransactionHistory>,
      comments:
          results[5]
              as List<CommentHistory>,
    );
  }

  String _friendlyErrorMessage(
    Object? error,
  ) {
    final message =
        error?.toString().toLowerCase() ??
            '';

    if (message.contains(
          'socketexception',
        ) ||
        message.contains(
          'connection refused',
        ) ||
        message.contains(
          'clientexception',
        ) ||
        message.contains(
          'failed host lookup',
        ) ||
        message.contains(
          'network is unreachable',
        ) ||
        message.contains(
          'connection timed out',
        )) {
      return 'Unable to connect to TugOfWar. '
          'Check your connection and try again.';
    }

    return 'Something went wrong while loading your profile. '
        'Please try again.';
  }

  void _retryPage() {
    setState(() {
      _pageFuture =
          _loadPageData();
    });
  }

  Future<void> _refresh() async {
    final newFuture =
        _loadPageData();

    setState(() {
      _pageFuture =
          newFuture;
    });

    try {
      await newFuture;
    } catch (_) {
      // The page-level FutureBuilder
      // displays the error state.
    }
  }

  Future<void> _logout(
    BuildContext context,
  ) async {
    await context
        .read<AppState>()
        .logout();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _openEditProfile(
    BuildContext context,
    Profile profile,
  ) async {
    final updatedProfile =
        await Navigator.push<Profile>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditProfileScreen(
          profile: profile,
        ),
      ),
    );

    if (updatedProfile == null ||
        !context.mounted) {
      return;
    }

    final newFuture =
        _loadPageData();

    setState(() {
      _pageFuture =
          newFuture;
    });

    try {
      await newFuture;
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _friendlyErrorMessage(
          error,
        ),
      );
    }
  }

  Future<void> _openCommentFaceOff(
    CommentHistory comment,
  ) async {
    if (_openingFaceOffId != null) {
      return;
    }

    setState(() {
      _openingFaceOffId =
          comment.faceOffId;
    });

    try {
      final faceOff =
          await _faceOffService
              .getFaceOffById(
        comment.faceOffId,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (_) =>
              FaceOffDetailsScreen(
            faceOff: faceOff,
          ),
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
          _openingFaceOffId =
              null;
        });
      }
    }
  }

  Future<void> _openFaceOff(
    VoteHistory vote,
  ) async {
    if (_openingFaceOffId != null) {
      return;
    }

    setState(() {
      _openingFaceOffId =
          vote.faceOffId;
    });

    try {
      final faceOff =
          await _faceOffService
              .getFaceOffById(
        vote.faceOffId,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (_) =>
              FaceOffDetailsScreen(
            faceOff: faceOff,
          ),
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
          _openingFaceOffId =
              null;
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

  String _chosenSideText(
    VoteHistory vote,
  ) {
    if (vote.chosenSide == 1) {
      return vote.sideAName;
    }

    if (vote.chosenSide == 2) {
      return vote.sideBName;
    }

    return 'Unknown';
  }

  String _statusText(
    VoteHistory vote,
  ) {
    final now =
        DateTime.now().toUtc();

    if (vote.status == 4) {
      return 'Archived';
    }

    if (now.isBefore(
      vote.startTime,
    )) {
      return 'Scheduled';
    }

    if (!now.isBefore(
          vote.endTime,
        ) ||
        vote.status == 3) {
      return 'Closed';
    }

    if (vote.status == 2) {
      return 'Live';
    }

    return 'Unavailable';
  }

  String _formatDate(
    DateTime value,
  ) {
    final local =
        value.toLocal();

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

  Widget _buildPageError(
    Object? error,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .cloud_off_outlined,
              size: 52,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              _friendlyErrorMessage(
                error,
              ),
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(
              height: 20,
            ),
            FilledButton.icon(
              onPressed:
                  _retryPage,
              icon: const Icon(
                Icons.refresh,
              ),
              label:
                  const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(
    Profile profile,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          20,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style:
                  Theme.of(
                context,
              )
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              profile.bio?.isNotEmpty ==
                      true
                  ? profile.bio!
                  : 'No bio added yet.',
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              profile.country
                          ?.isNotEmpty ==
                      true
                  ? 'Country: ${profile.country}'
                  : 'Country not set.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    Profile profile,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          20,
        ),
        child: Column(
          children: [
            _ProfileStatRow(
              label:
                  'Tug Coins',
              value:
                  '${profile.coinBalance}',
            ),
            const Divider(),
            _ProfileStatRow(
              label:
                  'Face-offs participated',
              value:
                  '${profile.faceOffsParticipated}',
            ),
            const Divider(),
            _ProfileStatRow(
              label:
                  'Comments created',
              value:
                  '${profile.commentsCreated}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinHistory(
    List<CoinTransactionHistory>
        transactions,
  ) {
    if (transactions.isEmpty) {
      return const Card(
        child: Padding(
          padding:
              EdgeInsets.all(
            20,
          ),
          child: Text(
            'No Tug Coin transactions yet.',
          ),
        ),
      );
    }

    return Column(
      children:
          transactions
              .map(
                (
                  transaction,
                ) =>
                    _CoinTransactionCard(
                  transaction:
                      transaction,
                  formattedDate:
                      _formatDate(
                    transaction
                        .createdAt,
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildAchievements(
    List<Achievement>
        achievements,
  ) {
    if (achievements.isEmpty) {
      return const Card(
        child: Padding(
          padding:
              EdgeInsets.all(
            20,
          ),
          child: Text(
            'No achievements are available yet.',
          ),
        ),
      );
    }

    final unlocked =
        achievements
            .where(
              (
                achievement,
              ) =>
                  achievement
                      .isUnlocked,
            )
            .length;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(
            bottom: 10,
          ),
          child: Text(
            '$unlocked / ${achievements.length} unlocked',
          ),
        ),
        ...achievements.map(
          (
            achievement,
          ) =>
              _AchievementCard(
            achievement:
                achievement,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentHistory(
    List<CommentHistory>
        comments,
  ) {
    if (comments.isEmpty) {
      return const Card(
        child: Padding(
          padding:
              EdgeInsets.all(
            20,
          ),
          child: Text(
            'You have not posted any comments yet.',
          ),
        ),
      );
    }

    return Column(
      children:
          comments
              .map(
                (
                  comment,
                ) =>
                    Card(
                  margin:
                      const EdgeInsets
                          .only(
                    bottom: 12,
                  ),
                  clipBehavior:
                      Clip.antiAlias,
                  child: InkWell(
                    onTap:
                        _openingFaceOffId ==
                                comment
                                    .faceOffId
                            ? null
                            : () {
                                _openCommentFaceOff(
                                  comment,
                                );
                              },
                    child: Padding(
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
                          Text(
                            comment
                                .faceOffTitle,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                          const SizedBox(
                            height:
                                10,
                          ),
                          Text(
                            comment
                                .content,
                          ),
                          const SizedBox(
                            height:
                                12,
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons
                                    .favorite_border,
                                size:
                                    18,
                              ),
                              const SizedBox(
                                width:
                                    5,
                              ),
                              Text(
                                '${comment.likeCount}',
                              ),
                              const Spacer(),
                              Text(
                                _formatDate(
                                  comment
                                      .createdAt,
                                ),
                                style:
                                    Theme.of(
                                  context,
                                )
                                        .textTheme
                                        .bodySmall,
                              ),
                              if (comment
                                      .updatedAt !=
                                  null) ...[
                                const SizedBox(
                                  width:
                                      6,
                                ),
                                Text(
                                  'Edited',
                                  style:
                                      Theme.of(
                                    context,
                                  )
                                          .textTheme
                                          .bodySmall,
                                ),
                              ],
                              const SizedBox(
                                width:
                                    8,
                              ),
                              if (_openingFaceOffId ==
                                  comment
                                      .faceOffId)
                                const SizedBox(
                                  width:
                                      18,
                                  height:
                                      18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons
                                      .chevron_right,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildVoteHistory(
    List<VoteHistory> votes,
  ) {
    if (votes.isEmpty) {
      return const Card(
        child: Padding(
          padding:
              EdgeInsets.all(
            20,
          ),
          child: Text(
            'You have not voted in any face-offs yet.',
          ),
        ),
      );
    }

    return Column(
      children:
          votes
              .map(
                (
                  vote,
                ) =>
                    _VoteHistoryCard(
                  vote: vote,
                  chosenSide:
                      _chosenSideText(
                    vote,
                  ),
                  status:
                      _statusText(
                    vote,
                  ),
                  votedAt:
                      _formatDate(
                    vote.votedAt,
                  ),
                  isOpening:
                      _openingFaceOffId ==
                          vote.faceOffId,
                  onTap: () {
                    _openFaceOff(
                      vote,
                    );
                  },
                ),
              )
              .toList(),
    );
  }

  Widget _buildProfileContent(
    Profile profile,
    _ProfilePageData data,
  ) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child:
          SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
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
                CircleAvatar(
                  radius: 44,
                  backgroundColor:
                      Theme.of(
                    context,
                  )
                          .colorScheme
                          .surfaceContainerHighest,
                  child: profile
                                  .profileImageUrl !=
                              null &&
                          profile
                              .profileImageUrl!
                              .trim()
                              .isNotEmpty
                      ? ClipOval(
                          child:
                              Image.network(
                            profile
                                .profileImageUrl!,
                            width:
                                88,
                            height:
                                88,
                            fit:
                                BoxFit.cover,
                            errorBuilder:
                                (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return const SizedBox(
                                width:
                                    88,
                                height:
                                    88,
                                child:
                                    Icon(
                                  Icons
                                      .person,
                                  size:
                                      44,
                                ),
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 44,
                        ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Text(
                  profile.username,
                  textAlign:
                      TextAlign.center,
                  style:
                      Theme.of(
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
                const SizedBox(
                  height: 6,
                ),
                Text(
                  profile.email,
                  textAlign:
                      TextAlign.center,
                ),
                const SizedBox(
                  height: 16,
                ),
                FilledButton.icon(
                  onPressed: context
                          .watch<
                              AppState>()
                          .isLoadingProfile
                      ? null
                      : () {
                          _openEditProfile(
                            context,
                            profile,
                          );
                        },
                  icon: const Icon(
                    Icons
                        .edit_outlined,
                  ),
                  label:
                      const Text(
                    'Edit profile',
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),

                _buildAboutCard(
                  profile,
                ),

                const SizedBox(
                  height: 16,
                ),

                _buildStatsCard(
                  profile,
                ),

                const SizedBox(
                  height: 24,
                ),

                _SectionTitle(
                  title:
                      'Daily reward',
                ),

                const SizedBox(
                  height: 12,
                ),

                _DailyRewardCard(
                  progress:
                      data.dailyProgress,
                ),

                const SizedBox(
                  height: 24,
                ),

                _SectionTitle(
                  title:
                      'Tug Coin history',
                ),

                const SizedBox(
                  height: 12,
                ),

                _buildCoinHistory(
                  data.coinTransactions,
                ),

                const SizedBox(
                  height: 24,
                ),

                _SectionTitle(
                  title:
                      'Achievements',
                ),

                const SizedBox(
                  height: 12,
                ),

                _buildAchievements(
                  data.achievements,
                ),

                const SizedBox(
                  height: 24,
                ),

                _SectionTitle(
                  title:
                      'Recent comments',
                ),

                const SizedBox(
                  height: 12,
                ),

                _buildCommentHistory(
                  data.comments,
                ),

                const SizedBox(
                  height: 24,
                ),

                _SectionTitle(
                  title:
                      'Recent votes',
                ),

                const SizedBox(
                  height: 12,
                ),

                _buildVoteHistory(
                  data.votes,
                ),

                const SizedBox(
                  height: 24,
                ),

                OutlinedButton.icon(
                  onPressed: () {
                    _logout(
                      context,
                    );
                  },
                  icon:
                      const Icon(
                    Icons.logout,
                  ),
                  label:
                      const Padding(
                    padding:
                        EdgeInsets
                            .symmetric(
                      vertical:
                          14,
                    ),
                    child: Text(
                      'Log out',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title:
                  const Text(
                'Profile',
              ),
            )
          : null,
      body:
          FutureBuilder<
              _ProfilePageData>(
        future:
            _pageFuture,
        builder: (
          context,
          snapshot,
        ) {
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
            return _buildPageError(
              snapshot.error,
            );
          }

          final profile =
              context
                  .watch<AppState>()
                  .profile;

          if (profile == null) {
            return _buildPageError(
              Exception(
                'Profile unavailable.',
              ),
            );
          }

          return _buildProfileContent(
            profile,
            snapshot.data!,
          );
        },
      ),
    );
  }
}

class _ProfilePageData {
  final List<VoteHistory> votes;
  final List<Achievement>
      achievements;
  final DailyProgress dailyProgress;
  final List<CoinTransactionHistory>
      coinTransactions;
  final List<CommentHistory>
      comments;

  const _ProfilePageData({
    required this.votes,
    required this.achievements,
    required this.dailyProgress,
    required this.coinTransactions,
    required this.comments,
  });
}

class _SectionTitle
    extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      title,
      style:
          Theme.of(
        context,
      )
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight:
                    FontWeight.bold,
              ),
    );
  }
}

class _DailyRewardCard
    extends StatelessWidget {
  final DailyProgress progress;

  const _DailyRewardCard({
    required this.progress,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final required =
        progress.votesRequired;

    final current =
        progress.votesToday;

    final progressValue =
        required <= 0
            ? 0.0
            : (current / required)
                .clamp(
                  0.0,
                  1.0,
                )
                .toDouble();

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          20,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    progress
                            .rewardClaimed
                        ? Icons
                            .check_circle_outline
                        : Icons
                            .local_fire_department_outlined,
                  ),
                ),
                const SizedBox(
                  width: 14,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        progress
                                .rewardClaimed
                            ? 'Reward earned today'
                            : 'Vote in $required face-offs',
                        style:
                            Theme.of(
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
                        height: 4,
                      ),
                      Text(
                        progress
                                .rewardClaimed
                            ? '+${progress.rewardCoins} Tug Coins earned'
                            : 'Complete your daily voting goal to earn +${progress.rewardCoins} Tug Coins.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 18,
            ),
            LinearProgressIndicator(
              value:
                  progressValue,
              minHeight: 10,
              borderRadius:
                  BorderRadius.circular(
                8,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Row(
              children: [
                Text(
                  progress
                          .rewardClaimed
                      ? 'Completed'
                      : 'Today',
                ),
                const Spacer(),
                Text(
                  '$current / $required votes',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinTransactionCard
    extends StatelessWidget {
  final CoinTransactionHistory
      transaction;

  final String formattedDate;

  const _CoinTransactionCard({
    required this.transaction,
    required this.formattedDate,
  });

  String get _title {
    switch (transaction.typeName) {
      case 'EarnedParticipation':
        return 'Participation reward';

      case 'EarnedDailyReward':
        return 'Daily reward';

      case 'Purchase':
        return 'Tug Coin purchase';

      case 'SpentBoost':
        return 'Vote boost';

      case 'Refund':
        return 'Refund';

      case 'AdminAdjustment':
        return 'Balance adjustment';

      default:
        return 'Tug Coin transaction';
    }
  }

  IconData get _icon {
    switch (transaction.typeName) {
      case 'EarnedParticipation':
        return Icons
            .how_to_vote_outlined;

      case 'EarnedDailyReward':
        return Icons
            .redeem_outlined;

      case 'Purchase':
        return Icons
            .shopping_cart_outlined;

      case 'SpentBoost':
        return Icons
            .bolt_outlined;

      case 'Refund':
        return Icons
            .replay_outlined;

      case 'AdminAdjustment':
        return Icons
            .admin_panel_settings_outlined;

      default:
        return Icons
            .monetization_on_outlined;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final isPositive =
        transaction.amount > 0;

    final amountText =
        transaction.amount > 0
            ? '+${transaction.amount}'
            : '${transaction.amount}';

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
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              child: Icon(
                _icon,
              ),
            ),
            const SizedBox(
              width: 14,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _title,
                          style:
                              Theme.of(
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
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        '$amountText Tug Coins',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,
                          color: isPositive
                              ? Theme.of(
                                  context,
                                )
                                  .colorScheme
                                  .primary
                              : Theme.of(
                                  context,
                                )
                                  .colorScheme
                                  .error,
                        ),
                      ),
                    ],
                  ),
                  if (transaction
                              .faceOffTitle !=
                          null &&
                      transaction
                          .faceOffTitle!
                          .isNotEmpty) ...[
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      transaction
                          .faceOffTitle!,
                    ),
                  ],
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    formattedDate,
                    style:
                        Theme.of(
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
      ),
    );
  }
}

class _AchievementCard
    extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({
    required this.achievement,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final required =
        achievement
            .requiredProgress;

    final current =
        achievement
            .currentProgress;

    final progress =
        required <= 0
            ? 0.0
            : (current / required)
                .clamp(
                  0.0,
                  1.0,
                )
                .toDouble();

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
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              child: Icon(
                achievement
                        .isUnlocked
                    ? Icons
                        .emoji_events
                    : Icons
                        .lock_outline,
              ),
            ),
            const SizedBox(
              width: 14,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement
                              .name,
                          style:
                              Theme.of(
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
                      ),
                      if (achievement
                          .isUnlocked)
                        const Icon(
                          Icons
                              .check_circle,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    achievement
                        .description,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  LinearProgressIndicator(
                    value:
                        progress,
                    minHeight: 8,
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Row(
                    children: [
                      Text(
                        achievement
                                .isUnlocked
                            ? 'Unlocked'
                            : 'Progress',
                      ),
                      const Spacer(),
                      Text(
                        '$current / $required',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoteHistoryCard
    extends StatelessWidget {
  final VoteHistory vote;
  final String chosenSide;
  final String status;
  final String votedAt;
  final bool isOpening;
  final VoidCallback onTap;

  const _VoteHistoryCard({
    required this.vote,
    required this.chosenSide,
    required this.status,
    required this.votedAt,
    required this.isOpening,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      clipBehavior:
          Clip.antiAlias,
      child: InkWell(
        onTap:
            isOpening
                ? null
                : onTap,
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
                  Expanded(
                    child: Text(
                      vote
                          .faceOffTitle,
                      style:
                          Theme.of(
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
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Chip(
                    label:
                        Text(
                      status,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                '${vote.sideAName} vs ${vote.sideBName}',
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  const Icon(
                    Icons
                        .how_to_vote_outlined,
                    size: 18,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      'You supported $chosenSide',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (vote
                      .coinBoostSupport >
                  0) ...[
                const SizedBox(
                  height: 8,
                ),
                Text(
                  'Coin boost: +${vote.coinBoostSupport} support',
                ),
              ],
              const SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Voted: $votedAt',
                      style:
                          Theme.of(
                        context,
                      )
                              .textTheme
                              .bodySmall,
                    ),
                  ),
                  if (isOpening)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2,
                      ),
                    )
                  else
                    const Icon(
                      Icons
                          .chevron_right,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStatRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStatRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Text(
          label,
        ),
        const Spacer(),
        Text(
          value,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }
}