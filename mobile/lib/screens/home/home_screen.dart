import 'package:flutter/material.dart';

import '../../core/services/faceoff_service.dart';
import '../../models/faceoff.dart';
import '../faceoff/faceoff_details_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final int coinBalance;

  const HomeScreen({
    super.key,
    required this.username,
    required this.coinBalance,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FaceOffService _faceOffService = FaceOffService();

  late Future<List<FaceOff>> _faceOffsFuture;

  @override
  void initState() {
    super.initState();
    _loadFaceOffs();
  }

  void _loadFaceOffs() {
    _faceOffsFuture = _faceOffService.getFaceOffs();
  }

  Future<void> _refresh() async {
    setState(_loadFaceOffs);
    await _faceOffsFuture;
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  void _openFaceOff(FaceOff faceOff) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FaceOffDetailsScreen(
          faceOff: faceOff,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TugOfWar'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.monetization_on_outlined),
                  const SizedBox(width: 6),
                  Text('${widget.coinBalance}'),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: _openProfile,
            icon: const Icon(Icons.person_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<FaceOff>>(
        future: _faceOffsFuture,
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
                      onPressed: () {
                        setState(_loadFaceOffs);
                      },
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final faceOffs = snapshot.data ?? [];

          if (faceOffs.isEmpty) {
            return const Center(
              child: Text('No face-offs available.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: faceOffs.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final faceOff = faceOffs[index];

                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openFaceOff(faceOff),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  faceOff.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                ),
                              ),
                              if (faceOff.isFeatured)
                                const Icon(
                                  Icons.star_rounded,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(faceOff.description),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  faceOff.sideAName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text('VS'),
                              ),
                              Expanded(
                                child: Text(
                                  faceOff.sideBName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            faceOff.isLive
                                ? 'Live now'
                                : 'Not currently live',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}