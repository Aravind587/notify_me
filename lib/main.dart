import 'package:flutter/material.dart';
import 'screens/clock_screen.dart';
import 'screens/alarm_screen.dart';
import 'screens/stopwatch_screen.dart';
import 'screens/world_clock_screen.dart';
import 'screens/events_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const ClockApp());
}

class ClockApp extends StatelessWidget {
  const ClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clock App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00B4D8),
          secondary: Color(0xFF00FFB3),
          surface: Color(0xFF111827),
        ),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ClockScreen(),
    AlarmScreen(),
    StopwatchScreen(),
    WorldClockScreen(),
    EventsScreen(),
    SettingsScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.watch_outlined, activeIcon: Icons.watch, label: 'Clock'),
    _NavItem(icon: Icons.alarm_outlined, activeIcon: Icons.alarm, label: 'Alarm'),
    _NavItem(icon: Icons.timer_outlined, activeIcon: Icons.timer, label: 'Stopwatch'),
    _NavItem(icon: Icons.language_outlined, activeIcon: Icons.language, label: 'World'),
    _NavItem(icon: Icons.event_outlined, activeIcon: Icons.event, label: 'Events'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1526),
          border: Border(top: BorderSide(color: Color(0xFF1E3A5F), width: 1)),
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
                          color: isActive ? const Color(0xFF00B4D8) : const Color(0xFF4A6A90),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 0.5,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                            color: isActive ? const Color(0xFF00B4D8) : const Color(0xFF4A6A90),
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
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}