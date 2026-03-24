import 'package:flutter/material.dart';

class AlarmModel {
  final String id;
  String label;
  int hour;
  int minute;
  bool isEnabled;
  List<bool> repeatDays; // Mon-Sun
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
    if (active.length == 5 && !repeatDays[5] && !repeatDays[6]) return 'Weekdays';
    return active.join(', ');
  }
}

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final List<AlarmModel> _alarms = [
    AlarmModel(id: '1', label: 'Wake Up', hour: 6, minute: 30,
        repeatDays: [true, true, true, true, true, false, false]),
    AlarmModel(id: '2', label: 'Gym', hour: 7, minute: 0,
        repeatDays: [false, false, false, false, false, true, true]),
    AlarmModel(id: '3', label: 'Meeting', hour: 9, minute: 30, isEnabled: false),
  ];

  void _showAddAlarm({AlarmModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AlarmEditSheet(
        alarm: existing,
        onSave: (alarm) {
          setState(() {
            if (existing != null) {
              final i = _alarms.indexWhere((a) => a.id == existing.id);
              if (i >= 0) _alarms[i] = alarm;
            } else {
              _alarms.add(alarm);
            }
          });
        },
      ),
    );
  }

  void _deleteAlarm(String id) {
    setState(() => _alarms.removeWhere((a) => a.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ALARM',
                      style: TextStyle(fontSize: 13, letterSpacing: 4,
                          color: Color(0xFF4A6A90), fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: () => _showAddAlarm(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B4D8).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF00B4D8).withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.add, color: Color(0xFF00B4D8), size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _alarms.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.alarm_off, size: 56, color: const Color(0xFF1E3A5F)),
                    const SizedBox(height: 16),
                    const Text('No alarms set',
                        style: TextStyle(color: Color(0xFF4A6A90), fontSize: 16)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _alarms.length,
                itemBuilder: (_, i) => _AlarmTile(
                  alarm: _alarms[i],
                  onToggle: (v) => setState(() => _alarms[i].isEnabled = v),
                  onTap: () => _showAddAlarm(existing: _alarms[i]),
                  onDelete: () => _deleteAlarm(_alarms[i].id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        child: const Icon(Icons.delete_outline, color: Color(0xFFFF4757)),
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
                    Text(alarm.timeString,
                        style: TextStyle(
                          fontSize: 36, fontWeight: FontWeight.w800,
                          color: alarm.isEnabled ? Colors.white : const Color(0xFF4A6A90),
                          fontFeatures: const [FontFeature.tabularFigures()],
                          height: 1,
                        )),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(alarm.label,
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500,
                              color: alarm.isEnabled
                                  ? const Color(0xFF00B4D8)
                                  : const Color(0xFF2A4A6A),
                            )),
                        const SizedBox(width: 8),
                        Text('• ${alarm.repeatString}',
                            style: TextStyle(
                              fontSize: 12,
                              color: alarm.isEnabled
                                  ? const Color(0xFF4A6A90)
                                  : const Color(0xFF2A4A6A),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: alarm.isEnabled,
                onChanged: onToggle,
                activeColor: const Color(0xFF00B4D8),
                activeTrackColor: const Color(0xFF00B4D8).withOpacity(0.3),
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

  @override
  void initState() {
    super.initState();
    final a = widget.alarm;
    _hour = a?.hour ?? 7;
    _minute = a?.minute ?? 0;
    _label = a?.label ?? 'Alarm';
    _repeatDays = List.from(a?.repeatDays ?? List.filled(7, false));
    _sound = a?.sound ?? 'Default';
    _labelCtrl = TextEditingController(text: _label);
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
          colorScheme: const ColorScheme.dark(primary: Color(0xFF00B4D8)),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() { _hour = t.hour; _minute = t.minute; });
  }

  void _save() {
    final alarm = AlarmModel(
      id: widget.alarm?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      label: _labelCtrl.text.isEmpty ? 'Alarm' : _labelCtrl.text,
      hour: _hour,
      minute: _minute,
      repeatDays: _repeatDays,
      sound: _sound,
    );
    widget.onSave(alarm);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final h = _hour > 12 ? _hour - 12 : (_hour == 0 ? 12 : _hour);
    final m = _minute.toString().padLeft(2, '0');
    final ampm = _hour >= 12 ? 'PM' : 'AM';
    const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1526),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF1E3A5F))),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _pickTime,
            child: Text('$h:$m $ampm',
                style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800,
                    color: Color(0xFF00B4D8), height: 1)),
          ),
          const SizedBox(height: 4),
          const Text('Tap to change time',
              style: TextStyle(fontSize: 11, color: Color(0xFF4A6A90))),
          const SizedBox(height: 20),
          TextField(
            controller: _labelCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Label',
              hintStyle: const TextStyle(color: Color(0xFF4A6A90)),
              filled: true,
              fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF00B4D8)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (i) {
              final active = _repeatDays[i];
              return GestureDetector(
                onTap: () => setState(() => _repeatDays[i] = !active),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36, height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF00B4D8) : const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: active ? const Color(0xFF00B4D8) : const Color(0xFF1E3A5F),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(days[i],
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: active ? Colors.white : const Color(0xFF4A6A90),
                      )),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B4D8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('SAVE ALARM',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}