// lib/screens/timer_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

enum TimerState { idle, running, paused, finished }

// ─── Alarm sound options ─────────────────────────────────────────────────────
class AlarmSound {
  final String label;
  final String asset;
  final IconData icon;
  const AlarmSound({required this.label, required this.asset, required this.icon});
}

const List<AlarmSound> kAlarmSounds = [
  AlarmSound(label: 'Classic Bell',  asset: 'sounds/alarm_default.mp3',       icon: Icons.notifications_rounded),
  AlarmSound(label: 'Morning Call',  asset: 'sounds/morning_walkup_call.mp3', icon: Icons.graphic_eq_rounded),
  AlarmSound(label: 'Warning Alert', asset: 'sounds/warning_alert.mp3',       icon: Icons.campaign_rounded),
];

// ─── Model ───────────────────────────────────────────────────────────────────
class TimerModel {
  final String id;
  String label;
  final Duration totalDuration;
  Duration remaining;
  TimerState state;
  AlarmSound alarmSound;

  TimerModel({
    required this.id,
    required this.label,
    required this.totalDuration,
    AlarmSound? alarmSound,
  })  : remaining = totalDuration,
        state = TimerState.idle,
        alarmSound = alarmSound ?? kAlarmSounds.first;

  double get progress {
    if (totalDuration.inMilliseconds == 0) return 0;
    return 1 - (remaining.inMilliseconds / totalDuration.inMilliseconds);
  }

  bool get isFinished => state == TimerState.finished;
  bool get isRunning  => state == TimerState.running;
  bool get isPaused   => state == TimerState.paused;
  bool get isIdle     => state == TimerState.idle;
}

// ─── Screen ──────────────────────────────────────────────────────────────────
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final List<TimerModel> _timers = [];
  final Map<String, Timer> _tickerMap = {};
  final AudioPlayer _audioPlayer   = AudioPlayer();
  final AudioPlayer _previewPlayer = AudioPlayer();

  String? _alertingTimerId;

  @override
  void dispose() {
    for (final t in _tickerMap.values) t.cancel();
    _audioPlayer.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  // ── Timer control ─────────────────────────────────────────────────────────

  void _startTimer(TimerModel model) {
    if (model.remaining.inSeconds == 0) return;
    setState(() => model.state = TimerState.running);
    _tickerMap[model.id]?.cancel();
    _tickerMap[model.id] = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (model.remaining.inSeconds > 0) {
          model.remaining -= const Duration(seconds: 1);
        } else {
          model.state = TimerState.finished;
          _tickerMap[model.id]?.cancel();
          _tickerMap.remove(model.id);
          _playAlert(model);
        }
      });
    });
  }

  void _pauseTimer(TimerModel model) {
    _tickerMap[model.id]?.cancel();
    _tickerMap.remove(model.id);
    setState(() => model.state = TimerState.paused);
  }

  void _resetTimer(TimerModel model) {
    _tickerMap[model.id]?.cancel();
    _tickerMap.remove(model.id);
    if (_alertingTimerId == model.id) {
      _audioPlayer.stop();
      _alertingTimerId = null;
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    }
    setState(() {
      model.remaining = model.totalDuration;
      model.state     = TimerState.idle;
    });
  }

  void _deleteTimer(String id) {
    _tickerMap[id]?.cancel();
    _tickerMap.remove(id);
    if (_alertingTimerId == id) {
      _audioPlayer.stop();
      _alertingTimerId = null;
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    }
    setState(() => _timers.removeWhere((t) => t.id == id));
  }

  void _confirmDelete(TimerModel model) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1526),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF1E3A5F)),
        ),
        title: const Text('Delete Timer?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Remove "${model.label}"?',
            style: const TextStyle(color: Color(0xFF4A6A90))),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4A6A90),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () { Navigator.of(ctx).pop(); _deleteTimer(model.id); },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFF4757).withOpacity(0.12),
              foregroundColor: const Color(0xFFFF4757),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Alert ─────────────────────────────────────────────────────────────────

  Future<void> _playAlert(TimerModel model) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource(model.alarmSound.asset));
      _alertingTimerId = model.id;
      if (mounted) _showAlertDialog(model);
    } catch (e) {
      debugPrint('[TimerScreen] Could not play sound: $e');
    }
  }

  Future<void> _stopAlert(TimerModel model, {Duration? snoozeDuration}) async {
    await _audioPlayer.stop();
    _alertingTimerId = null;
    if (!mounted) return;
    setState(() {
      model.remaining = snoozeDuration ?? model.totalDuration;
      model.state     = TimerState.idle;
    });
    if (snoozeDuration != null) _startTimer(model);
  }

  void _showAlertDialog(TimerModel model) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0D1526),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF4757), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.alarm_rounded, color: Color(0xFFFF4757)),
            SizedBox(width: 8),
            Text("Time's Up!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(model.label, style: const TextStyle(color: Color(0xFF4A6A90), fontSize: 16)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _stopAlert(model, snoozeDuration: const Duration(minutes: 1));
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700).withOpacity(0.12),
              foregroundColor: const Color(0xFFFFD700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Snooze 1 min', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () { Navigator.of(dialogContext).pop(); _stopAlert(model); },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFF4757).withOpacity(0.12),
              foregroundColor: const Color(0xFFFF4757),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Stop', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Add Timer sheet ───────────────────────────────────────────────────────

  void _showAddTimer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTimerSheet(
        previewPlayer: _previewPlayer,
        onAdd: (label, duration, sound) {
          setState(() {
            _timers.add(TimerModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              label: label,
              totalDuration: duration,
              alarmSound: sound,
            ));
          });
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060E1E),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TIMERS',
                          style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 4,
                              color: Color(0xFF3D6A90),
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '${_timers.length} active',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _showAddTimer,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00B4D8), Color(0xFF0077A8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00B4D8).withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),

            // ── Timer list ────────────────────────────────────────────
            Expanded(
              child: _timers.isEmpty
                  ? _EmptyState(onTap: _showAddTimer)
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _timers.length,
                itemBuilder: (_, i) {
                  final model = _timers[i];
                  return _TimerCard(
                    key: Key(model.id),
                    model: model,
                    onStart:     () => _startTimer(model),
                    onPause:     () => _pauseTimer(model),
                    onReset:     () => _resetTimer(model),
                    onDelete:    () => _confirmDelete(model),
                    onStopAlert: () => _stopAlert(model),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1A2E),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1E3A5F), width: 1.5),
            ),
            child: const Icon(Icons.hourglass_top_rounded,
                size: 36, color: Color(0xFF1E3A5F)),
          ),
          const SizedBox(height: 20),
          const Text('No timers yet',
              style: TextStyle(
                  color: Color(0xFF4A6A90),
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF00B4D8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00B4D8).withOpacity(0.3)),
              ),
              child: const Text('+ Add your first timer',
                  style: TextStyle(color: Color(0xFF00B4D8), fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timer Card (redesigned) ──────────────────────────────────────────────────

class _TimerCard extends StatelessWidget {
  final TimerModel   model;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback onDelete;
  final VoidCallback onStopAlert;

  const _TimerCard({
    super.key,
    required this.model,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    required this.onDelete,
    required this.onStopAlert,
  });

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String _fmtTotal(Duration d) {
    final parts = <String>[];
    if (d.inHours > 0) parts.add('${d.inHours}h');
    if (d.inMinutes.remainder(60) > 0) parts.add('${d.inMinutes.remainder(60)}m');
    if (d.inSeconds.remainder(60) > 0) parts.add('${d.inSeconds.remainder(60)}s');
    return parts.join(' ');
  }

  // State-driven colors
  Color get _accentColor {
    if (model.isFinished) return const Color(0xFFFF4757);
    if (model.isRunning)  return const Color(0xFF00FFB3);
    if (model.isPaused)   return const Color(0xFFFFD700);
    return const Color(0xFF00B4D8);
  }

  List<Color> get _accentGradient {
    if (model.isFinished) return [const Color(0xFFFF4757), const Color(0xFFFF6B7A)];
    if (model.isRunning)  return [const Color(0xFF00C896), const Color(0xFF00FFB3)];
    if (model.isPaused)   return [const Color(0xFFFFB800), const Color(0xFFFFD700)];
    return [const Color(0xFF0090B0), const Color(0xFF00B4D8)];
  }

  String get _statusLabel {
    if (model.isFinished) return 'TIME\'S UP';
    if (model.isRunning)  return 'RUNNING';
    if (model.isPaused)   return 'PAUSED';
    return _fmtTotal(model.totalDuration);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: model.isFinished
              ? const Color(0xFFFF4757).withOpacity(0.4)
              : model.isRunning
              ? const Color(0xFF00FFB3).withOpacity(0.2)
              : const Color(0xFF1A2D45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(model.isRunning || model.isFinished ? 0.08 : 0.03),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // ── Progress bar at top ───────────────────────────────────
            _ProgressBar(progress: model.progress, colors: _accentGradient),

            // ── Card body ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 16),
              child: Row(
                children: [
                  // ── Left: time display ──────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label + three-dot menu in same row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                model.label,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.2),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // ── Three-dot menu ────────────────────────
                            _ThreeDotMenu(
                              onReset: onReset,
                              onDelete: onDelete,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Big time display
                        Text(
                          _fmt(model.remaining),
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: model.isFinished ? const Color(0xFFFF4757) : Colors.white,
                            letterSpacing: -1.5,
                            height: 1,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Status pill + sound chip
                        Row(
                          children: [
                            // Status pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _accentColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _accentColor.withOpacity(0.25)),
                              ),
                              child: Text(
                                _statusLabel,
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: _accentColor,
                                    letterSpacing: 1.2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Sound chip
                            Icon(model.alarmSound.icon, size: 11, color: const Color(0xFF3D5A7A)),
                            const SizedBox(width: 4),
                            Text(model.alarmSound.label,
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF3D5A7A), fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ── Right: play/pause or stop-alert button ──────────
                  _MainActionButton(
                    model: model,
                    accentColor: _accentColor,
                    accentGradient: _accentGradient,
                    onStart: onStart,
                    onPause: onPause,
                    onStopAlert: onStopAlert,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Progress bar ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double progress;
  final List<Color> colors;
  const _ProgressBar({required this.progress, required this.colors});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      return Stack(
        children: [
          // Track
          Container(height: 3, color: const Color(0xFF1A2D45)),
          // Fill
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: 3,
            width: constraints.maxWidth * progress,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
            ),
          ),
        ],
      );
    });
  }
}

// ─── Three-dot menu ───────────────────────────────────────────────────────────

class _ThreeDotMenu extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onDelete;
  const _ThreeDotMenu({required this.onReset, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'reset') onReset();
        if (val == 'delete') onDelete();
      },
      color: const Color(0xFF0D1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF1E3A5F)),
      ),
      offset: const Offset(0, 8),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'reset',
          child: Row(
            children: const [
              Icon(Icons.refresh_rounded, color: Color(0xFF4A6A90), size: 18),
              SizedBox(width: 10),
              Text('Reset', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: const [
              Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4757), size: 18),
              SizedBox(width: 10),
              Text('Delete', style: TextStyle(color: Color(0xFFFF4757), fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
        child: Icon(Icons.more_vert_rounded, color: const Color(0xFF3D5A7A), size: 20),
      ),
    );
  }
}

// ─── Main action button (big circular) ───────────────────────────────────────

class _MainActionButton extends StatelessWidget {
  final TimerModel model;
  final Color accentColor;
  final List<Color> accentGradient;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onStopAlert;

  const _MainActionButton({
    required this.model,
    required this.accentColor,
    required this.accentGradient,
    required this.onStart,
    required this.onPause,
    required this.onStopAlert,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    VoidCallback action;

    if (model.isFinished) {
      icon = Icons.volume_off_rounded;
      action = onStopAlert;
    } else if (model.isRunning) {
      icon = Icons.pause_rounded;
      action = onPause;
    } else {
      icon = Icons.play_arrow_rounded;
      action = onStart;
    }

    return GestureDetector(
      onTap: action,
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: accentGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

// ─── Ring painter (kept for compatibility) ────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color  color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    canvas.drawCircle(center, radius,
        Paint()..color = const Color(0xFF1E3A5F)..style = PaintingStyle.stroke..strokeWidth = 4);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, 2 * pi * progress, false,
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}

// ─── Add Timer sheet ──────────────────────────────────────────────────────────

class _AddTimerSheet extends StatefulWidget {
  final void Function(String label, Duration duration, AlarmSound sound) onAdd;
  final AudioPlayer previewPlayer;
  const _AddTimerSheet({required this.onAdd, required this.previewPlayer});

  @override
  State<_AddTimerSheet> createState() => _AddTimerSheetState();
}

class _AddTimerSheetState extends State<_AddTimerSheet> {
  int _hours = 0, _minutes = 1, _seconds = 0;
  late TextEditingController _labelCtrl;
  AlarmSound _selectedSound = kAlarmSounds.first;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: 'Timer');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    widget.previewPlayer.stop();
    super.dispose();
  }

  bool get _isValid => (_hours + _minutes + _seconds) > 0;

  void _save() {
    if (!_isValid) return;
    widget.previewPlayer.stop();
    widget.onAdd(
      _labelCtrl.text.isEmpty ? 'Timer' : _labelCtrl.text,
      Duration(hours: _hours, minutes: _minutes, seconds: _seconds),
      _selectedSound,
    );
    Navigator.pop(context);
  }

  Future<void> _previewSound(AlarmSound sound) async {
    await widget.previewPlayer.stop();
    await widget.previewPlayer.setReleaseMode(ReleaseMode.release);
    await widget.previewPlayer.play(AssetSource(sound.asset));
  }

  Widget _spinner({
    required int value,
    required int max,
    required String label,
    required ValueChanged<int> onChange,
  }) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 9, color: Color(0xFF4A6A90), letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Container(
          width: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1E3A5F)),
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => onChange((value + 1) % (max + 1)),
                child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Icon(Icons.keyboard_arrow_up, color: Color(0xFF00B4D8), size: 22)),
              ),
              Text(value.toString().padLeft(2, '0'),
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white,
                      height: 1, fontFeatures: [FontFeature.tabularFigures()])),
              GestureDetector(
                onTap: () => onChange(value == 0 ? max : value - 1),
                child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Icon(Icons.keyboard_arrow_down, color: Color(0xFF00B4D8), size: 22)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1526),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF1E3A5F))),
      ),
      padding: EdgeInsets.only(
          left: 24, right: 24, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _spinner(value: _hours, max: 23, label: 'HOURS',
                  onChange: (v) => setState(() => _hours = v)),
              const Padding(padding: EdgeInsets.only(top: 44, left: 8, right: 8),
                  child: Text(':', style: TextStyle(fontSize: 28, color: Color(0xFF1E3A5F), fontWeight: FontWeight.w700))),
              _spinner(value: _minutes, max: 59, label: 'MIN',
                  onChange: (v) => setState(() => _minutes = v)),
              const Padding(padding: EdgeInsets.only(top: 44, left: 8, right: 8),
                  child: Text(':', style: TextStyle(fontSize: 28, color: Color(0xFF1E3A5F), fontWeight: FontWeight.w700))),
              _spinner(value: _seconds, max: 59, label: 'SEC',
                  onChange: (v) => setState(() => _seconds = v)),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _labelCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Timer label',
              hintStyle: const TextStyle(color: Color(0xFF4A6A90)),
              filled: true, fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1E3A5F))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1E3A5F))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00B4D8))),
            ),
          ),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('ALARM SOUND',
                style: TextStyle(fontSize: 9, letterSpacing: 1.5,
                    color: Color(0xFF4A6A90), fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E3A5F)),
            ),
            child: Column(
              children: List.generate(kAlarmSounds.length, (index) {
                final sound      = kAlarmSounds[index];
                final isSelected = _selectedSound.asset == sound.asset;
                final isLast     = index == kAlarmSounds.length - 1;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () { setState(() => _selectedSound = sound); _previewSound(sound); },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00B4D8).withOpacity(0.08) : Colors.transparent,
                      borderRadius: isLast
                          ? const BorderRadius.vertical(bottom: Radius.circular(12))
                          : BorderRadius.zero,
                      border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF1E3A5F))),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF00B4D8).withOpacity(0.15)
                                : const Color(0xFF1E3A5F).withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(sound.icon, size: 16,
                              color: isSelected ? const Color(0xFF00B4D8) : const Color(0xFF4A6A90)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(sound.label,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected ? Colors.white : const Color(0xFF4A6A90),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF00B4D8), size: 18)
                        else
                          const Icon(Icons.play_circle_outline_rounded, color: Color(0xFF1E3A5F), size: 18),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isValid ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B4D8),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF1E3A5F),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('ADD TIMER',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}