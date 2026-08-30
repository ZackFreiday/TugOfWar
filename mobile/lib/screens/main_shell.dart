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
      'TugOfWar',
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
                right: 4,
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
          _buildNotificationButton(
            appState,
          ),
          const SizedBox(
            width: 8,
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