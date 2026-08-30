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
          'tugofwar-result-${result.faceOffId}.png';

      await shareResultImage(
        bytes: pngBytes,
        fileName: fileName,
        title:
            '${result.title} — TugOfWar',
        text:
            '${result.title} — final result on TugOfWar',
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
      body: FutureBuilder<FaceOffResult>(
        future: _resultFuture,
        builder: (
          context,
          snapshot,
        ) {
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
                    const EdgeInsets.all(
                  24,
                ),
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
                      onPressed: _reload,
                      child: const Text(
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

          if (result.isTie) {
            outcomeText =
                'It is a tie!';

            outcomeIcon =
                Icons.balance_outlined;
          } else if (result.winningSide ==
              'A') {
            outcomeText =
                '${result.sideAName} wins!';

            outcomeIcon =
                Icons
                    .emoji_events_outlined;
          } else if (result.winningSide ==
              'B') {
            outcomeText =
                '${result.sideBName} wins!';

            outcomeIcon =
                Icons
                    .emoji_events_outlined;
          } else {
            outcomeText =
                'Final result';

            outcomeIcon =
                Icons.bar_chart_outlined;
          }

          return SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              32,
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
                      style:
                          Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .all(
                          20,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              outcomeIcon,
                              size: 44,
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              outcomeText,
                              textAlign:
                                  TextAlign
                                      .center,
                              style: Theme.of(
                                context,
                              )
                                  .textTheme
                                  .titleLarge
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
                              result.totalParticipants ==
                                      1
                                  ? 'Based on 1 participant'
                                  : 'Based on ${result.totalParticipants} participants',
                              textAlign:
                                  TextAlign
                                      .center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
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
                                !result.isTie &&
                                    result
                                            .winningSide ==
                                        'A',
                          ),
                        ),
                        const SizedBox(
                          width: 16,
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
                                !result.isTie &&
                                    result
                                            .winningSide ==
                                        'B',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    Text(
                      'Support distribution',
                      style:
                          Theme.of(context)
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
                    ClipRRect(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                      child:
                          LinearProgressIndicator(
                        value: result
                                .sideAPercentage /
                            100,
                        minHeight: 22,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        Text(
                          '${result.sideAPercentage.toStringAsFixed(1)}%',
                        ),
                        const Spacer(),
                        Text(
                          '${result.sideBPercentage.toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 28,
                    ),
                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .all(
                          20,
                        ),
                        child: Column(
                          children: [
                            _StatisticRow(
                              label:
                                  'Participants',
                              value:
                                  '${result.totalParticipants}',
                            ),
                            const Divider(),
                            _StatisticRow(
                              label:
                                  'Total votes',
                              value:
                                  '${result.sideAVotes + result.sideBVotes}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (result
                            .userSupportedSide !=
                        null) ...[
                      const SizedBox(
                        height: 20,
                      ),
                      Card(
                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .all(
                            20,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons
                                    .how_to_vote_outlined,
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Expanded(
                                child: Text(
                                  result.userSupportedSide ==
                                          'A'
                                      ? 'You supported ${result.sideAName}.'
                                      : 'You supported ${result.sideBName}.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(
                      height: 24,
                    ),
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
                                  .share_outlined,
                            ),
                      label: Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 14,
                        ),
                        child: Text(
                          _isSharing
                              ? 'Preparing...'
                              : 'Share result',
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
    final String outcome;

    if (result.isTie) {
      outcome = 'IT IS A TIE';
    } else if (result.winningSide ==
        'A') {
      outcome =
          '${result.sideAName} WINS';
    } else if (result.winningSide ==
        'B') {
      outcome =
          '${result.sideBName} WINS';
    } else {
      outcome = 'FINAL RESULT';
    }

    return Material(
      color: Colors.white,
      child: Container(
        width: 600,
        padding:
            const EdgeInsets.all(
          40,
        ),
        color: Colors.white,
        child: DefaultTextStyle(
          style:
              const TextStyle(
            color: Colors.black,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  const Icon(
                    Icons
                        .sports_score_rounded,
                    size: 30,
                    color:
                        Colors.black,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    'TugOfWar',
                    style:
                        Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color:
                                  Colors.black,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                  ),
                ],
              ),
              const SizedBox(
                height: 34,
              ),
              Text(
                result.title,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color: Colors.black,
                  fontSize: 30,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 28,
              ),
              Icon(
                result.isTie
                    ? Icons
                        .balance_outlined
                    : Icons
                        .emoji_events_outlined,
                size: 48,
                color: Colors.black,
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                outcome,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 36,
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          result.sideAName,
                          textAlign:
                              TextAlign
                                  .center,
                          style:
                              const TextStyle(
                            color:
                                Colors.black,
                            fontSize:
                                20,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          '${result.sideAPercentage.toStringAsFixed(1)}%',
                          style:
                              const TextStyle(
                            color:
                                Colors.black,
                            fontSize:
                                36,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding:
                        EdgeInsets
                            .symmetric(
                      horizontal: 20,
                    ),
                    child: Text(
                      'VS',
                      style:
                          TextStyle(
                        color:
                            Colors.black54,
                        fontSize: 18,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          result.sideBName,
                          textAlign:
                              TextAlign
                                  .center,
                          style:
                              const TextStyle(
                            color:
                                Colors.black,
                            fontSize:
                                20,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          '${result.sideBPercentage.toStringAsFixed(1)}%',
                          style:
                              const TextStyle(
                            color:
                                Colors.black,
                            fontSize:
                                36,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 34,
              ),
              Text(
                result.totalParticipants ==
                        1
                    ? '1 participant'
                    : '${result.totalParticipants} participants',
                style:
                    const TextStyle(
                  color:
                      Colors.black54,
                  fontSize: 16,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              const Text(
                'Final result',
                style: TextStyle(
                  color:
                      Colors.black54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
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

  const _ResultSideCard({
    required this.name,
    required this.percentage,
    required this.votes,
    required this.isUserSide,
    required this.isWinner,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          18,
        ),
        child: Column(
          children: [
            if (isWinner) ...[
              const Icon(
                Icons
                    .emoji_events_outlined,
              ),
              const SizedBox(
                height: 8,
              ),
            ] else if (isUserSide) ...[
              const Icon(
                Icons
                    .check_circle_outline,
              ),
              const SizedBox(
                height: 8,
              ),
            ],
            Text(
              name,
              textAlign:
                  TextAlign.center,
              style:
                  Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style:
                  Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              votes == 1
                  ? '1 vote'
                  : '$votes votes',
            ),
            if (isUserSide) ...[
              const SizedBox(
                height: 10,
              ),
              const Text(
                'Your choice',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
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