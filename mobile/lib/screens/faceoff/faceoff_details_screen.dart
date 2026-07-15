import 'package:flutter/material.dart';

import '../../core/services/vote_service.dart';
import '../../models/faceoff.dart';
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

  int? _selectedSide;
  int _coinBoost = 0;
  bool _isSubmitting = false;
  bool _voteSubmitted = false;

  FaceOff get faceOff => widget.faceOff;

  String get _statusText {
    switch (faceOff.status) {
      case 1:
        return 'Scheduled';
      case 2:
        return 'Live';
      case 3:
        return 'Closed';
      case 4:
        return 'Archived';
      default:
        return 'Unknown';
    }
  }

  Future<void> _submitVote() async {
    if (_selectedSide == null) {
      _showMessage('Choose a side first.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
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
      });

      _showMessage('Your vote was submitted.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face-off'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        faceOff.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
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
                const SizedBox(height: 12),
                Text(
                  faceOff.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text(_statusText),
                  ),
                ),
                const SizedBox(height: 28),
                if (faceOff.isLive && !_voteSubmitted) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _SideButton(
                          label: faceOff.sideAName,
                          selected: _selectedSide == 1,
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  setState(() {
                                    _selectedSide = 1;
                                  });
                                },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SideButton(
                          label: faceOff.sideBName,
                          selected: _selectedSide == 2,
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  setState(() {
                                    _selectedSide = 2;
                                  });
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Coin boost',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [0, 10, 25, 50].map((boost) {
                      return ChoiceChip(
                        label: Text(
                          boost == 0
                              ? 'No boost'
                              : '+$boost support',
                        ),
                        selected: _coinBoost == boost,
                        onSelected: _isSubmitting
                            ? null
                            : (_) {
                                setState(() {
                                  _coinBoost = boost;
                                });
                              },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed:
                        _isSubmitting ? null : _submitVote,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Submit vote'),
                    ),
                  ),
                ] else if (_voteSubmitted) ...[
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your vote has been recorded.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  OutlinedButton(
                     onPressed: () {
                     Navigator.push(
                   context,
                   MaterialPageRoute(
                       builder: (_) => FaceOffResultsScreen(
                  faceOff: faceOff,
                ),
              ),
            );
          },
             child: const Padding(
           padding: EdgeInsets.symmetric(vertical: 14),
         child: Text('View results'),
        ),
      ),
                ],
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 20),
                Text(
                  'Discussion',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Comments will be connected after voting.',
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
}

class _SideButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  const _SideButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return selected
        ? FilledButton(
            onPressed: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
              ),
            ),
          )
        : OutlinedButton(
            onPressed: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
              ),
            ),
          );
  }
}