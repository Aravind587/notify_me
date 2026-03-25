// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/clock_screen.dart';
import 'screens/alarm_screen.dart';
import 'screens/stopwatch_screen.dart';
import 'screens/world_clock_screen.dart';
import 'screens/events_screen.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';

void main() async {
  // Required before any async work in main().
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification plugin once at startup.
  await NotificationService.init();

  runApp(const ClockApp());
}

// Global notifier for theme
final ValueNotifier<AppThemeMode> appThemeNotifier =
ValueNotifier(AppThemeMode.dark);

enum AppThemeMode { dark, darker, midnight, ocean }

extension AppThemeModeExt on AppThemeMode {
  String get label {
    switch (this) {
      case AppThemeMode.dark:     return 'Dark';
      case AppThemeMode.darker:   return 'Darker';
      case AppThemeMode.midnight: return 'Midnight';
      case AppThemeMode.ocean:    return 'Ocean';
    }
  }

  Color get background {
    switch (this) {
      case AppThemeMode.dark:     return const Color(0xFF080D18);
      case AppThemeMode.darker:   return const Color(0xFF06060C);
      case AppThemeMode.midnight: return const Color(0xFF0A0A1E);
      case AppThemeMode.ocean:    return const Color(0xFF010F1E);
    }
  }

  Color get surface {
    switch (this) {
      case AppThemeMode.dark:     return const Color(0xFF0C1422);
      case AppThemeMode.darker:   return const Color(0xFF09090F);
      case AppThemeMode.midnight: return const Color(0xFF0F0F28);
      case AppThemeMode.ocean:    return const Color(0xFF031827);
    }
  }

  Color get card {
    switch (this) {
      case AppThemeMode.dark:     return const Color(0xFF111C30);
      case AppThemeMode.darker:   return const Color(0xFF0E0E1A);
      case AppThemeMode.midnight: return const Color(0xFF161638);
      case AppThemeMode.ocean:    return const Color(0xFF062033);
    }
  }

  Color get border {
    switch (this) {
      case AppThemeMode.dark:     return const Color(0xFF1E3A6B);
      case AppThemeMode.darker:   return const Color(0xFF1D1640);
      case AppThemeMode.midnight: return const Color(0xFF2D1B69);
      case AppThemeMode.ocean:    return const Color(0xFF0A3D5C);
    }
  }

  Color get primary {
    switch (this) {
      case AppThemeMode.dark:     return const Color(0xFF38BDF8);
      case AppThemeMode.darker:   return const Color(0xFF9B87F5);
      case AppThemeMode.midnight: return const Color(0xFFC084FC);
      case AppThemeMode.ocean:    return const Color(0xFF00E5FF);
    }
  }

  Color get accent {
    switch (this) {
      case AppThemeMode.dark:     return const Color(0xFF34D399);
      case AppThemeMode.darker:   return const Color(0xFF60A5FA);
      case AppThemeMode.midnight: return const Color(0xFF34D399);
      case AppThemeMode.ocean:    return const Color(0xFFF59E0B);
    }
  }

  Color get navBar {
    switch (this) {
      case AppThemeMode.dark:     return const Color(0xFF0D1E3D);
      case AppThemeMode.darker:   return const Color(0xFF07070E);
      case AppThemeMode.midnight: return const Color(0xFF0C0C22);
      case AppThemeMode.ocean:    return const Color(0xFF011424);
    }
  }

  Color get textPrimary {
    switch (this) {
      case AppThemeMode.dark:     return const Color(0xFFE2EBF6);
      case AppThemeMode.darker:   return const Color(0xFFD4D0F0);
      case AppThemeMode.midnight: return const Color(0xFFE0D9FF);
      case AppThemeMode.ocean:    return const Color(0xFFCAEEFF);
    }
  }

  Color get textMuted {
    switch (this) {
      case AppThemeMode.dark:     return const Color(0xFF4A7BAD);
      case AppThemeMode.darker:   return const Color(0xFF6655AA);
      case AppThemeMode.midnight: return const Color(0xFF6644AA);
      case AppThemeMode.ocean:    return const Color(0xFF2A7A96);
    }
  }
}

class ClockApp extends StatelessWidget {
  const ClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: appThemeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'notify_me',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: themeMode.background,
            colorScheme: ColorScheme.dark(
              primary: themeMode.primary,
              secondary: const Color(0xFF00FFB3),
              surface: themeMode.surface,
            ),
          ),
          home: MainShell(themeMode: themeMode),
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  final AppThemeMode themeMode;
  const MainShell({super.key, required this.themeMode});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    const ClockScreen(),
    const AlarmScreen(),
    const StopwatchScreen(),
    const WorldClockScreen(),
    const EventsScreen(),
    SettingsScreen(themeMode: widget.themeMode),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.watch_outlined,    activeIcon: Icons.watch,    label: 'Clock'),
    _NavItem(icon: Icons.alarm_outlined,    activeIcon: Icons.alarm,    label: 'Alarm'),
    _NavItem(icon: Icons.timer_outlined,    activeIcon: Icons.timer,    label: 'Stopwatch'),
    _NavItem(icon: Icons.language_outlined, activeIcon: Icons.language, label: 'World'),
    _NavItem(icon: Icons.event_outlined,    activeIcon: Icons.event,    label: 'Events'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeMode;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.navBar,
          border: Border(top: BorderSide(color: theme.border, width: 1)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final isActive = _currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          size: 22,
                          color: isActive ? theme.primary : const Color(0xFF4A6A90),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 0.5,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                            color: isActive ? theme.primary : const Color(0xFF4A6A90),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}