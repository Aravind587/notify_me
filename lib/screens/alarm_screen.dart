// lib/screens/alarm_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/alarm_storage_service.dart';
import '../services/alarm_service.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class AlarmModel {
  final String id;
  String label;
  int hour;
  int minute;
  bool isEnabled;
  List<bool> repeatDays; // Mon–Sun (index 0–6)
  String sound;

  AlarmModel({
    required this.id,
    required this.label,
    required this.hour,
    required this.minute,
    this.isEnabled = true,
    List<bool>? repeatDays,
    this.sound = 'Default',
  }) : repeatDays = repeatDays ?? List.filled(7, false);

  String get timeString {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  String get repeatString {
    const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final active = <String>[];
    for (int i = 0; i < 7; i++) {
      if (repeatDays[i]) active.add(days[i]);
    }
    if (active.isEmpty) return 'Once';
    if (active.length == 7) return 'Every day';
    if (active.length == 5 && !repeatDays[5] && !repeatDays[6]) {
      return 'Weekdays';
    }
    return active.join(', ');
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  List<AlarmModel> _alarms = [];
  bool _loading = true;
  StreamSubscription<AlarmModel>? _firingSub;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
    // Listen for alarms fired by AlarmService and show ringing overlay
    _firingSub = AlarmService.instance.firingStream.listen((alarm) {
      if (!mounted) return;
      _showRingingOverlay(alarm);
    });
  }

  @override
  void dispose() {
    _firingSub?.cancel();
    super.dispose();
  }

  Future<void> _loadAlarms() async {
    final alarms = await AlarmStorageService.loadAlarms();
    setState(() {
      _alarms = alarms;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await AlarmStorageService.saveAlarms(_alarms);
  }

  Future<void> _addOrUpdateAlarm(AlarmModel alarm) async {
    setState(() {
      final idx = _alarms.indexWhere((a) => a.id == alarm.id);
      if (idx >= 0) {
        _alarms[idx] = alarm;
      } else {
        _alarms.add(alarm);
      }
    });
    await _persist();
  }

  Future<void> _toggleAlarm(int index, bool enabled) async {
    setState(() => _alarms[index].isEnabled = enabled);
    await _persist();
  }

  Future<void> _deleteAlarm(String id) async {
    setState(() => _alarms.removeWhere((a) => a.id == id));
    await _persist();
  }

  void _showRingingOverlay(AlarmModel alarm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) => _RingingOverlay(alarm: alarm),
    );
  }

  void _showAddAlarm({AlarmModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AlarmEditSheet(
        alarm: existing,
        onSave: _addOrUpdateAlarm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ALARM',
                      style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 4,
                          color: Color(0xFF4A6A90),
                          fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: () => _showAddAlarm(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B4D8).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                            const Color(0xFF00B4D8).withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.add,
                          color: Color(0xFF00B4D8), size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF00B4D8)))
                  : _alarms.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.alarm_off,
                        size: 56, color: Color(0xFF1E3A5F)),
                    SizedBox(height: 16),
                    Text('No alarms set',
                        style: TextStyle(
                            color: Color(0xFF4A6A90),
                            fontSize: 16)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
                itemCount: _alarms.length,
                itemBuilder: (_, i) => _AlarmTile(
                  alarm: _alarms[i],
                  onToggle: (v) => _toggleAlarm(i, v),
                  onTap: () =>
                      _showAddAlarm(existing: _alarms[i]),
                  onDelete: () =>
                      _deleteAlarm(_alarms[i].id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ringing Overlay ──────────────────────────────────────────────────────────

class _RingingOverlay extends StatefulWidget {
  final AlarmModel alarm;
  const _RingingOverlay({required this.alarm});

  @override
  State<_RingingOverlay> createState() => _RingingOverlayState();
}

class _RingingOverlayState extends State<_RingingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alarm = widget.alarm;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1526),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: const Color(0xFF00B4D8).withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(
                    const Color(0xFF00B4D8).withOpacity(0.2),
                    const Color(0xFF00B4D8).withOpacity(0.05),
                    _pulse.value,
                  ),
                  border: Border.all(
                    color: Color.lerp(
                      const Color(0xFF00B4D8),
                      const Color(0xFF00B4D8).withOpacity(0.3),
                      _pulse.value,
                    )!,
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.alarm,
                    color: Color(0xFF00B4D8), size: 36),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              alarm.timeString,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              alarm.label,
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF00B4D8),
                  fontWeight: FontWeight.w500),
            ),
            if (alarm.repeatString != 'Once') ...[
              const SizedBox(height: 4),
              Text(alarm.repeatString,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF4A6A90))),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await AlarmService.instance.stopSound();
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B4D8),
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('STOP',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await AlarmService.instance.snooze();
                  if (context.mounted) Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4A6A90),
                  side:
                  const BorderSide(color: Color(0xFF1E3A5F)),
                  padding:
                  const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('SNOOZE 5 MIN',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Alarm Tile ───────────────────────────────────────────────────────────────

class _AlarmTile extends StatelessWidget {
  final AlarmModel alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AlarmTile({
    required this.alarm,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(alarm.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4757).withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline,
            color: Color(0xFFFF4757)),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1526),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: alarm.isEnabled
                  ? const Color(0xFF00B4D8).withOpacity(0.3)
                  : const Color(0xFF1E3A5F),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm.timeString,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: alarm.isEnabled
                            ? Colors.white
                            : const Color(0xFF4A6A90),
                        fontFeatures: const [
                          FontFeature.tabularFigures()
                        ],
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          alarm.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: alarm.isEnabled
                                ? const Color(0xFF00B4D8)
                                : const Color(0xFF2A4A6A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${alarm.repeatString}',
                          style: TextStyle(
                            fontSize: 12,
                            color: alarm.isEnabled
                                ? const Color(0xFF4A6A90)
                                : const Color(0xFF2A4A6A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: alarm.isEnabled,
                onChanged: onToggle,
                activeColor: const Color(0xFF00B4D8),
                activeTrackColor:
                const Color(0xFF00B4D8).withOpacity(0.3),
                inactiveThumbColor: const Color(0xFF4A6A90),
                inactiveTrackColor: const Color(0xFF1E3A5F),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Edit Sheet ───────────────────────────────────────────────────────────────

class _AlarmEditSheet extends StatefulWidget {
  final AlarmModel? alarm;
  final ValueChanged<AlarmModel> onSave;

  const _AlarmEditSheet({this.alarm, required this.onSave});

  @override
  State<_AlarmEditSheet> createState() => _AlarmEditSheetState();
}

class _AlarmEditSheetState extends State<_AlarmEditSheet> {
  late int _hour;
  late int _minute;
  late String _label;
  late List<bool> _repeatDays;
  late String _sound;
  late TextEditingController _labelCtrl;

  // ─────────────────────────────────────────────────────────────────────────
  // SOUND LIST — labels here MUST exactly match the keys in
  // AlarmService._fire() soundMap. If you add a new file to assets/sounds/
  // you must add it in BOTH places with the same label string.
  // ─────────────────────────────────────────────────────────────────────────
  final List<String> _sounds = const [
    'Default',             // → assets/sounds/alarm_default.mp3
    'Morning Walkup Call', // → assets/sounds/morning_walkup_call.mp3
    'Warning Alert',       // → assets/sounds/warning_alert.mp3
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.alarm;
    _hour       = a?.hour ?? 7;
    _minute     = a?.minute ?? 0;
    _label      = a?.label ?? 'Alarm';
    _repeatDays = List.from(a?.repeatDays ?? List.filled(7, false));
    _sound      = a?.sound ?? 'Default';
    _labelCtrl  = TextEditingController(text: _label);
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme:
          const ColorScheme.dark(primary: Color(0xFF00B4D8)),
        ),
        child: child!,
      ),
    );
    if (t != null) {
      setState(() {
        _hour   = t.hour;
        _minute = t.minute;
      });
    }
  }

  void _showSoundPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1526),
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          ..._sounds.map(
                (s) => ListTile(
              leading: Icon(
                Icons.music_note,
                color: s == _sound
                    ? const Color(0xFF00B4D8)
                    : const Color(0xFF4A6A90),
                size: 18,
              ),
              title: Text(
                s,
                style: TextStyle(
                  color: s == _sound
                      ? const Color(0xFF00B4D8)
                      : Colors.white,
                  fontWeight: s == _sound
                      ? FontWeight.w700
                      : FontWeight.normal,
                ),
              ),
              trailing: s == _sound
                  ? const Icon(Icons.check,
                  color: Color(0xFF00B4D8), size: 18)
                  : null,
              onTap: () {
                setState(() => _sound = s);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final alarm = AlarmModel(
      id: widget.alarm?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      label:      _labelCtrl.text.isEmpty ? 'Alarm' : _labelCtrl.text,
      hour:       _hour,
      minute:     _minute,
      repeatDays: _repeatDays,
      sound:      _sound,
      isEnabled:  true,
    );
    widget.onSave(alarm);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final h    = _hour > 12 ? _hour - 12 : (_hour == 0 ? 12 : _hour);
    final m    = _minute.toString().padLeft(2, '0');
    final ampm = _hour >= 12 ? 'PM' : 'AM';
    const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1526),
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF1E3A5F))),
      ),
      padding: EdgeInsets.only(
        left:   24,
        right:  24,
        top:    16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Time display — tap to change
          GestureDetector(
            onTap: _pickTime,
            child: Text(
              '$h:$m $ampm',
              style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00B4D8),
                  height: 1),
            ),
          ),
          const SizedBox(height: 4),
          const Text('Tap to change time',
              style:
              TextStyle(fontSize: 11, color: Color(0xFF4A6A90))),
          const SizedBox(height: 20),

          // Label field
          TextField(
            controller: _labelCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Label',
              hintStyle:
              const TextStyle(color: Color(0xFF4A6A90)),
              filled: true,
              fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                const BorderSide(color: Color(0xFF1E3A5F)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                const BorderSide(color: Color(0xFF1E3A5F)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                const BorderSide(color: Color(0xFF00B4D8)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Repeat day buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (i) {
              final active = _repeatDays[i];
              return GestureDetector(
                onTap: () =>
                    setState(() => _repeatDays[i] = !active),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF00B4D8)
                        : const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: active
                          ? const Color(0xFF00B4D8)
                          : const Color(0xFF1E3A5F),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    days[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? Colors.white
                          : const Color(0xFF4A6A90),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Sound picker row
          GestureDetector(
            onTap: _showSoundPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(10),
                border:
                Border.all(color: const Color(0xFF1E3A5F)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.music_note_outlined,
                      color: Color(0xFF00B4D8), size: 18),
                  const SizedBox(width: 12),
                  const Text('Ringtone',
                      style: TextStyle(
                          color: Color(0xFF4A6A90), fontSize: 13)),
                  const Spacer(),
                  Text(
                    _sound,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right,
                      color: Color(0xFF4A6A90), size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B4D8),
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'SAVE ALARM',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}