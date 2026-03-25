import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  final AppThemeMode themeMode;
  const SettingsScreen({super.key, required this.themeMode});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _use24Hour = false;
  bool _showSeconds = true;
  bool _vibrateAlarm = true;
  bool _alarmSnooze = true;
  int _snoozeDuration = 5;
  String _alarmSound = 'Digital Bell';
  bool _notificationsEnabled = true;
  bool _persistentNotif = false;
  double _alarmVolume = 0.7;
  bool _isLoading = true;

  final List<String> _alarmSounds = [
    'Digital Bell', 'Gentle Chime', 'Radar', 'Sunrise', 'Classic Alarm', 'Beep Beep',
  ];
  final List<int> _snoozeOptions = [1, 3, 5, 10, 15, 20];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _use24Hour = prefs.getBool('use24Hour') ?? false;
      _showSeconds = prefs.getBool('showSeconds') ?? true;
      _vibrateAlarm = prefs.getBool('vibrateAlarm') ?? true;
      _alarmSnooze = prefs.getBool('alarmSnooze') ?? true;
      _snoozeDuration = prefs.getInt('snoozeDuration') ?? 5;
      _alarmSound = prefs.getString('alarmSound') ?? 'Digital Bell';
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _persistentNotif = prefs.getBool('persistentNotif') ?? false;
      _alarmVolume = prefs.getDouble('alarmVolume') ?? 0.7;
      final savedTheme = prefs.getString('theme') ?? 'Dark';
      final themeMode = AppThemeMode.values.firstWhere(
            (t) => t.label == savedTheme,
        orElse: () => AppThemeMode.dark,
      );
      appThemeNotifier.value = themeMode;
      _isLoading = false;
    });
  }

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is int) await prefs.setInt(key, value);
    if (value is String) await prefs.setString(key, value);
    if (value is double) await prefs.setDouble(key, value);
  }

  void _changeTheme(String themeLabel) {
    final themeMode = AppThemeMode.values.firstWhere(
          (t) => t.label == themeLabel,
      orElse: () => AppThemeMode.dark,
    );
    appThemeNotifier.value = themeMode;
    _savePref('theme', themeLabel);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00B4D8))),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  const Text('SETTINGS',
                      style: TextStyle(fontSize: 13, letterSpacing: 4,
                          color: Color(0xFF4A6A90), fontWeight: FontWeight.w600)),
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
                      onChanged: (v) {
                        setState(() => _use24Hour = v);
                        _savePref('use24Hour', v);
                      },
                    ),
                    _divider(),
                    _switchTile(
                      icon: Icons.timer_outlined,
                      title: 'Show Seconds',
                      subtitle: 'Display seconds on clock face',
                      value: _showSeconds,
                      onChanged: (v) {
                        setState(() => _showSeconds = v);
                        _savePref('showSeconds', v);
                      },
                    ),
                  ]),

                  _sectionHeader('ALARM'),
                  _card([
                    _switchTile(
                      icon: Icons.vibration,
                      title: 'Vibration',
                      subtitle: 'Vibrate when alarm rings',
                      value: _vibrateAlarm,
                      onChanged: (v) {
                        setState(() => _vibrateAlarm = v);
                        _savePref('vibrateAlarm', v);
                      },
                    ),
                    _divider(),
                    _switchTile(
                      icon: Icons.snooze,
                      title: 'Snooze',
                      subtitle: 'Allow snoozing alarms',
                      value: _alarmSnooze,
                      onChanged: (v) {
                        setState(() => _alarmSnooze = v);
                        _savePref('alarmSnooze', v);
                      },
                    ),
                    if (_alarmSnooze) ...[
                      _divider(),
                      _pickerTile(
                        icon: Icons.timer_3,
                        title: 'Snooze Duration',
                        value: '$_snoozeDuration min',
                        onTap: () => _showPickerSheet(
                          'Snooze Duration',
                          _snoozeOptions.map((v) => '$v min').toList(),
                          '$_snoozeDuration min',
                              (v) {
                            final val = int.parse(v.replaceAll(' min', ''));
                            setState(() => _snoozeDuration = val);
                            _savePref('snoozeDuration', val);
                          },
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
                            (v) {
                          setState(() => _alarmSound = v);
                          _savePref('alarmSound', v);
                          _previewSound(v);
                        },
                      ),
                    ),
                    _divider(),
                    _sliderTile(
                      icon: Icons.volume_up_outlined,
                      title: 'Alarm Volume',
                      value: _alarmVolume,
                      onChanged: (v) {
                        setState(() => _alarmVolume = v);
                        _savePref('alarmVolume', v);
                      },
                    ),
                  ]),

                  _sectionHeader('NOTIFICATIONS'),
                  _card([
                    _switchTile(
                      icon: Icons.notifications_outlined,
                      title: 'Enable Notifications',
                      subtitle: 'Receive event reminders',
                      value: _notificationsEnabled,
                      onChanged: (v) {
                        setState(() => _notificationsEnabled = v);
                        _savePref('notificationsEnabled', v);
                      },
                    ),
                    _divider(),
                    _switchTile(
                      icon: Icons.push_pin_outlined,
                      title: 'Persistent Notifications',
                      subtitle: 'Keep reminders visible until dismissed',
                      value: _persistentNotif,
                      onChanged: _notificationsEnabled
                          ? (v) {
                        setState(() => _persistentNotif = v);
                        _savePref('persistentNotif', v);
                      }
                          : null,
                    ),
                  ]),

                  _sectionHeader('APPEARANCE'),
                  _card([
                    _pickerTile(
                      icon: Icons.palette_outlined,
                      title: 'Theme',
                      value: appThemeNotifier.value.label,
                      onTap: () => _showPickerSheet(
                        'Theme',
                        AppThemeMode.values.map((t) => t.label).toList(),
                        appThemeNotifier.value.label,
                        _changeTheme,
                      ),
                    ),
                  ]),

                  // Theme preview
                  const SizedBox(height: 8),
                  _themePreviewCard(),

                  _sectionHeader('ABOUT'),
                  _card([
                    _infoTile(Icons.info_outline, 'Version', '1.0.0'),
                    _divider(),
                    _infoTile(Icons.code, 'Build', 'Flutter · Dart'),
                    _divider(),
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: const Icon(Icons.star_outline,
                          color: Color(0xFF00B4D8), size: 20),
                      title: const Text('Rate the App',
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                      trailing: const Icon(Icons.chevron_right,
                          color: Color(0xFF4A6A90), size: 18),
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

  // Shows a snackbar preview when sound is selected
  void _previewSound(String sound) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0D1526),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.music_note, color: Color(0xFF00B4D8), size: 18),
            const SizedBox(width: 10),
            Text('Playing: $sound',
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
    // To actually play sound, add audioplayers package:
    // final player = AudioPlayer();
    // await player.play(AssetSource('sounds/${sound.toLowerCase().replaceAll(' ', '_')}.mp3'));
  }

  Widget _themePreviewCard() {
    final theme = appThemeNotifier.value;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PREVIEW — ${theme.label.toUpperCase()}',
              style: const TextStyle(fontSize: 9, color: Color(0xFF4A6A90),
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(width: 32, height: 32,
                  decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.primary.withOpacity(0.5))),
                  child: Icon(Icons.alarm, color: theme.primary, size: 16)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sample Alarm', style: const TextStyle(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Theme preview', style: TextStyle(
                      color: theme.primary, fontSize: 11)),
                ],
              )),
              Switch(value: true, onChanged: null,
                  activeColor: theme.primary,
                  activeTrackColor: theme.primary.withOpacity(0.3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 20, bottom: 8),
      child: Text(title,
          style: const TextStyle(fontSize: 9, color: Color(0xFF4A6A90),
              letterSpacing: 2, fontWeight: FontWeight.w700)),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1526),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(
      height: 1, color: Color(0xFF1E3A5F), indent: 52, endIndent: 0);

  Widget _switchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: const Color(0xFF00B4D8), size: 20),
      title: Text(title, style: TextStyle(
          color: onChanged != null ? Colors.white : const Color(0xFF4A6A90),
          fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(
          color: Color(0xFF4A6A90), fontSize: 11))
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF00B4D8),
        activeTrackColor: const Color(0xFF00B4D8).withOpacity(0.3),
        inactiveThumbColor: const Color(0xFF4A6A90),
        inactiveTrackColor: const Color(0xFF1E3A5F),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: const Color(0xFF00B4D8), size: 20),
      title: Text(title, style: const TextStyle(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: Color(0xFF4A6A90), fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Color(0xFF4A6A90), size: 18),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00B4D8), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    Text('${(value * 100).round()}%',
                        style: const TextStyle(color: Color(0xFF4A6A90), fontSize: 12)),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: const Color(0xFF00B4D8),
                    inactiveTrackColor: const Color(0xFF1E3A5F),
                    thumbColor: const Color(0xFF00B4D8),
                    overlayColor: const Color(0xFF00B4D8).withOpacity(0.2),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(value: value, onChanged: onChanged),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: const Color(0xFF00B4D8), size: 20),
      title: Text(title, style: const TextStyle(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Text(value, style: const TextStyle(
          color: Color(0xFF4A6A90), fontSize: 13)),
    );
  }

  void _showPickerSheet(
      String title, List<String> options, String current, ValueChanged<String> onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1526),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF1E3A5F))),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 16),
            ...options.map((opt) => ListTile(
              title: Text(opt, style: const TextStyle(color: Colors.white)),
              trailing: opt == current
                  ? const Icon(Icons.check, color: Color(0xFF00B4D8), size: 20)
                  : null,
              onTap: () {
                onSelect(opt);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}