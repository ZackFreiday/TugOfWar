import 'package:flutter/material.dart';

import '../../core/services/result_service.dart';
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
  final ResultService _resultService = ResultService();

  late Future<FaceOffResult> _resultFuture;

  @override
  void initState() {
    super.initState();
    _resultFuture = _resultService.getResults(widget.faceOff.id);
  }

  void _reload() {
    setState(() {
      _resultFuture =
          _resultService.getResults(widget.faceOff.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Final results'),
      ),
      body: FutureBuilder<FaceOffResult>(
        future: _resultFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error
                          .toString()
                          .replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final result = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      result.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ResultSideCard(
                            name: result.sideAName,
                            percentage:
                                result.sideAPercentage,
                            votes: result.sideAVotes,
                            support: result.sideASupport,
                            isUserSide:
                                result.userSupportedSide == 'A',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ResultSideCard(
                            name: result.sideBName,
                            percentage:
                                result.sideBPercentage,
                            votes: result.sideBVotes,
                            support: result.sideBSupport,
                            isUserSide:
                                result.userSupportedSide == 'B',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Support distribution',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value:
                            result.sideAPercentage / 100,
                        minHeight: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 28),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _StatisticRow(
                              label: 'Participants',
                              value:
                                  '${result.totalParticipants}',
                            ),
                            const Divider(),
                            _StatisticRow(
                              label: 'Total support',
                              value:
                                  '${result.sideASupport + result.sideBSupport}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (result.userSupportedSide != null) ...[
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.how_to_vote_outlined,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  result.userSupportedSide == 'A'
                                      ? 'You supported ${result.sideAName}.'
                                      : 'You supported ${result.sideBName}.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class _ResultSideCard extends StatelessWidget {
  final String name;
  final double percentage;
  final int votes;
  final int support;
  final bool isUserSide;

  const _ResultSideCard({
    required this.name,
    required this.percentage,
    required this.votes,
    required this.support,
    required this.isUserSide,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            if (isUserSide) ...[
              const Icon(Icons.check_circle_outline),
              const SizedBox(height: 8),
            ],
            Text(
              name,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text('$votes votes'),
            Text('$support support'),
          ],
        ),
      ),
    );
  }
}

class _StatisticRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatisticRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}