import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/services/result_service.dart';
import '../../core/services/result_share_service.dart';
import '../../models/faceoff.dart';
import '../../models/faceoff_result.dart';

class FaceOffResultsScreen extends StatefulWidget {
  final FaceOff faceOff;

  const FaceOffResultsScreen({
    super.key,
    required this.faceOff,
  });

  @override
  State<FaceOffResultsScreen> createState() =>
      _FaceOffResultsScreenState();
}

class _FaceOffResultsScreenState
    extends State<FaceOffResultsScreen> {
  final ResultService _resultService =
      ResultService();

  late Future<FaceOffResult>
      _resultFuture;

  bool _isSharing = false;

  static const Color _purple =
      Color(0xFF6C4DFF);

  static const Color _blue =
      Color(0xFF147BFF);

  static const Color _blueLight =
      Color(0xFFEAF3FF);

  static const Color _red =
      Color(0xFFFF3158);

  static const Color _redLight =
      Color(0xFFFFEDF1);

  static const Color _secondaryText =
      Color(0xFF686570);

  static const Color _border =
      Color(0xFFE4E1EA);

  @override
  void initState() {
    super.initState();

    _resultFuture =
        _resultService.getResults(
      widget.faceOff.id,
    );
  }

  void _reload() {
    setState(() {
      _resultFuture =
          _resultService.getResults(
        widget.faceOff.id,
      );
    });
  }

  Future<void> _shareResult(
    FaceOffResult result,
  ) async {
    if (_isSharing) {
      return;
    }

    setState(() {
      _isSharing = true;
    });

    final shareCardKey =
        GlobalKey();

    OverlayEntry? overlayEntry;

    try {
      final overlay =
          Overlay.of(context);

      overlayEntry =
          OverlayEntry(
        builder: (context) {
          return Positioned(
            left: -10000,
            top: 0,
            child: Material(
              type:
                  MaterialType.transparency,
              child: RepaintBoundary(
                key: shareCardKey,
                child: _ShareResultCard(
                  result: result,
                ),
              ),
            ),
          );
        },
      );

      overlay.insert(
        overlayEntry,
      );

      await WidgetsBinding
          .instance.endOfFrame;

      final boundary =
          shareCardKey.currentContext
              ?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception(
          'The result card could not be created.',
        );
      }

      final ui.Image image =
          await boundary.toImage(
        pixelRatio: 2.5,
      );

      final ByteData? byteData =
          await image.toByteData(
        format:
            ui.ImageByteFormat.png,
      );

      image.dispose();

      if (byteData == null) {
        throw Exception(
          'The result image could not be created.',
        );
      }

      final Uint8List pngBytes =
          byteData.buffer.asUint8List();

      final fileName =
          'tugvote-result-${result.faceOffId}.png';

      await shareResultImage(
        bytes: pngBytes,
        fileName: fileName,
        title:
            '${result.title} — TugVote',
        text:
            '${result.title} — final result on TugVote',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(error),
      );
    } finally {
      overlayEntry?.remove();

      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
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
          'Final results',
        ),
      ),
      body:
          FutureBuilder<FaceOffResult>(
        future: _resultFuture,
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot
                  .connectionState ==
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
                    const EdgeInsets.all(
                  24,
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons
                          .error_outline_rounded,
                      size: 48,
                      color: _purple,
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
                      onPressed:
                          _reload,
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

          final result =
              snapshot.data!;

          final String outcomeText;
          final IconData outcomeIcon;
          final Color outcomeColor;
          final Color outcomeBackground;

          if (result.isTie) {
            outcomeText =
                'It is a tie!';

            outcomeIcon =
                Icons.balance_rounded;

            outcomeColor =
                _purple;

            outcomeBackground =
                const Color(
              0xFFEDE9FF,
            );
          } else if (result
                  .winningSide ==
              'A') {
            outcomeText =
                '${result.sideAName} wins!';

            outcomeIcon =
                Icons
                    .emoji_events_rounded;

            outcomeColor =
                _blue;

            outcomeBackground =
                _blueLight;
          } else if (result
                  .winningSide ==
              'B') {
            outcomeText =
                '${result.sideBName} wins!';

            outcomeIcon =
                Icons
                    .emoji_events_rounded;

            outcomeColor =
                _red;

            outcomeBackground =
                _redLight;
          } else {
            outcomeText =
                'Final result';

            outcomeIcon =
                Icons
                    .bar_chart_rounded;

            outcomeColor =
                _purple;

            outcomeBackground =
                const Color(
              0xFFEDE9FF,
            );
          }

          return SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              28,
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
                    Text(
                      result.title,
                      textAlign:
                          TextAlign.center,
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

                    const SizedBox(
                      height: 20,
                    ),

                    // Winner
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 20,
                        vertical: 22,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            outcomeBackground,
                        borderRadius:
                            BorderRadius
                                .circular(
                          18,
                        ),
                        border:
                            Border.all(
                          color:
                              outcomeColor
                                  .withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white,
                              shape:
                                  BoxShape
                                      .circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      outcomeColor
                                          .withValues(
                                    alpha:
                                        0.12,
                                  ),
                                  blurRadius:
                                      14,
                                ),
                              ],
                            ),
                            child: Icon(
                              outcomeIcon,
                              color:
                                  outcomeColor,
                              size: 30,
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            outcomeText,
                            textAlign:
                                TextAlign
                                    .center,
                            style:
                                TextStyle(
                              color:
                                  outcomeColor,
                              fontSize: 21,
                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            result.totalParticipants ==
                                    1
                                ? 'Based on 1 participant'
                                : 'Based on ${result.totalParticipants} participants',
                            textAlign:
                                TextAlign
                                    .center,
                            style:
                                const TextStyle(
                              color:
                                  _secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // Side result cards
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Expanded(
                          child:
                              _ResultSideCard(
                            name:
                                result
                                    .sideAName,
                            percentage:
                                result
                                    .sideAPercentage,
                            votes:
                                result
                                    .sideAVotes,
                            isUserSide:
                                result
                                        .userSupportedSide ==
                                    'A',
                            isWinner:
                                !result
                                        .isTie &&
                                    result
                                            .winningSide ==
                                        'A',
                            accentColor:
                                _blue,
                            tintColor:
                                _blueLight,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child:
                              _ResultSideCard(
                            name:
                                result
                                    .sideBName,
                            percentage:
                                result
                                    .sideBPercentage,
                            votes:
                                result
                                    .sideBVotes,
                            isUserSide:
                                result
                                        .userSupportedSide ==
                                    'B',
                            isWinner:
                                !result
                                        .isTie &&
                                    result
                                            .winningSide ==
                                        'B',
                            accentColor:
                                _red,
                            tintColor:
                                _redLight,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    const Text(
                      'Support distribution',
                      style:
                          TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _SplitResultBar(
                      sideAPercentage:
                          result
                              .sideAPercentage,
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${result.sideAName}  ${result.sideAPercentage.toStringAsFixed(1)}%',
                            style:
                                const TextStyle(
                              color: _blue,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${result.sideBPercentage.toStringAsFixed(1)}%  ${result.sideBName}',
                            textAlign:
                                TextAlign
                                    .right,
                            style:
                                const TextStyle(
                              color: _red,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 26,
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .all(
                        18,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,
                        borderRadius:
                            BorderRadius
                                .circular(
                          16,
                        ),
                        border:
                            Border.all(
                          color: _border,
                        ),
                      ),
                      child: Column(
                        children: [
                          _StatisticRow(
                            label:
                                'Participants',
                            value:
                                '${result.totalParticipants}',
                          ),
                          const Divider(
                            height: 22,
                          ),
                          _StatisticRow(
                            label:
                                'Total votes',
                            value:
                                '${result.sideAVotes + result.sideBVotes}',
                          ),
                        ],
                      ),
                    ),

                    if (result
                            .userSupportedSide !=
                        null) ...[
                      const SizedBox(
                        height: 18,
                      ),

                      _UserChoiceCard(
                        sideName: result
                                    .userSupportedSide ==
                                'A'
                            ? result
                                .sideAName
                            : result
                                .sideBName,
                        accentColor: result
                                    .userSupportedSide ==
                                'A'
                            ? _blue
                            : _red,
                        tintColor: result
                                    .userSupportedSide ==
                                'A'
                            ? _blueLight
                            : _redLight,
                      ),
                    ],

                    const SizedBox(
                      height: 22,
                    ),

                    // Intentionally 52px,
                    // rather than the old
                    // oversized button.
                    SizedBox(
                      height: 52,
                      child:
                          FilledButton.icon(
                        onPressed:
                            _isSharing
                                ? null
                                : () =>
                                    _shareResult(
                                      result,
                                    ),
                        icon: _isSharing
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .share_outlined,
                                size: 20,
                              ),
                        label: Text(
                          _isSharing
                              ? 'Preparing...'
                              : 'Share result',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SplitResultBar
    extends StatelessWidget {
  final double sideAPercentage;

  const _SplitResultBar({
    required this.sideAPercentage,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    const blue =
        Color(0xFF147BFF);

    const red =
        Color(0xFFFF3158);

    final a =
        sideAPercentage
            .clamp(
              0.0,
              100.0,
            ) /
        100;

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(
        20,
      ),
      child: SizedBox(
        height: 16,
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            return Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(
                    color: red,
                  ),
                ),
                if (a > 0)
                  Align(
                    alignment:
                        Alignment.centerLeft,
                    child: SizedBox(
                      width: constraints
                              .maxWidth *
                          a,
                      child:
                          const ColoredBox(
                        color: blue,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ResultSideCard
    extends StatelessWidget {
  final String name;
  final double percentage;
  final int votes;
  final bool isUserSide;
  final bool isWinner;
  final Color accentColor;
  final Color tintColor;

  const _ResultSideCard({
    required this.name,
    required this.percentage,
    required this.votes,
    required this.isUserSide,
    required this.isWinner,
    required this.accentColor,
    required this.tintColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      constraints:
          const BoxConstraints(
        minHeight: 180,
      ),
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: tintColor,
        borderRadius:
            BorderRadius.circular(
          17,
        ),
        border: Border.all(
          color: accentColor
              .withValues(
            alpha:
                isWinner ? 0.7 : 0.3,
          ),
          width:
              isWinner ? 1.6 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isWinner)
            Container(
              width: 34,
              height: 34,
              decoration:
                  BoxDecoration(
                color: Colors.white
                    .withValues(
                  alpha: 0.9,
                ),
                shape:
                    BoxShape.circle,
              ),
              child: Icon(
                Icons
                    .emoji_events_rounded,
                color: accentColor,
                size: 20,
              ),
            )
          else if (isUserSide)
            Container(
              width: 34,
              height: 34,
              decoration:
                  BoxDecoration(
                color: Colors.white
                    .withValues(
                  alpha: 0.9,
                ),
                shape:
                    BoxShape.circle,
              ),
              child: Icon(
                Icons
                    .check_rounded,
                color: accentColor,
                size: 20,
              ),
            )
          else
            const SizedBox(
              height: 34,
            ),

          const SizedBox(
            height: 8,
          ),

          Text(
            name,
            textAlign:
                TextAlign.center,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              color: accentColor,
              fontSize: 15,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: accentColor,
              fontSize: 29,
              height: 1,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            votes == 1
                ? '1 vote'
                : '$votes votes',
            style:
                const TextStyle(
              color:
                  _FaceOffResultsScreenState
                      ._secondaryText,
            ),
          ),

          if (isUserSide) ...[
            const SizedBox(
              height: 8,
            ),
            Text(
              'Your choice',
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UserChoiceCard
    extends StatelessWidget {
  final String sideName;
  final Color accentColor;
  final Color tintColor;

  const _UserChoiceCard({
    required this.sideName,
    required this.accentColor,
    required this.tintColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: tintColor,
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color: accentColor
              .withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(
              color: Colors.white
                  .withValues(
                alpha: 0.9,
              ),
              shape:
                  BoxShape.circle,
            ),
            child: Icon(
              Icons
                  .how_to_vote_rounded,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Text(
              'You supported $sideName.',
              style: TextStyle(
                color: accentColor,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _StatisticRow({
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
          style:
              const TextStyle(
            color:
                _FaceOffResultsScreenState
                    ._secondaryText,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ShareResultCard
    extends StatelessWidget {
  final FaceOffResult result;

  const _ShareResultCard({
    required this.result,
  });

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

    final String outcome;
    final Color winnerColor;

    if (result.isTie) {
      outcome =
          'IT IS A TIE';

      winnerColor =
          purple;
    } else if (result
            .winningSide ==
        'A') {
      outcome =
          '${result.sideAName.toUpperCase()} WINS';

      winnerColor =
          blue;
    } else if (result
            .winningSide ==
        'B') {
      outcome =
          '${result.sideBName.toUpperCase()} WINS';

      winnerColor =
          red;
    } else {
      outcome =
          'FINAL RESULT';

      winnerColor =
          purple;
    }

    return Material(
      color: Colors.white,
      child: Container(
        width: 600,
        padding:
            const EdgeInsets.all(
          40,
        ),
        color: const Color(
          0xFFF8F7FC,
        ),
        child: DefaultTextStyle(
          style:
              const TextStyle(
            color:
                Color(
              0xFF18171D,
            ),
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFEDE9FF,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    30,
                  ),
                ),
                child:
                    const Row(
                  mainAxisSize:
                      MainAxisSize
                          .min,
                  children: [
                    Icon(
                      Icons
                          .compare_arrows_rounded,
                      color:
                          purple,
                      size: 28,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Text(
                      'TugVote',
                      style:
                          TextStyle(
                        color:
                            Color(
                          0xFF18171D,
                        ),
                        fontSize: 22,
                        fontWeight:
                            FontWeight
                                .w900,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              Text(
                result.title,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 30,
                  height: 1.2,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              Icon(
                result.isTie
                    ? Icons
                        .balance_rounded
                    : Icons
                        .emoji_events_rounded,
                size: 48,
                color:
                    winnerColor,
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                outcome,
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color:
                      winnerColor,
                  fontSize: 23,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch,
                children: [
                  Expanded(
                    child:
                        _ShareSideCard(
                      name: result
                          .sideAName,
                      percentage: result
                          .sideAPercentage,
                      accentColor:
                          blue,
                      tintColor:
                          blueLight,
                    ),
                  ),
                  const SizedBox(
                    width: 14,
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    alignment:
                        Alignment.center,
                    decoration:
                        const BoxDecoration(
                      color: purple,
                      shape:
                          BoxShape.circle,
                    ),
                    child:
                        const Text(
                      'VS',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontWeight:
                            FontWeight
                                .w900,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 14,
                  ),
                  Expanded(
                    child:
                        _ShareSideCard(
                      name: result
                          .sideBName,
                      percentage: result
                          .sideBPercentage,
                      accentColor:
                          red,
                      tintColor:
                          redLight,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 28,
              ),

              _ShareDistributionBar(
                sideAPercentage:
                    result
                        .sideAPercentage,
              ),

              const SizedBox(
                height: 20,
              ),

              Text(
                result.totalParticipants ==
                        1
                    ? 'Based on 1 participant'
                    : 'Based on ${result.totalParticipants} participants',
                style:
                    const TextStyle(
                  color:
                      Color(
                    0xFF686570,
                  ),
                  fontSize: 16,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              const Text(
                'Final result on TugVote',
                style:
                    TextStyle(
                  color:
                      Color(
                    0xFF8B8793,
                  ),
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareSideCard
    extends StatelessWidget {
  final String name;
  final double percentage;
  final Color accentColor;
  final Color tintColor;

  const _ShareSideCard({
    required this.name,
    required this.percentage,
    required this.accentColor,
    required this.tintColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 14,
        vertical: 22,
      ),
      decoration: BoxDecoration(
        color: tintColor,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: accentColor
              .withValues(
            alpha: 0.3,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Text(
            name,
            textAlign:
                TextAlign.center,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              color: accentColor,
              fontSize: 18,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: accentColor,
              fontSize: 34,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareDistributionBar
    extends StatelessWidget {
  final double sideAPercentage;

  const _ShareDistributionBar({
    required this.sideAPercentage,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    const blue =
        Color(0xFF147BFF);

    const red =
        Color(0xFFFF3158);

    final a =
        sideAPercentage
            .clamp(
              0.0,
              100.0,
            ) /
        100;

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(
        20,
      ),
      child: SizedBox(
        height: 16,
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            return Stack(
              children: [
                const Positioned.fill(
                  child:
                      ColoredBox(
                    color: red,
                  ),
                ),
                if (a > 0)
                  Align(
                    alignment:
                        Alignment.centerLeft,
                    child: SizedBox(
                      width: constraints
                              .maxWidth *
                          a,
                      child:
                          const ColoredBox(
                        color: blue,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}