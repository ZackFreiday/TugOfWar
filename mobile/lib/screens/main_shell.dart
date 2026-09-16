import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/state/app_state.dart';
import 'admin/admin_faceoffs_screen.dart';
import 'home/home_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
  });

  @override
  State<MainShell> createState() =>
      _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const Color _purple =
      Color(0xFF6C4DFF);

  int _selectedIndex = 0;

  int _homeRefreshVersion = 0;
  int _profileRefreshVersion = 0;

  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context
          .read<AppState>()
          .loadUnreadNotificationCount();
    });

    _notificationTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        if (!mounted) {
          return;
        }

        context
            .read<AppState>()
            .loadUnreadNotificationCount();
      },
    );
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();

    super.dispose();
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const NotificationsScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await context
        .read<AppState>()
        .loadUnreadNotificationCount();
  }

  void _openProfile() {
    if (_selectedIndex == 1) {
      return;
    }

    setState(() {
      _profileRefreshVersion++;
      _selectedIndex = 1;
    });

    context
        .read<AppState>()
        .loadProfile();

    context
        .read<AppState>()
        .loadUnreadNotificationCount();
  }

  Future<void> _confirmLogout() async {
    final shouldLogout =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.logout_rounded,
            color: _purple,
          ),
          title: const Text(
            'Log out?',
          ),
          content: const Text(
            'You will need to log in again to access your account.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Log out',
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true ||
        !mounted) {
      return;
    }

    await context
        .read<AppState>()
        .logout();
  }

  Widget _buildNotificationButton(
    AppState appState,
  ) {
    final unreadCount =
        appState.unreadNotificationCount;

    return IconButton(
      onPressed: _openNotifications,
      tooltip: 'Notifications',
      icon: Badge(
        isLabelVisible:
            unreadCount > 0,
        label: Text(
          unreadCount > 99
              ? '99+'
              : '$unreadCount',
        ),
        child: const Icon(
          Icons.notifications_outlined,
        ),
      ),
    );
  }

  Widget _buildAccountAvatar(
    AppState appState,
  ) {
    final profileImageUrl =
        appState.profile
            ?.profileImageUrl
            ?.trim();

    if (profileImageUrl == null ||
        profileImageUrl.isEmpty) {
      return const CircleAvatar(
        radius: 16,
        backgroundColor:
            Color(0xFFEDE9FF),
        child: Icon(
          Icons.person,
          size: 20,
          color: _purple,
        ),
      );
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor:
          const Color(0xFFEDE9FF),
      child: ClipOval(
        child: Image.network(
          profileImageUrl,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return const SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                Icons.person,
                size: 20,
                color: _purple,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccountMenu(
    AppState appState,
  ) {
    return PopupMenuButton<String>(
      tooltip: 'Account',
      position:
          PopupMenuPosition.under,
      offset: const Offset(
        0,
        6,
      ),
      onSelected: (value) {
        if (value == 'profile') {
          _openProfile();
          return;
        }

        if (value == 'logout') {
          _confirmLogout();
        }
      },
      itemBuilder: (context) {
        return const [
          PopupMenuItem<String>(
            value: 'profile',
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                ),
                SizedBox(
                  width: 12,
                ),
                Text(
                  'Profile',
                ),
              ],
            ),
          ),
          PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Color(
                    0xFFD93B4B,
                  ),
                ),
                SizedBox(
                  width: 12,
                ),
                Text(
                  'Log out',
                  style: TextStyle(
                    color: Color(
                      0xFFD93B4B,
                    ),
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ];
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        child: _buildAccountAvatar(
          appState,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState =
        context.watch<AppState>();

    final isAdmin =
        appState.isAdmin;

    final pages = <Widget>[
      HomeScreen(
        key: ValueKey(
          _homeRefreshVersion,
        ),
        showAppBar: false,
      ),
      ProfileScreen(
        key: ValueKey(
          _profileRefreshVersion,
        ),
        showAppBar: false,
      ),
      if (isAdmin)
        const AdminFaceOffsScreen(),
    ];

    final destinations =
        <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(
          Icons.home_outlined,
        ),
        selectedIcon: Icon(
          Icons.home,
        ),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(
          Icons.person_outline,
        ),
        selectedIcon: Icon(
          Icons.person,
        ),
        label: 'Profile',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(
            Icons
                .admin_panel_settings_outlined,
          ),
          selectedIcon: Icon(
            Icons.admin_panel_settings,
          ),
          label: 'Admin',
        ),
    ];

    final titles = <String>[
      'TugVote',
      'Profile',
      if (isAdmin) 'Admin',
    ];

    final safeSelectedIndex =
        _selectedIndex < pages.length
            ? _selectedIndex
            : 0;

    if (safeSelectedIndex !=
        _selectedIndex) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[
              safeSelectedIndex],
        ),
        actions: [
          if (safeSelectedIndex == 0)
            Padding(
              padding:
                  const EdgeInsets.only(
                right: 2,
              ),
              child: Center(
                child: Row(
                  children: [
                    const Icon(
                      Icons
                          .monetization_on_outlined,
                      size: 21,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                      '${appState.coinBalance}',
                    ),
                  ],
                ),
              ),
            ),

          _buildNotificationButton(
            appState,
          ),

          _buildAccountMenu(
            appState,
          ),

          const SizedBox(
            width: 4,
          ),
        ],
      ),

      body: IndexedStack(
        index:
            safeSelectedIndex,
        children: pages,
      ),

      bottomNavigationBar:
          NavigationBar(
        selectedIndex:
            safeSelectedIndex,
        onDestinationSelected:
            (index) {
          setState(() {
            if (index == 0 &&
                _selectedIndex != 0) {
              _homeRefreshVersion++;
            }

            if (index == 1 &&
                _selectedIndex != 1) {
              _profileRefreshVersion++;
            }

            _selectedIndex = index;
          });

          if (index == 1) {
            context
                .read<AppState>()
                .loadProfile();
          }

          context
              .read<AppState>()
              .loadUnreadNotificationCount();
        },
        destinations:
            destinations,
      ),
    );
  }
}