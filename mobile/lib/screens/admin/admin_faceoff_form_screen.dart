import 'package:flutter/material.dart';

import '../../core/services/admin_faceoff_service.dart';
import '../../core/services/category_service.dart';
import '../../models/category.dart';
import '../../models/faceoff.dart';

class AdminFaceOffFormScreen extends StatefulWidget {
  final FaceOff? faceOff;

  const AdminFaceOffFormScreen({
    super.key,
    this.faceOff,
  });

  bool get isEditing => faceOff != null;

  @override
  State<AdminFaceOffFormScreen> createState() =>
      _AdminFaceOffFormScreenState();
}

class _AdminFaceOffFormScreenState
    extends State<AdminFaceOffFormScreen> {
  final AdminFaceOffService _adminService =
      AdminFaceOffService();

  final CategoryService _categoryService =
      CategoryService();

  final _formKey = GlobalKey<FormState>();

  final _titleController =
      TextEditingController();

  final _descriptionController =
      TextEditingController();

  final _sideAController =
      TextEditingController();

  final _sideBController =
      TextEditingController();

  final _sideAImageUrlController =
      TextEditingController();

  final _sideBImageUrlController =
      TextEditingController();

  late Future<List<Category>> _categoriesFuture;

  int? _selectedCategoryId;
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isFeatured = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _categoriesFuture =
        _categoryService.getCategories();

    final faceOff = widget.faceOff;

    if (faceOff != null) {
      _titleController.text =
          faceOff.title;

      _descriptionController.text =
          faceOff.description;

      _sideAController.text =
          faceOff.sideAName;

      _sideBController.text =
          faceOff.sideBName;

      _sideAImageUrlController.text =
          faceOff.sideAImageUrl ?? '';

      _sideBImageUrlController.text =
          faceOff.sideBImageUrl ?? '';

      _selectedCategoryId =
          faceOff.categoryId;

      _startTime =
          faceOff.startTime.toLocal();

      _endTime =
          faceOff.endTime.toLocal();

      _isFeatured =
          faceOff.isFeatured;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _sideAController.dispose();
    _sideBController.dispose();
    _sideAImageUrlController.dispose();
    _sideBImageUrlController.dispose();

    super.dispose();
  }

  Future<void> _selectStartTime() async {
    final selected = await _pickDateTime(
      initialValue:
          _startTime ?? DateTime.now(),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _startTime = selected;
    });
  }

  Future<void> _selectEndTime() async {
    final selected = await _pickDateTime(
      initialValue: _endTime ??
          DateTime.now().add(
            const Duration(days: 1),
          ),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _endTime = selected;
    });
  }

  Future<DateTime?> _pickDateTime({
    required DateTime initialValue,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialValue,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date == null || !mounted) {
      return null;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        initialValue,
      ),
    );

    if (time == null) {
      return null;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      _showMessage(
        'Choose a category.',
      );
      return;
    }

    if (_startTime == null ||
        _endTime == null) {
      _showMessage(
        'Choose the start and end times.',
      );
      return;
    }

    if (!_endTime!.isAfter(
      _startTime!,
    )) {
      _showMessage(
        'End time must be later than start time.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.isEditing) {
        await _adminService.updateFaceOff(
          faceOffId:
              widget.faceOff!.id,
          title:
              _titleController.text,
          description:
              _descriptionController.text,
          categoryId:
              _selectedCategoryId!,
          sideAName:
              _sideAController.text,
          sideBName:
              _sideBController.text,
          sideAImageUrl:
              _sideAImageUrlController.text,
          sideBImageUrl:
              _sideBImageUrlController.text,
          startTime:
              _startTime!,
          endTime:
              _endTime!,
          isFeatured:
              _isFeatured,
        );
      } else {
        await _adminService.createFaceOff(
          title:
              _titleController.text,
          description:
              _descriptionController.text,
          categoryId:
              _selectedCategoryId!,
          sideAName:
              _sideAController.text,
          sideBName:
              _sideBController.text,
          sideAImageUrl:
              _sideAImageUrlController.text,
          sideBImageUrl:
              _sideBImageUrlController.text,
          startTime:
              _startTime!,
          endTime:
              _endTime!,
          isFeatured:
              _isFeatured,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
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
          _isSaving = false;
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
          content: Text(message),
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

  String _formatDateTime(
    DateTime? value,
  ) {
    if (value == null) {
      return 'Not selected';
    }

    final day =
        value.day.toString().padLeft(2, '0');

    final month =
        value.month.toString().padLeft(2, '0');

    final hour =
        value.hour.toString().padLeft(2, '0');

    final minute =
        value.minute.toString().padLeft(2, '0');

    return '$day.$month.${value.year} '
        '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Edit face-off'
              : 'Create face-off',
        ),
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
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
                    const EdgeInsets.all(24),
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
                      onPressed: () {
                        setState(() {
                          _categoriesFuture =
                              _categoryService
                                  .getCategories();
                        });
                      },
                      child: const Text(
                        'Try again',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final categories =
              snapshot.data ?? [];

          return SingleChildScrollView(
            padding:
                const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 700,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                    children: [
                      TextFormField(
                        controller:
                            _titleController,
                        enabled:
                            !_isSaving,
                        maxLength: 150,
                        decoration:
                            const InputDecoration(
                          labelText: 'Title',
                          border:
                              OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Enter a title.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller:
                            _descriptionController,
                        enabled:
                            !_isSaving,
                        minLines: 3,
                        maxLines: 6,
                        maxLength: 1000,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Description',
                          border:
                              OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Enter a description.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue:
                            _selectedCategoryId,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Category',
                          border:
                              OutlineInputBorder(),
                        ),
                        items: categories
                            .map(
                              (category) =>
                                  DropdownMenuItem<int>(
                                value:
                                    category.id,
                                child: Text(
                                  category.name,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged:
                            _isSaving
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedCategoryId =
                                          value;
                                    });
                                  },
                        validator: (value) {
                          if (value == null) {
                            return 'Choose a category.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller:
                            _sideAController,
                        enabled:
                            !_isSaving,
                        maxLength: 100,
                        decoration:
                            const InputDecoration(
                          labelText: 'Side A',
                          border:
                              OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Enter Side A.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller:
                            _sideBController,
                        enabled:
                            !_isSaving,
                        maxLength: 100,
                        decoration:
                            const InputDecoration(
                          labelText: 'Side B',
                          border:
                              OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Enter Side B.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller:
                            _sideAImageUrlController,
                        enabled:
                            !_isSaving,
                        maxLength: 1000,
                        keyboardType:
                            TextInputType.url,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Side A image URL (optional)',
                          hintText:
                              'https://...',
                          prefixIcon: Icon(
                            Icons.image_outlined,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ImageUrlPreview(
                        controller:
                            _sideAImageUrlController,
                        label:
                            'Side A preview',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller:
                            _sideBImageUrlController,
                        enabled:
                            !_isSaving,
                        maxLength: 1000,
                        keyboardType:
                            TextInputType.url,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Side B image URL (optional)',
                          hintText:
                              'https://...',
                          prefixIcon: Icon(
                            Icons.image_outlined,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ImageUrlPreview(
                        controller:
                            _sideBImageUrlController,
                        label:
                            'Side B preview',
                      ),
                      const SizedBox(height: 16),
                      _DateTimeCard(
                        label: 'Start time',
                        value:
                            _formatDateTime(
                          _startTime,
                        ),
                        onPressed:
                            _isSaving
                                ? null
                                : _selectStartTime,
                      ),
                      const SizedBox(height: 12),
                      _DateTimeCard(
                        label: 'End time',
                        value:
                            _formatDateTime(
                          _endTime,
                        ),
                        onPressed:
                            _isSaving
                                ? null
                                : _selectEndTime,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        value: _isFeatured,
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                setState(() {
                                  _isFeatured =
                                      value;
                                });
                              },
                        title: const Text(
                          'Featured',
                        ),
                        subtitle: const Text(
                          'Show this face-off more prominently.',
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed:
                            _isSaving
                                ? null
                                : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                widget.isEditing
                                    ? Icons
                                        .save_outlined
                                    : Icons
                                        .add_outlined,
                              ),
                        label: Text(
                          _isSaving
                              ? 'Saving...'
                              : widget.isEditing
                                  ? 'Save changes'
                                  : 'Create face-off',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DateTimeCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onPressed;

  const _DateTimeCard({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 14,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(value),
                ],
              ),
            ),
            const Icon(
              Icons.edit_calendar_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageUrlPreview extends StatefulWidget {
  final TextEditingController controller;
  final String label;

  const _ImageUrlPreview({
    required this.controller,
    required this.label,
  });

  @override
  State<_ImageUrlPreview> createState() =>
      _ImageUrlPreviewState();
}

class _ImageUrlPreviewState
    extends State<_ImageUrlPreview> {
  @override
  void initState() {
    super.initState();

    widget.controller.addListener(
      _handleChanged,
    );
  }

  @override
  void didUpdateWidget(
    covariant _ImageUrlPreview oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller !=
        widget.controller) {
      oldWidget.controller.removeListener(
        _handleChanged,
      );

      widget.controller.addListener(
        _handleChanged,
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(
      _handleChanged,
    );

    super.dispose();
  }

  void _handleChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final url =
        widget.controller.text.trim();

    if (url.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.image_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${widget.label}: no image URL',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final uri = Uri.tryParse(url);

    final isValidHttpUrl =
        uri != null &&
        (uri.scheme == 'http' ||
            uri.scheme == 'https') &&
        uri.host.isNotEmpty;

    if (!isValidHttpUrl) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${widget.label}: invalid URL',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),
            child: Text(
              widget.label,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (
                context,
                child,
                loadingProgress,
              ) {
                if (loadingProgress == null) {
                  return child;
                }

                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              },
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return const Center(
                  child: Padding(
                    padding:
                        EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          Icons
                              .broken_image_outlined,
                          size: 40,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Image could not be loaded. '
                          'Use a direct image URL.',
                          textAlign:
                              TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}