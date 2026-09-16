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
  static const Color _purple =
      Color(0xFF6C4DFF);

  static const Color _sideABlue =
      Color(0xFF147BFF);

  static const Color _sideALight =
      Color(0xFFEAF3FF);

  static const Color _sideBRed =
      Color(0xFFFF3158);

  static const Color _sideBLight =
      Color(0xFFFFEDF1);

  static const Color _secondaryText =
      Color(0xFF686570);

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
      return 'Unable to connect to TugVote. '
          'Check your connection and try again.';
    }

    return 'Something went wrong while loading TugVote. '
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
      _selectedSort = sort;

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
        return Icons.lock_outline_rounded;

      case 'Archived':
        return Icons.archive_outlined;

      default:
        return Icons.help_outline;
    }
  }

  Color _statusColor(
    FaceOff faceOff,
  ) {
    final status =
        _displayStatus(
      faceOff,
    );

    switch (status) {
      case 'Live now':
        return const Color(
          0xFF13A864,
        );

      case 'Scheduled':
        return _purple;

      case 'Closed':
        return const Color(
          0xFF5E5B66,
        );

      case 'Archived':
        return const Color(
          0xFF77737E,
        );

      default:
        return _secondaryText;
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

  Widget _buildCategoryChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        right: 8,
      ),
      child: ChoiceChip(
        label: Text(
          label,
        ),
        selected: selected,
        showCheckmark: selected,
        checkmarkColor: Colors.white,
        selectedColor: _purple,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected
              ? _purple
              : const Color(
                  0xFFE4E1EA,
                ),
        ),
        labelStyle: TextStyle(
          color: selected
              ? Colors.white
              : const Color(
                  0xFF3C3942,
                ),
          fontWeight: selected
              ? FontWeight.w700
              : FontWeight.w500,
        ),
        onSelected: (_) {
          onTap();
        },
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        right: 8,
      ),
      child: ChoiceChip(
        label: Text(
          label,
        ),
        selected: selected,
        showCheckmark: false,
        selectedColor:
            const Color(
          0xFFE9E4FF,
        ),
        backgroundColor:
            Colors.white,
        side: BorderSide(
          color: selected
              ? _purple
              : const Color(
                  0xFFE4E1EA,
                ),
        ),
        labelStyle: TextStyle(
          color: selected
              ? _purple
              : const Color(
                  0xFF3C3942,
                ),
          fontWeight: selected
              ? FontWeight.w700
              : FontWeight.w500,
        ),
        onSelected: (_) {
          onTap();
        },
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
                      'TugVote',
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
                      'TugVote',
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
                    'TugVote',
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
                  12,
                  16,
                  6,
                ),
                child: SizedBox(
                  height: 48,
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
                        size: 21,
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
                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 0,
                        horizontal: 14,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 46,
                child: ListView(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                  ),
                  scrollDirection:
                      Axis.horizontal,
                  children: [
                    _buildCategoryChip(
                      label: 'All',
                      selected:
                          _selectedCategoryId ==
                              null,
                      onTap: () {
                        _selectCategory(
                          null,
                        );
                      },
                    ),
                    ...categories.map(
                      (category) =>
                          _buildCategoryChip(
                        label:
                            category.name,
                        selected:
                            _selectedCategoryId ==
                                category.id,
                        onTap: () {
                          _selectCategory(
                            category.id,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                  ),
                  scrollDirection:
                      Axis.horizontal,
                  children: [
                    _buildStatusChip(
                      label: 'All',
                      selected:
                          _selectedStatus ==
                              'All',
                      onTap: () {
                        _selectStatus(
                          'All',
                        );
                      },
                    ),
                    _buildStatusChip(
                      label: 'Live',
                      selected:
                          _selectedStatus ==
                              'Live',
                      onTap: () {
                        _selectStatus(
                          'Live',
                        );
                      },
                    ),
                    _buildStatusChip(
                      label: 'Closed',
                      selected:
                          _selectedStatus ==
                              'Closed',
                      onTap: () {
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
                  2,
                  16,
                  8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sort_rounded,
                      size: 19,
                      color:
                          _secondaryText,
                    ),
                    const SizedBox(
                      width: 7,
                    ),
                    const Text(
                      'Sort by',
                      style: TextStyle(
                        color:
                            _secondaryText,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child:
                            DropdownButtonFormField<
                                String>(
                          initialValue:
                              _selectedSort,
                          decoration:
                              const InputDecoration(
                            isDense: true,
                            contentPadding:
                                EdgeInsets
                                    .symmetric(
                              horizontal: 14,
                            ),
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
                                .fromLTRB(
                          16,
                          8,
                          16,
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
                                Clip.antiAlias,
                            child: InkWell(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
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
                                                      FontWeight.w800,
                                                ),
                                          ),
                                        ),
                                        if (faceOff
                                            .isFeatured)
                                          Container(
                                            width:
                                                32,
                                            height:
                                                32,
                                            decoration:
                                                const BoxDecoration(
                                              color:
                                                  Color(
                                                0xFFEDE9FF,
                                              ),
                                              shape:
                                                  BoxShape.circle,
                                            ),
                                            child:
                                                const Icon(
                                              Icons
                                                  .star_rounded,
                                              color:
                                                  _purple,
                                              size:
                                                  20,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 6,
                                    ),
                                    Text(
                                      faceOff
                                          .description,
                                      style:
                                          const TextStyle(
                                        color:
                                            _secondaryText,
                                        height:
                                            1.35,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 16,
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
                                                faceOff
                                                    .sideAImageUrl,
                                            label:
                                                faceOff
                                                    .sideAName,
                                            fallbackIcon:
                                                Icons
                                                    .chevron_left_rounded,
                                            accentColor:
                                                _sideABlue,
                                            tintColor:
                                                _sideALight,
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            horizontal:
                                                10,
                                          ),
                                          child:
                                              Column(
                                            children: [
                                              const SizedBox(
                                                height:
                                                    38,
                                              ),
                                              Container(
                                                width:
                                                    44,
                                                height:
                                                    44,
                                                alignment:
                                                    Alignment
                                                        .center,
                                                decoration:
                                                    BoxDecoration(
                                                  color:
                                                      _purple,
                                                  shape:
                                                      BoxShape
                                                          .circle,
                                                  border:
                                                      Border.all(
                                                    color:
                                                        Colors.white,
                                                    width:
                                                        3,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: _purple
                                                          .withValues(
                                                        alpha:
                                                            0.28,
                                                      ),
                                                      blurRadius:
                                                          16,
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
                                                    fontSize:
                                                        13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child:
                                              _HomeSidePreview(
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
                                                _sideBRed,
                                            tintColor:
                                                _sideBLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 14,
                                    ),
                                    _StatusBadge(
                                      text:
                                          _displayStatus(
                                        faceOff,
                                      ),
                                      icon:
                                          _statusIcon(
                                        faceOff,
                                      ),
                                      color:
                                          _statusColor(
                                        faceOff,
                                      ),
                                    ),
                                    if (_isClosed(
                                          faceOff,
                                        ) &&
                                        faceOff
                                            .hasFinalResult) ...[
                                      const SizedBox(
                                        height:
                                            14,
                                      ),
                                      const Divider(),
                                      const SizedBox(
                                        height:
                                            12,
                                      ),
                                      _WinnerBanner(
                                        isTie:
                                            faceOff.isTie ==
                                                true,
                                        winnerName:
                                            faceOff
                                                .winningSideName,
                                        sideAName:
                                            faceOff
                                                .sideAName,
                                        sideBName:
                                            faceOff
                                                .sideBName,
                                      ),
                                      const SizedBox(
                                        height:
                                            14,
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
                                                  TextOverflow
                                                      .ellipsis,
                                              style:
                                                  const TextStyle(
                                                color:
                                                    _sideABlue,
                                                fontWeight:
                                                    FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${faceOff.sideAPercentage!.toStringAsFixed(1)}%',
                                            style:
                                                const TextStyle(
                                              color:
                                                  _sideABlue,
                                              fontWeight:
                                                  FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(
                                            width:
                                                14,
                                          ),
                                          Text(
                                            '${faceOff.sideBPercentage!.toStringAsFixed(1)}%',
                                            style:
                                                const TextStyle(
                                              color:
                                                  _sideBRed,
                                              fontWeight:
                                                  FontWeight.w800,
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
                                                  TextOverflow
                                                      .ellipsis,
                                              textAlign:
                                                  TextAlign.right,
                                              style:
                                                  const TextStyle(
                                                color:
                                                    _sideBRed,
                                                fontWeight:
                                                    FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height:
                                            9,
                                      ),
                                      _ResultBar(
                                        sideAPercentage:
                                            faceOff
                                                .sideAPercentage!,
                                      ),
                                      const SizedBox(
                                        height:
                                            14,
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
                                                .bar_chart_rounded,
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
  final Color accentColor;
  final Color tintColor;

  const _HomeSidePreview({
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
          aspectRatio: 16 / 10,
          child: Container(
            decoration: BoxDecoration(
              color: tintColor,
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
              border: Border.all(
                color: accentColor
                    .withValues(
                  alpha: 0.65,
                ),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor
                      .withValues(
                    alpha: 0.11,
                  ),
                  blurRadius: 12,
                  offset:
                      const Offset(
                    0,
                    4,
                  ),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                13.5,
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
                        return _placeholder();
                      },
                    )
                  : _placeholder(),
            ),
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        Container(
          constraints:
              const BoxConstraints(
            minHeight: 28,
          ),
          alignment:
              Alignment.topCenter,
          child: Text(
            label,
            textAlign:
                TextAlign.center,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              color: accentColor,
              fontWeight:
                  FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      color: tintColor,
      child: Center(
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white
                .withValues(
              alpha: 0.92,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: accentColor
                  .withValues(
                alpha: 0.14,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor
                    .withValues(
                  alpha: 0.10,
                ),
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(
            fallbackIcon,
            color: accentColor,
            size: 38,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge
    extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _StatusBadge({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(
          9,
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
            size: text == 'Live now'
                ? 9
                : 14,
            color: color,
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

class _WinnerBanner
    extends StatelessWidget {
  final bool isTie;
  final String? winnerName;
  final String sideAName;
  final String sideBName;

  const _WinnerBanner({
    required this.isTie,
    required this.winnerName,
    required this.sideAName,
    required this.sideBName,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    const purple =
        Color(0xFF6C4DFF);

    const blue =
        Color(0xFF147BFF);

    const red =
        Color(0xFFFF3158);

    Color accent = purple;

    if (!isTie) {
      if (winnerName ==
          sideAName) {
        accent = blue;
      } else if (winnerName ==
          sideBName) {
        accent = red;
      }
    }

    final resultText = isTie
        ? 'Final result: Tie'
        : '${winnerName ?? 'Winner'} won';

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: accent.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(
                alpha: 0.13,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isTie
                  ? Icons
                      .balance_rounded
                  : Icons
                      .emoji_events_rounded,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              resultText,
              style: TextStyle(
                color: accent,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBar
    extends StatelessWidget {
  final double sideAPercentage;

  const _ResultBar({
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

    final normalized =
        (sideAPercentage / 100)
            .clamp(
              0.0,
              1.0,
            );

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(
        100,
      ),
      child: SizedBox(
        height: 9,
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final blueWidth =
                constraints.maxWidth *
                    normalized;

            return Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(
                    color: red,
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: blueWidth,
                  child:
                      const ColoredBox(
                    color: blue,
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