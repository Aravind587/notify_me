import 'package:flutter/material.dart';

/// NOTE: For real notifications, add flutter_local_notifications to pubspec.yaml:
///   flutter_local_notifications: ^17.0.0
/// Then initialize in main() and call the scheduling methods below.
/// This file uses a simulated in-app notification approach with full UI.

enum ReminderInterval { at_time, five_min, fifteen_min, thirty_min, one_hour, one_day }

extension ReminderIntervalLabel on ReminderInterval {
  String get label {
    switch (this) {
      case ReminderInterval.at_time: return 'At event time';
      case ReminderInterval.five_min: return '5 min before';
      case ReminderInterval.fifteen_min: return '15 min before';
      case ReminderInterval.thirty_min: return '30 min before';
      case ReminderInterval.one_hour: return '1 hour before';
      case ReminderInterval.one_day: return '1 day before';
    }
  }
}

class EventModel {
  final String id;
  String title;
  String description;
  DateTime date;
  TimeOfDay time;
  Color color;
  List<ReminderInterval> reminders;
  bool isCompleted;

  EventModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.date,
    required this.time,
    this.color = const Color(0xFF00B4D8),
    List<ReminderInterval>? reminders,
    this.isCompleted = false,
  }) : reminders = reminders ?? [ReminderInterval.fifteen_min];

  DateTime get eventDateTime => DateTime(
      date.year, date.month, date.day, time.hour, time.minute);

  bool get isUpcoming => eventDateTime.isAfter(DateTime.now());

  String get formattedDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String get formattedTime {
    final h = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final m = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  Duration get timeUntil => eventDateTime.difference(DateTime.now());
}

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<EventModel> _events = [
    EventModel(
      id: '1',
      title: 'Team Standup',
      description: 'Daily sync with the engineering team',
      date: DateTime.now().add(const Duration(hours: 2)),
      time: TimeOfDay.now(),
      color: const Color(0xFF00B4D8),
      reminders: [ReminderInterval.five_min, ReminderInterval.fifteen_min],
    ),
    EventModel(
      id: '2',
      title: 'Doctor Appointment',
      description: 'Annual checkup at City Clinic',
      date: DateTime.now().add(const Duration(days: 3)),
      time: const TimeOfDay(hour: 10, minute: 30),
      color: const Color(0xFF00FFB3),
      reminders: [ReminderInterval.one_hour, ReminderInterval.one_day],
    ),
    EventModel(
      id: '3',
      title: 'Project Deadline',
      description: 'Submit final deliverables',
      date: DateTime.now().add(const Duration(days: 7)),
      time: const TimeOfDay(hour: 17, minute: 0),
      color: const Color(0xFFFF6B6B),
      reminders: [ReminderInterval.one_day],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<EventModel> get _upcoming =>
      _events.where((e) => e.isUpcoming && !e.isCompleted).toList()
        ..sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));

  List<EventModel> get _past =>
      _events.where((e) => !e.isUpcoming || e.isCompleted).toList()
        ..sort((a, b) => b.eventDateTime.compareTo(a.eventDateTime));

  void _addEvent() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventEditSheet(
        onSave: (event) => setState(() => _events.add(event)),
      ),
    );
  }

  void _editEvent(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventEditSheet(
        event: event,
        onSave: (updated) {
          setState(() {
            final i = _events.indexWhere((e) => e.id == event.id);
            if (i >= 0) _events[i] = updated;
          });
        },
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('EVENTS',
                      style: TextStyle(fontSize: 13, letterSpacing: 4,
                          color: Color(0xFF4A6A90), fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: _addEvent,
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

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E3A5F)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF00B4D8),
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF4A6A90),
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'UPCOMING (${_upcoming.length})'),
                  Tab(text: 'PAST (${_past.length})'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEventList(_upcoming),
                  _buildEventList(_past),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(List<EventModel> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 56, color: const Color(0xFF1E3A5F)),
            const SizedBox(height: 16),
            const Text('No events', style: TextStyle(color: Color(0xFF4A6A90), fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (_, i) => _EventTile(
        event: events[i],
        onTap: () => _editEvent(events[i]),
        onComplete: () => setState(() => events[i].isCompleted = !events[i].isCompleted),
        onDelete: () => setState(() => _events.removeWhere((e) => e.id == events[i].id)),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _EventTile({
    required this.event,
    required this.onTap,
    required this.onComplete,
    required this.onDelete,
  });

  String _timeUntilString() {
    final d = event.timeUntil;
    if (d.isNegative) return 'Past';
    if (d.inDays > 0) return 'In ${d.inDays}d ${d.inHours.remainder(24)}h';
    if (d.inHours > 0) return 'In ${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return 'In ${d.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(event.id),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1526),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: event.isCompleted
                  ? const Color(0xFF1E3A5F)
                  : event.color.withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color indicator
              Container(
                width: 4, height: 60,
                decoration: BoxDecoration(
                  color: event.isCompleted ? const Color(0xFF2A4A6A) : event.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(event.title,
                              style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700,
                                color: event.isCompleted
                                    ? const Color(0xFF4A6A90)
                                    : Colors.white,
                                decoration: event.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              )),
                        ),
                        if (!event.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: event.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(_timeUntilString(),
                                style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w700,
                                    color: event.color)),
                          ),
                      ],
                    ),
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(event.description,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF4A6A90)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 11, color: const Color(0xFF4A6A90)),
                        const SizedBox(width: 4),
                        Text(event.formattedDate,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF4A6A90))),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time,
                            size: 11, color: const Color(0xFF4A6A90)),
                        const SizedBox(width: 4),
                        Text(event.formattedTime,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF4A6A90))),
                        const SizedBox(width: 12),
                        Icon(Icons.notifications_outlined,
                            size: 11, color: const Color(0xFF4A6A90)),
                        const SizedBox(width: 4),
                        Text('${event.reminders.length} reminder${event.reminders.length > 1 ? 's' : ''}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF4A6A90))),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onComplete,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: event.isCompleted
                        ? const Color(0xFF00FFB3).withOpacity(0.2)
                        : const Color(0xFF111827),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: event.isCompleted
                          ? const Color(0xFF00FFB3)
                          : const Color(0xFF1E3A5F),
                    ),
                  ),
                  child: event.isCompleted
                      ? const Icon(Icons.check, color: Color(0xFF00FFB3), size: 16)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventEditSheet extends StatefulWidget {
  final EventModel? event;
  final ValueChanged<EventModel> onSave;

  const _EventEditSheet({this.event, required this.onSave});

  @override
  State<_EventEditSheet> createState() => _EventEditSheetState();
}

class _EventEditSheetState extends State<_EventEditSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late DateTime _date;
  late TimeOfDay _time;
  late Color _color;
  late List<ReminderInterval> _reminders;

  final List<Color> _colors = const [
    Color(0xFF00B4D8), Color(0xFF00FFB3), Color(0xFFFF6B6B),
    Color(0xFFFFD700), Color(0xFFBB86FC), Color(0xFFFF8C00),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _date = e?.date ?? DateTime.now();
    _time = e?.time ?? TimeOfDay.now();
    _color = e?.color ?? const Color(0xFF00B4D8);
    _reminders = List.from(e?.reminders ?? [ReminderInterval.fifteen_min]);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF00B4D8)),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context, initialTime: _time,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF00B4D8)),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _time = t);
  }

  void _toggleReminder(ReminderInterval r) {
    setState(() {
      if (_reminders.contains(r)) {
        _reminders.remove(r);
      } else {
        _reminders.add(r);
      }
    });
  }

  void _save() {
    if (_titleCtrl.text.isEmpty) return;
    final event = EventModel(
      id: widget.event?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text,
      description: _descCtrl.text,
      date: _date,
      time: _time,
      color: _color,
      reminders: _reminders.isEmpty ? [ReminderInterval.at_time] : _reminders,
    );

    // In production, schedule notifications here using flutter_local_notifications
    // For each reminder in event.reminders, calculate notification time and schedule.

    widget.onSave(event);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0D1526),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Color(0xFF00FFB3), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Event saved! ${_reminders.length} reminder${_reminders.length != 1 ? 's' : ''} scheduled.',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _formattedDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[_date.month - 1]} ${_date.day}, ${_date.year}';
  }

  String get _formattedTime {
    final h = _time.hour > 12 ? _time.hour - 12 : (_time.hour == 0 ? 12 : _time.hour);
    final m = _time.minute.toString().padLeft(2, '0');
    final ampm = _time.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFF1E3A5F),
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),

            const Text('EVENT TITLE',
                style: TextStyle(fontSize: 9, color: Color(0xFF4A6A90), letterSpacing: 1.5)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              decoration: _inputDecoration('e.g. Team Meeting'),
            ),

            const SizedBox(height: 16),

            const Text('DESCRIPTION',
                style: TextStyle(fontSize: 9, color: Color(0xFF4A6A90), letterSpacing: 1.5)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: _inputDecoration('Optional notes...'),
            ),

            const SizedBox(height: 16),

            // Date & Time row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DATE',
                          style: TextStyle(fontSize: 9, color: Color(0xFF4A6A90), letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF1E3A5F)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 14, color: Color(0xFF00B4D8)),
                              const SizedBox(width: 8),
                              Text(_formattedDate,
                                  style: const TextStyle(color: Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TIME',
                          style: TextStyle(fontSize: 9, color: Color(0xFF4A6A90), letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF1E3A5F)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 14, color: Color(0xFF00B4D8)),
                              const SizedBox(width: 8),
                              Text(_formattedTime,
                                  style: const TextStyle(color: Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Color picker
            const Text('COLOR',
                style: TextStyle(fontSize: 9, color: Color(0xFF4A6A90), letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Row(
              children: _colors.map((c) => GestureDetector(
                onTap: () => setState(() => _color = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32, height: 32,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _color == c ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: _color == c
                        ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)]
                        : null,
                  ),
                ),
              )).toList(),
            ),

            const SizedBox(height: 16),

            // Reminders
            const Text('REMINDERS',
                style: TextStyle(fontSize: 9, color: Color(0xFF4A6A90), letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: ReminderInterval.values.map((r) {
                final isSelected = _reminders.contains(r);
                return GestureDetector(
                  onTap: () => _toggleReminder(r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00B4D8).withOpacity(0.2)
                          : const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00B4D8)
                            : const Color(0xFF1E3A5F),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_outlined,
                            size: 12,
                            color: isSelected
                                ? const Color(0xFF00B4D8)
                                : const Color(0xFF4A6A90)),
                        const SizedBox(width: 5),
                        Text(r.label,
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF00B4D8)
                                  : const Color(0xFF4A6A90),
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _titleCtrl.text.isEmpty ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: const Color(0xFF1E3A5F),
                ),
                child: const Text('SAVE EVENT',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF4A6A90)),
    filled: true,
    fillColor: const Color(0xFF111827),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1E3A5F))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1E3A5F))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF00B4D8))),
  );
}