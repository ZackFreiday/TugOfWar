import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/countries.dart';
import '../../core/services/profile_service.dart';
import '../../models/profile.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile profile;

  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final ProfileService _profileService =
      ProfileService();

  final ImagePicker _imagePicker =
      ImagePicker();

  late final TextEditingController
      _usernameController;

  late final TextEditingController
      _bioController;

  String? _selectedCountry;

  XFile? _selectedImage;

  String? _currentProfileImageUrl;

  bool _isSaving = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();

    _usernameController =
        TextEditingController(
      text: widget.profile.username,
    );

    _bioController =
        TextEditingController(
      text: widget.profile.bio ?? '',
    );

    final currentCountry =
        widget.profile.country?.trim();

    if (currentCountry != null &&
        currentCountry.isNotEmpty &&
        countries.contains(
          currentCountry,
        )) {
      _selectedCountry =
          currentCountry;
    } else {
      _selectedCountry = null;
    }

    _currentProfileImageUrl =
        widget.profile.profileImageUrl;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();

    super.dispose();
  }

  Future<void> _chooseProfileImage() async {
    if (_isSaving ||
        _isPickingImage) {
      return;
    }

    setState(() {
      _isPickingImage = true;
    });

    try {
      final image =
          await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (!mounted ||
          image == null) {
        return;
      }

      setState(() {
        _selectedImage = image;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _removeProfileImage() async {
    if (_isSaving ||
        _isPickingImage) {
      return;
    }

    // If the user has only selected a new image
    // but has not uploaded it yet, simply discard
    // that local selection.
    if (_selectedImage != null &&
        (_currentProfileImageUrl == null ||
            _currentProfileImageUrl!
                .trim()
                .isEmpty)) {
      setState(() {
        _selectedImage = null;
      });

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedProfile =
          await _profileService
              .deleteProfileImage();

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImage = null;
        _currentProfileImageUrl =
            updatedProfile.profileImageUrl;
      });

      _showMessage(
        'Profile picture removed.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectCountry() async {
    if (_isSaving) {
      return;
    }

    final selected =
        await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        String searchQuery = '';

        return StatefulBuilder(
          builder: (
            context,
            setModalState,
          ) {
            final query =
                searchQuery
                    .trim()
                    .toLowerCase();

            final filteredCountries =
                countries.where(
              (country) {
                return country
                    .toLowerCase()
                    .contains(
                      query,
                    );
              },
            ).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom:
                    MediaQuery.of(context)
                            .viewInsets
                            .bottom +
                        16,
              ),
              child: SizedBox(
                height:
                    MediaQuery.of(context)
                            .size
                            .height *
                        0.75,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Select country',
                            style:
                                Theme.of(context)
                                    .textTheme
                                    .titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            FocusScope.of(context)
                                .unfocus();

                            Navigator.pop(
                              context,
                            );
                          },
                          icon: const Icon(
                            Icons.close,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      autofocus: true,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Search countries',
                        prefixIcon: Icon(
                          Icons.search,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons
                            .remove_circle_outline,
                      ),
                      title: const Text(
                        'Not set',
                      ),
                      selected:
                          _selectedCountry ==
                              null,
                      onTap: () {
                        FocusScope.of(context)
                            .unfocus();

                        Navigator.pop(
                          context,
                          '',
                        );
                      },
                    ),
                    const Divider(),
                    Expanded(
                      child:
                          filteredCountries
                                  .isEmpty
                              ? const Center(
                                  child: Text(
                                    'No countries found.',
                                  ),
                                )
                              : ListView.builder(
                                  itemCount:
                                      filteredCountries
                                          .length,
                                  itemBuilder: (
                                    context,
                                    index,
                                  ) {
                                    final country =
                                        filteredCountries[
                                            index];

                                    return ListTile(
                                      title: Text(
                                        country,
                                      ),
                                      selected:
                                          country ==
                                              _selectedCountry,
                                      trailing:
                                          country ==
                                                  _selectedCountry
                                              ? const Icon(
                                                  Icons
                                                      .check,
                                                )
                                              : null,
                                      onTap: () {
                                        FocusScope.of(
                                          context,
                                        ).unfocus();

                                        Navigator.pop(
                                          context,
                                          country,
                                        );
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted ||
        selected == null) {
      return;
    }

    setState(() {
      _selectedCountry =
          selected.isEmpty
              ? null
              : selected;
    });
  }

  Future<void> _save() async {
    final username =
        _usernameController.text.trim();

    if (username.isEmpty) {
      _showMessage(
        'Username is required.',
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_selectedImage != null) {
        final profileAfterUpload =
            await _profileService
                .uploadProfileImage(
          _selectedImage!,
        );

        _currentProfileImageUrl =
            profileAfterUpload
                .profileImageUrl;
      }

      final updatedProfile =
          await _profileService
              .updateProfile(
        username: username,
        bio: _bioController.text,
        country:
            _selectedCountry ?? '',
        profileImageUrl:
            _currentProfileImageUrl,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        updatedProfile,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),
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
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  Widget _buildProfileImagePreview() {
    if (_selectedImage != null) {
      return FutureBuilder<List<int>>(
        future:
            _selectedImage!
                .readAsBytes(),
        builder: (
          context,
          snapshot,
        ) {
          if (!snapshot.hasData) {
            return const CircleAvatar(
              radius: 50,
              child:
                  CircularProgressIndicator(),
            );
          }

          return CircleAvatar(
            radius: 50,
            backgroundColor:
                Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
            backgroundImage:
                MemoryImage(
              Uint8List.fromList(
                snapshot.data!,
              ),
            ),
          );
        },
      );
    }

    final imageUrl =
        _currentProfileImageUrl;

    if (imageUrl == null ||
        imageUrl.trim().isEmpty) {
      return const CircleAvatar(
        radius: 50,
        child: Icon(
          Icons.person,
          size: 50,
        ),
      );
    }

    return CircleAvatar(
      radius: 50,
      backgroundColor:
          Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,
      child: ClipOval(
        child: Image.network(
          imageUrl,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return const SizedBox(
              width: 100,
              height: 100,
              child: Icon(
                Icons
                    .broken_image_outlined,
                size: 42,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final hasProfileImage =
        _selectedImage != null ||
            (_currentProfileImageUrl
                    ?.trim()
                    .isNotEmpty ??
                false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit profile',
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          20,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 600,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch,
              children: [
                Center(
                  child:
                      _buildProfileImagePreview(),
                ),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed:
                          _isSaving ||
                                  _isPickingImage
                              ? null
                              : _chooseProfileImage,
                      icon:
                          _isPickingImage
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : const Icon(
                                  Icons
                                      .photo_library_outlined,
                                ),
                      label: Text(
                        hasProfileImage
                            ? 'Change picture'
                            : 'Choose picture',
                      ),
                    ),
                    if (hasProfileImage) ...[
                      const SizedBox(
                        width: 10,
                      ),
                      OutlinedButton.icon(
                        onPressed:
                            _isSaving ||
                                    _isPickingImage
                                ? null
                                : _removeProfileImage,
                        icon:
                            const Icon(
                          Icons
                              .delete_outline,
                        ),
                        label:
                            const Text(
                          'Remove',
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(
                  height: 24,
                ),
                TextField(
                  controller:
                      _usernameController,
                  enabled:
                      !_isSaving,
                  maxLength: 30,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Username',
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                TextField(
                  controller:
                      _bioController,
                  enabled:
                      !_isSaving,
                  maxLength: 300,
                  maxLines: 4,
                  decoration:
                      const InputDecoration(
                    labelText: 'Bio',
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                InkWell(
                  onTap:
                      _isSaving
                          ? null
                          : _selectCountry,
                  borderRadius:
                      BorderRadius.circular(
                    4,
                  ),
                  child: InputDecorator(
                    decoration:
                        InputDecoration(
                      labelText:
                          'Country',
                      border:
                          const OutlineInputBorder(),
                      enabled:
                          !_isSaving,
                      suffixIcon:
                          const Icon(
                        Icons
                            .arrow_drop_down,
                      ),
                    ),
                    child: Text(
                      _selectedCountry ??
                          'Not set',
                      style:
                          _selectedCountry ==
                                  null
                              ? TextStyle(
                                  color:
                                      Theme.of(
                                    context,
                                  )
                                          .colorScheme
                                          .onSurfaceVariant,
                                )
                              : null,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                FilledButton(
                  onPressed:
                      _isSaving
                          ? null
                          : _save,
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 14,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Text(
                            'Save changes',
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