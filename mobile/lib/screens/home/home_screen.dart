import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/category_service.dart';
import '../../core/services/faceoff_service.dart';
import '../../core/state/app_state.dart';
import '../../models/category.dart';
import '../../models/faceoff.dart';
import '../faceoff/faceoff_details_screen.dart';
import '../faceoff/faceoff_results_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool showAppBar;

  const HomeScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  final FaceOffService _faceOffService =
      FaceOffService();

  final CategoryService _categoryService =
      CategoryService();

  final TextEditingController
      _searchController =
      TextEditingController();

  late Future<List<FaceOff>>
      _faceOffsFuture;

  late Future<List<Category>>
      _categoriesFuture;

  String _searchText = '';
  int? _selectedCategoryId;
  String _selectedStatus = 'All';
  String _selectedSort = 'Featured';

  @override
  void initState() {
    super.initState();

    _loadData();

    _searchController.addListener(
      _handleSearchChanged,
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(
      _handleSearchChanged,
    );

    _searchController.dispose();

    super.dispose();
  }

  void _loadData() {
    _faceOffsFuture =
        _faceOffService.getFaceOffs();

    _categoriesFuture =
        _categoryService.getCategories();
  }

  String _friendlyErrorMessage(
    Object? error,
  ) {
    final message =
        error?.toString().toLowerCase() ?? '';

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
        )) {
      return 'Unable to connect to TugOfWar. '
          'Check your connection and try again.';
    }

    return 'Something went wrong while loading TugOfWar. '
        'Please try again.';
  }

  void _retry() {
    setState(() {
      _loadData();
    });
  }

  void _handleSearchChanged() {
    final value =
        _searchController.text
            .trim()
            .toLowerCase();

    if (value == _searchText) {
      return;
    }

    setState(() {
      _searchText = value;
    });
  }

  void _clearSearch() {
    _searchController.clear();
  }

  void _selectCategory(
    int? categoryId,
  ) {
    setState(() {
      _selectedCategoryId =
          categoryId;
    });
  }

  void _selectStatus(
    String status,
  ) {
    setState(() {
      _selectedStatus =
          status;
    });
  }

  void _selectSort(
    String sort,
  ) {
    setState(() {
      _selectedSort =
          sort;

      if (sort == 'Ending soon') {
        _selectedStatus = 'Live';
      } else if (sort ==
          'Recently closed') {
        _selectedStatus = 'Closed';
      }
    });
  }

  Future<void> _refresh() async {
    setState(_loadData);

    try {
      await Future.wait([
        _faceOffsFuture,
        _categoriesFuture,
      ]);

      if (!mounted) {
        return;
      }

      await context
          .read<AppState>()
          .loadProfile();
    } catch (_) {
      // The FutureBuilders display the
      // appropriate error state.
    }
  }

  Future<void> _openFaceOff(
    FaceOff faceOff,
  ) async {
    final balanceMayHaveChanged =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FaceOffDetailsScreen(
          faceOff: faceOff,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (balanceMayHaveChanged == true) {
      await context
          .read<AppState>()
          .loadProfile();
    }
  }

  Future<void> _openResults(
    FaceOff faceOff,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FaceOffResultsScreen(
          faceOff: faceOff,
        ),
      ),
    );
  }

  String _displayStatus(
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
      return 'Live now';
    }

    if (faceOff.status == 1) {
      return 'Scheduled';
    }

    return 'Unavailable';
  }

  IconData _statusIcon(
    FaceOff faceOff,
  ) {
    final status =
        _displayStatus(
      faceOff,
    );

    switch (status) {
      case 'Live now':
        return Icons.circle;

      case 'Scheduled':
        return Icons.schedule_outlined;

      case 'Closed':
        return Icons.lock_clock_outlined;

      case 'Archived':
        return Icons.archive_outlined;

      default:
        return Icons.help_outline;
    }
  }

  bool _isLive(
    FaceOff faceOff,
  ) {
    return _displayStatus(
          faceOff,
        ) ==
        'Live now';
  }

  bool _isClosed(
    FaceOff faceOff,
  ) {
    return _displayStatus(
          faceOff,
        ) ==
        'Closed';
  }

  bool _matchesSelectedStatus(
    FaceOff faceOff,
  ) {
    if (_selectedStatus == 'All') {
      return true;
    }

    if (_selectedStatus == 'Live') {
      return _isLive(
        faceOff,
      );
    }

    if (_selectedStatus == 'Closed') {
      return _isClosed(
        faceOff,
      );
    }

    return true;
  }

  List<FaceOff> _applySort(
    List<FaceOff> faceOffs,
  ) {
    if (_selectedSort == 'Featured') {
      final featured =
          faceOffs
              .where(
                (faceOff) =>
                    faceOff.isFeatured,
              )
              .toList();

      final normal =
          faceOffs
              .where(
                (faceOff) =>
                    !faceOff.isFeatured,
              )
              .toList();

      return [
        ...featured,
        ...normal,
      ];
    }

    if (_selectedSort == 'Newest') {
      final sorted =
          List<FaceOff>.from(
        faceOffs,
      );

      sorted.sort(
        (a, b) =>
            b.startTime.compareTo(
          a.startTime,
        ),
      );

      return sorted;
    }

    if (_selectedSort ==
        'Ending soon') {
      final liveFaceOffs =
          faceOffs
              .where(
                _isLive,
              )
              .toList();

      liveFaceOffs.sort(
        (a, b) =>
            a.endTime.compareTo(
          b.endTime,
        ),
      );

      return liveFaceOffs;
    }

    if (_selectedSort ==
        'Recently closed') {
      final closedFaceOffs =
          faceOffs
              .where(
                _isClosed,
              )
              .toList();

      closedFaceOffs.sort(
        (a, b) =>
            b.endTime.compareTo(
          a.endTime,
        ),
      );

      return closedFaceOffs;
    }

    return faceOffs;
  }

  List<FaceOff> _filteredFaceOffs(
    List<FaceOff> faceOffs,
  ) {
    final filtered =
        faceOffs.where(
      (faceOff) {
        final matchesCategory =
            _selectedCategoryId ==
                    null ||
                faceOff.categoryId ==
                    _selectedCategoryId;

        if (!matchesCategory) {
          return false;
        }

        if (!_matchesSelectedStatus(
          faceOff,
        )) {
          return false;
        }

        if (_searchText.isEmpty) {
          return true;
        }

        final searchableText = [
          faceOff.title,
          faceOff.description,
          faceOff.sideAName,
          faceOff.sideBName,
        ].join(' ').toLowerCase();

        return searchableText.contains(
          _searchText,
        );
      },
    ).toList();

    return _applySort(
      filtered,
    );
  }

  Widget _buildErrorState(
    Object? error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
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
              onPressed: _retry,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Retry',
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
    final appState =
        context.watch<AppState>();

    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (
        context,
        categorySnapshot,
      ) {
        if (categorySnapshot
                .connectionState ==
            ConnectionState.waiting) {
          return Scaffold(
            appBar: widget.showAppBar
                ? AppBar(
                    title: const Text(
                      'TugOfWar',
                    ),
                  )
                : null,
            body: const Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        if (categorySnapshot.hasError) {
          return Scaffold(
            appBar: widget.showAppBar
                ? AppBar(
                    title: const Text(
                      'TugOfWar',
                    ),
                  )
                : null,
            body: _buildErrorState(
              categorySnapshot.error,
            ),
          );
        }

        final categories =
            categorySnapshot.data ??
                [];

        return Scaffold(
          appBar: widget.showAppBar
              ? AppBar(
                  title:
                      const Text(
                    'TugOfWar',
                  ),
                  actions: [
                    Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        right: 16,
                      ),
                      child: Center(
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .monetization_on_outlined,
                            ),
                            const SizedBox(
                              width: 6,
                            ),
                            Text(
                              '${appState.coinBalance}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : null,
          body: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets
                        .fromLTRB(
                  16,
                  16,
                  16,
                  8,
                ),
                child: TextField(
                  controller:
                      _searchController,
                  decoration:
                      InputDecoration(
                    hintText:
                        'Search face-offs...',
                    prefixIcon:
                        const Icon(
                      Icons.search,
                    ),
                    suffixIcon:
                        _searchText.isEmpty
                            ? null
                            : IconButton(
                                onPressed:
                                    _clearSearch,
                                icon:
                                    const Icon(
                                  Icons.clear,
                                ),
                              ),
                    border:
                        const OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                height: 52,
                child: ListView(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                  ),
                  scrollDirection:
                      Axis.horizontal,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        right: 8,
                      ),
                      child: ChoiceChip(
                        label:
                            const Text(
                          'All',
                        ),
                        selected:
                            _selectedCategoryId ==
                                null,
                        onSelected: (
                          selected,
                        ) {
                          _selectCategory(
                            null,
                          );
                        },
                      ),
                    ),
                    ...categories.map(
                      (category) =>
                          Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          right: 8,
                        ),
                        child:
                            ChoiceChip(
                          label: Text(
                            category.name,
                          ),
                          selected:
                              _selectedCategoryId ==
                                  category
                                      .id,
                          onSelected: (
                            selected,
                          ) {
                            _selectCategory(
                              category.id,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 52,
                child: ListView(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                  ),
                  scrollDirection:
                      Axis.horizontal,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        right: 8,
                      ),
                      child: ChoiceChip(
                        label:
                            const Text(
                          'All',
                        ),
                        selected:
                            _selectedStatus ==
                                'All',
                        onSelected: (
                          selected,
                        ) {
                          _selectStatus(
                            'All',
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        right: 8,
                      ),
                      child: ChoiceChip(
                        label:
                            const Text(
                          'Live',
                        ),
                        selected:
                            _selectedStatus ==
                                'Live',
                        onSelected: (
                          selected,
                        ) {
                          _selectStatus(
                            'Live',
                          );
                        },
                      ),
                    ),
                    ChoiceChip(
                      label:
                          const Text(
                        'Closed',
                      ),
                      selected:
                          _selectedStatus ==
                              'Closed',
                      onSelected: (
                        selected,
                      ) {
                        _selectStatus(
                          'Closed',
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets
                        .fromLTRB(
                  16,
                  0,
                  16,
                  8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sort_outlined,
                      size: 20,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    const Text(
                      'Sort by',
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child:
                          DropdownButtonFormField<
                              String>(
                        initialValue:
                            _selectedSort,
                        decoration:
                            const InputDecoration(
                          isDense: true,
                          border:
                              OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value:
                                'Featured',
                            child: Text(
                              'Featured',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'Newest',
                            child: Text(
                              'Newest',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'Ending soon',
                            child: Text(
                              'Ending soon',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'Recently closed',
                            child: Text(
                              'Recently closed',
                            ),
                          ),
                        ],
                        onChanged: (
                          value,
                        ) {
                          if (value ==
                              null) {
                            return;
                          }

                          _selectSort(
                            value,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Expanded(
                child:
                    FutureBuilder<
                        List<FaceOff>>(
                  future:
                      _faceOffsFuture,
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

                    if (snapshot
                        .hasError) {
                      return _buildErrorState(
                        snapshot.error,
                      );
                    }

                    final filtered =
                        _filteredFaceOffs(
                      snapshot.data ??
                          [],
                    );

                    if (filtered
                        .isEmpty) {
                      return RefreshIndicator(
                        onRefresh:
                            _refresh,
                        child: ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          children:
                              const [
                            SizedBox(
                              height:
                                  180,
                            ),
                            Center(
                              child: Text(
                                'No face-offs match your filters.',
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
                          ListView.builder(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets
                                .all(
                          16,
                        ),
                        itemCount:
                            filtered.length,
                        itemBuilder: (
                          context,
                          index,
                        ) {
                          final faceOff =
                              filtered[
                                  index];

                          return Card(
                            margin:
                                const EdgeInsets
                                    .only(
                              bottom: 16,
                            ),
                            clipBehavior:
                                Clip
                                    .antiAlias,
                            child:
                                InkWell(
                              onTap: () =>
                                  _openFaceOff(
                                faceOff,
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets
                                        .all(
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
                                          child:
                                              Text(
                                            faceOff
                                                .title,
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
                                          16,
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Expanded(
                                          child:
                                              _HomeSidePreview(
                                            imageUrl:
                                                faceOff.sideAImageUrl,
                                            label:
                                                faceOff.sideAName,
                                            fallbackIcon:
                                                Icons.chevron_left_rounded,
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal:
                                                12,
                                          ),
                                          child:
                                              Column(
                                            children: [
                                              const SizedBox(
                                                height:
                                                    42,
                                              ),
                                              Text(
                                                'VS',
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
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child:
                                              _HomeSidePreview(
                                            imageUrl:
                                                faceOff.sideBImageUrl,
                                            label:
                                                faceOff.sideBName,
                                            fallbackIcon:
                                                Icons.chevron_right_rounded,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height:
                                          14,
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          _statusIcon(
                                            faceOff,
                                          ),
                                          size:
                                              14,
                                        ),
                                        const SizedBox(
                                          width:
                                              6,
                                        ),
                                        Text(
                                          _displayStatus(
                                            faceOff,
                                          ),
                                          style: Theme.of(
                                            context,
                                          )
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                    if (_isClosed(
                                          faceOff,
                                        ) &&
                                        faceOff
                                            .hasFinalResult) ...[
                                      const SizedBox(
                                        height:
                                            16,
                                      ),
                                      const Divider(),
                                      const SizedBox(
                                        height:
                                            10,
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            faceOff.isTie ==
                                                    true
                                                ? Icons
                                                    .balance_outlined
                                                : Icons
                                                    .emoji_events_outlined,
                                            size:
                                                22,
                                          ),
                                          const SizedBox(
                                            width:
                                                8,
                                          ),
                                          Expanded(
                                            child:
                                                Text(
                                              faceOff.isTie ==
                                                      true
                                                  ? 'Final result: Tie'
                                                  : '${faceOff.winningSideName} won',
                                              style:
                                                  const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height:
                                            10,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child:
                                                Text(
                                              faceOff
                                                  .sideAName,
                                              maxLines:
                                                  1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            '${faceOff.sideAPercentage!.toStringAsFixed(1)}%',
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                          const Padding(
                                            padding:
                                                EdgeInsets.symmetric(
                                              horizontal:
                                                  10,
                                            ),
                                            child:
                                                Text(
                                              '—',
                                            ),
                                          ),
                                          Text(
                                            '${faceOff.sideBPercentage!.toStringAsFixed(1)}%',
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(
                                            width:
                                                8,
                                          ),
                                          Expanded(
                                            child:
                                                Text(
                                              faceOff
                                                  .sideBName,
                                              maxLines:
                                                  1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              textAlign:
                                                  TextAlign.right,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height:
                                            12,
                                      ),
                                      SizedBox(
                                        width:
                                            double.infinity,
                                        child:
                                            OutlinedButton
                                                .icon(
                                          onPressed:
                                              () {
                                            _openResults(
                                              faceOff,
                                            );
                                          },
                                          icon:
                                              const Icon(
                                            Icons
                                                .bar_chart_outlined,
                                          ),
                                          label:
                                              const Text(
                                            'View results',
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
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeSidePreview
    extends StatelessWidget {
  final String? imageUrl;
  final String label;
  final IconData fallbackIcon;

  const _HomeSidePreview({
    required this.imageUrl,
    required this.label,
    required this.fallbackIcon,
  });

  bool get _hasImage =>
      imageUrl != null &&
      imageUrl!
          .trim()
          .isNotEmpty;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            child: _hasImage
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (
                      imageContext,
                      error,
                      stackTrace,
                    ) {
                      return _placeholder(
                        context,
                      );
                    },
                  )
                : _placeholder(
                    context,
                  ),
          ),
        ),
        const SizedBox(
          height: 8,
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
      child: Center(
        child: Icon(
          fallbackIcon,
          size: 36,
        ),
      ),
    );
  }
}