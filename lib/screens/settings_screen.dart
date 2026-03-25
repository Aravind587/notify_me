import 'package:flutter/material.dart';
import '../main.dart'; // IMPORTANT for AppThemeMode + appThemeNotifier

class SettingsScreen extends StatefulWidget {
  final AppThemeMode themeMode;

  const SettingsScreen({super.key, required this.themeMode});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppThemeMode get theme => widget.themeMode;

  bool _use24Hour = false;
  bool _showSeconds = true;
  bool _vibrateAlarm = true;
  bool _alarmSnooze = true;
  int _snoozeDuration = 5;
  String _alarmSound = 'Digital Bell';
  String _theme = 'Dark';
  bool _notificationsEnabled = true;
  bool _persistentNotif = false;
  double _alarmVolume = 0.7;

  final List<String> _alarmSounds = [
    'Digital Bell',
    'Gentle Chime',
    'Radar',
    'Sunrise',
    'Classic Alarm',
    'Beep Beep',
  ];

  final List<int> _snoozeOptions = [1, 3, 5, 10, 15, 20];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Text(
                    'SETTINGS',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 4,
                      color: theme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _sectionHeader('CLOCK'),
                  _card([
                    _switchTile(
                      icon: Icons.access_time,
                      title: '24-Hour Format',
                      subtitle: 'Show time in 24h format',
                      value: _use24Hour,
                      onChanged: (v) =>
                          setState(() => _use24Hour = v),
                    ),
                    _divider(),
                    _switchTile(
                      icon: Icons.timer_outlined,
                      title: 'Show Seconds',
                      subtitle: 'Display seconds on clock face',
                      value: _showSeconds,
                      onChanged: (v) =>
                          setState(() => _showSeconds = v),
                    ),
                  ]),

                  _sectionHeader('ALARM'),
                  _card([
                    _switchTile(
                      icon: Icons.vibration,
                      title: 'Vibration',
                      subtitle: 'Vibrate when alarm rings',
                      value: _vibrateAlarm,
                      onChanged: (v) =>
                          setState(() => _vibrateAlarm = v),
                    ),
                    _divider(),
                    _switchTile(
                      icon: Icons.snooze,
                      title: 'Snooze',
                      subtitle: 'Allow snoozing alarms',
                      value: _alarmSnooze,
                      onChanged: (v) =>
                          setState(() => _alarmSnooze = v),
                    ),
                    if (_alarmSnooze) ...[
                      _divider(),
                      _pickerTile(
                        icon: Icons.timer_3,
                        title: 'Snooze Duration',
                        value: '$_snoozeDuration min',
                        onTap: () => _showPickerSheet(
                          'Snooze Duration',
                          _snoozeOptions
                              .map((v) => '$v min')
                              .toList(),
                          '$_snoozeDuration min',
                              (v) => setState(() =>
                          _snoozeDuration = int.parse(
                              v.replaceAll(' min', ''))),
                        ),
                      ),
                    ],
                    _divider(),
                    _pickerTile(
                      icon: Icons.music_note_outlined,
                      title: 'Default Sound',
                      value: _alarmSound,
                      onTap: () => _showPickerSheet(
                        'Alarm Sound',
                        _alarmSounds,
                        _alarmSound,
                            (v) => setState(() => _alarmSound = v),
                      ),
                    ),
                    _divider(),
                    _sliderTile(
                      icon: Icons.volume_up_outlined,
                      title: 'Alarm Volume',
                      value: _alarmVolume,
                      onChanged: (v) =>
                          setState(() => _alarmVolume = v),
                    ),
                  ]),

                  _sectionHeader('NOTIFICATIONS'),
                  _card([
                    _switchTile(
                      icon: Icons.notifications_outlined,
                      title: 'Enable Notifications',
                      subtitle: 'Receive event reminders',
                      value: _notificationsEnabled,
                      onChanged: (v) =>
                          setState(() => _notificationsEnabled = v),
                    ),
                    _divider(),
                    _switchTile(
                      icon: Icons.push_pin_outlined,
                      title: 'Persistent Notifications',
                      subtitle:
                      'Keep reminders visible until dismissed',
                      value: _persistentNotif,
                      onChanged: _notificationsEnabled
                          ? (v) => setState(
                              () => _persistentNotif = v)
                          : null,
                    ),
                  ]),

                  _sectionHeader('APPEARANCE'),
                  _card([
                    _pickerTile(
                      icon: Icons.palette_outlined,
                      title: 'Theme',
                      value: _theme,
                      onTap: () => _showPickerSheet(
                        'Theme',
                        ['Dark', 'Darker', 'Midnight', 'Ocean'],
                        _theme,
                            (v) {
                          setState(() => _theme = v);

                          final selected =
                          AppThemeMode.values.firstWhere(
                                (e) => e.label == v,
                          );

                          appThemeNotifier.value = selected;
                        },
                      ),
                    ),
                  ]),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding:
      const EdgeInsets.only(left: 4, top: 20, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 9,
          color: theme.textMuted,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    color: theme.border,
    indent: 52,
  );

  Widget _switchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: theme.primary),
      title: Text(
        title,
        style: TextStyle(
          color: onChanged != null
              ? theme.textPrimary
              : theme.textMuted,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle,
          style: TextStyle(color: theme.textMuted))
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: theme.primary,
      ),
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: theme.primary),
      title: Text(title,
          style: TextStyle(color: theme.textPrimary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(color: theme.textMuted)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right,
              color: theme.textMuted),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _sliderTile({
    required IconData icon,
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: theme.primary),
        Expanded(
          child: Slider(
            value: value,
            onChanged: onChanged,
            activeColor: theme.primary,
          ),
        ),
      ],
    );
  }

  void _showPickerSheet(
      String title,
      List<String> options,
      String current,
      ValueChanged<String> onSelect,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: options
            .map((opt) => ListTile(
          title: Text(opt,
              style: TextStyle(
                  color: theme.textPrimary)),
          onTap: () {
            onSelect(opt);
            Navigator.pop(context);
          },
        ))
            .toList(),
      ),
    );
  }
}