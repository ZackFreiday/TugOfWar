import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/profile.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService =
      AuthService();

  final ProfileService _profileService =
      ProfileService();

  final NotificationService
      _notificationService =
      NotificationService();

  StreamSubscription<void>?
      _sessionExpiredSubscription;

  Profile? _profile;

  bool _isInitializing = true;
  bool _isLoadingProfile = false;
  bool _isAuthenticating = false;
  bool _isLoadingUnreadNotifications =
      false;

  int _unreadNotificationCount = 0;

  AppState() {
    _sessionExpiredSubscription =
        AuthService
            .sessionExpiredStream
            .listen(
      (_) {
        _handleSessionExpired();
      },
    );
  }

  Profile? get profile =>
      _profile;

  bool get isInitializing =>
      _isInitializing;

  bool get isLoadingProfile =>
      _isLoadingProfile;

  bool get isAuthenticating =>
      _isAuthenticating;

  bool get isLoggedIn =>
      _profile != null;

  bool get isLoadingUnreadNotifications =>
      _isLoadingUnreadNotifications;

  String get username =>
      _profile?.username ?? '';

  int get coinBalance =>
      _profile?.coinBalance ?? 0;

  bool get isAdmin =>
      _profile?.isAdmin ?? false;

  int get unreadNotificationCount =>
      _unreadNotificationCount;

  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    final token =
        await _authService.getToken();

    if (token == null ||
        token.isEmpty) {
      _profile = null;
      _unreadNotificationCount = 0;
      _isInitializing = false;

      notifyListeners();

      return;
    }

    try {
      _profile =
          await _profileService
              .getProfile();

      await _loadUnreadNotificationCountInternal();
    } on SessionExpiredException {
      await _clearSessionState();
    } catch (_) {
      await _authService.logout();

      _profile = null;
      _unreadNotificationCount = 0;
    }

    _isInitializing = false;

    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _isAuthenticating = true;
    notifyListeners();

    try {
      await _authService.login(
        email: email,
        password: password,
      );

      _profile =
          await _profileService
              .getProfile();

      await _loadUnreadNotificationCountInternal();
    } finally {
      _isAuthenticating = false;

      notifyListeners();
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _isAuthenticating = true;
    notifyListeners();

    try {
      await _authService.register(
        username: username,
        email: email,
        password: password,
      );

      _profile =
          await _profileService
              .getProfile();

      await _loadUnreadNotificationCountInternal();
    } finally {
      _isAuthenticating = false;

      notifyListeners();
    }
  }

  Future<void> loadProfile() async {
    _isLoadingProfile = true;
    notifyListeners();

    try {
      _profile =
          await _profileService
              .getProfile();
    } on SessionExpiredException {
      await _clearSessionState();

      rethrow;
    } finally {
      _isLoadingProfile = false;

      notifyListeners();
    }
  }

  Future<void>
      loadUnreadNotificationCount()
      async {
    if (_profile == null) {
      _unreadNotificationCount = 0;

      notifyListeners();

      return;
    }

    if (_isLoadingUnreadNotifications) {
      return;
    }

    _isLoadingUnreadNotifications =
        true;

    try {
      _unreadNotificationCount =
          await _notificationService
              .getUnreadCount();
    } on SessionExpiredException {
      await _clearSessionState();

      rethrow;
    } finally {
      _isLoadingUnreadNotifications =
          false;

      notifyListeners();
    }
  }

  Future<void>
      _loadUnreadNotificationCountInternal()
      async {
    try {
      _unreadNotificationCount =
          await _notificationService
              .getUnreadCount();
    } on SessionExpiredException {
      await _clearSessionState();

      rethrow;
    } catch (_) {
      _unreadNotificationCount = 0;
    }
  }

  Future<Profile> updateProfile({
    required String username,
    required String? bio,
    required String? country,
    required String? profileImageUrl,
  }) async {
    _isLoadingProfile = true;
    notifyListeners();

    try {
      final updatedProfile =
          await _profileService
              .updateProfile(
        username: username,
        bio: bio,
        country: country,
        profileImageUrl:
            profileImageUrl,
      );

      _profile = updatedProfile;

      return updatedProfile;
    } on SessionExpiredException {
      await _clearSessionState();

      rethrow;
    } finally {
      _isLoadingProfile = false;

      notifyListeners();
    }
  }

  Future<void>
      _handleSessionExpired()
      async {
    await _clearSessionState();
  }

  Future<void>
      _clearSessionState()
      async {
    _profile = null;
    _unreadNotificationCount = 0;

    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();

    _profile = null;
    _unreadNotificationCount = 0;

    notifyListeners();
  }

  @override
  void dispose() {
    _sessionExpiredSubscription
        ?.cancel();

    super.dispose();
  }
}