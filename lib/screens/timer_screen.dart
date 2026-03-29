// lib/screens/timer_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

enum TimerState { idle, running, paused, finished }

class TimerModel {
  final String id;
  String label;
  final Duration totalDuration;
  Duration remaining;
  TimerState state;

  TimerModel({
    required this.id,
    required this.label,
    required this.totalDuration,
  })  : remaining = totalDuration,
        state = TimerState.idle;

  double get progress {
    if (totalDuration.inMilliseconds == 0) return 0;
    return 1 - (remaining.inMilliseconds / totalDuration.inMilliseconds);
  }

  bool get isFinished => state == TimerState.finished;
  bool get isRunning  => state == TimerState.running;
  bool get isPaused   => state == TimerState.paused;
  bool get isIdle     => state == TimerState.idle;
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final List<TimerModel> _timers = [];
  final Map<String, Timer> _tickerMap = {};
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Track which timer is currently alerting so we can show the popup once
  String? _alertingTimerId;

  @override
  void dispose() {
    for (final t in _tickerMap.values) { t.cancel(); }
    _audioPlayer.dispose();
    super.dispose();
  }

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

    // If this timer was the one alerting, stop the sound and close any open dialog
    if (_alertingTimerId == model.id) {
      _audioPlayer.stop();
      _alertingTimerId = null;
      // Pop the alert dialog if it is showing
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
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
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    setState(() => _timers.removeWhere((t) => t.id == id));
  }

  Future<void> _playAlert(TimerModel model) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/alarm_default.mp3'));
      _alertingTimerId = model.id;
      // Show the alert dialog
      if (mounted) {
        _showAlertDialog(model);
      }
    } catch (e) {
      debugPrint('[TimerScreen] Could not play sound: $e');
    }
  }

  /// Stops audio and resets the finished timer back to idle.
  /// Optionally snoozes it for [snoozeDuration].
  Future<void> _stopAlert(TimerModel model, {Duration? snoozeDuration}) async {
    // 1. Stop the audio immediately
    await _audioPlayer.stop();
    _alertingTimerId = null;

    if (!mounted) return;

    setState(() {
      if (snoozeDuration != null) {
        // Snooze: set remaining to snooze duration and go back to idle
        // so the user can tap play, OR auto-start here if you prefer.
        model.remaining = snoozeDuration;
        model.state     = TimerState.idle;
      } else {
        // Plain stop: reset to beginning, idle
        model.remaining = model.totalDuration;
        model.state     = TimerState.idle;
      }
    });

    // Auto-start snooze countdown
    if (snoozeDuration != null) {
      _startTimer(model);
    }
  }

  void _showAlertDialog(TimerModel model) {
    showDialog(
      context: context,
      barrierDismissible: false, // force user to tap a button
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D1526),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFFF4757), width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.alarm, color: Color(0xFFFF4757)),
              SizedBox(width: 8),
              Text('Time\'s Up!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Text(
            model.label,
            style: const TextStyle(color: Color(0xFF4A6A90), fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            // ── Snooze 5 min ──────────────────────────────────────────
            TextButton(
              onPressed: () {
                // 1. Close the dialog FIRST
                Navigator.of(dialogContext).pop();
                // 2. Then stop alert & start snooze
                _stopAlert(model, snoozeDuration: const Duration(minutes: 5));
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700).withOpacity(0.12),
                foregroundColor: const Color(0xFFFFD700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Snooze 5 min',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            // ── Stop ──────────────────────────────────────────────────
            TextButton(
              onPressed: () {
                // 1. Close the dialog FIRST
                Navigator.of(dialogContext).pop();
                // 2. Then stop the alert
                _stopAlert(model);
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFF4757).withOpacity(0.12),
                foregroundColor: const Color(0xFFFF4757),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Stop', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _showAddTimer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTimerSheet(
        onAdd: (label, duration) {
          setState(() {
            _timers.add(TimerModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              label: label,
              totalDuration: duration,
            ));
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
                  const Text('TIMER',
                      style: TextStyle(fontSize: 13, letterSpacing: 4,
                          color: Color(0xFF4A6A90), fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: _showAddTimer,
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
              child: _timers.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.hourglass_empty, size: 56, color: Color(0xFF1E3A5F)),
                    const SizedBox(height: 16),
                    const Text('No timers yet',
                        style: TextStyle(color: Color(0xFF4A6A90), fontSize: 16)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showAddTimer,
                      child: const Text('Tap + to add one',
                          style: TextStyle(color: Color(0xFF00B4D8), fontSize: 13)),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _timers.length,
                itemBuilder: (_, i) {
                  final model = _timers[i];
                  return _TimerTile(
                    key: Key(model.id),
                    model: model,
                    onStart:  () => _startTimer(model),
                    onPause:  () => _pauseTimer(model),
                    onReset:  () => _resetTimer(model),
                    onDelete: () => _deleteTimer(model.id),
                    // Inline stop from tile still works (no snooze)
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

// ─────────────────────────────────────────────────────────────────────────────
// _TimerTile — unchanged except onStopAlert now also resets state via _stopAlert
// ─────────────────────────────────────────────────────────────────────────────

class _TimerTile extends StatelessWidget {
  final TimerModel   model;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback onDelete;
  final VoidCallback onStopAlert;

  const _TimerTile({
    super.key,
    required this.model,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    required this.onDelete,
    required this.onStopAlert,
  });

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  String _fmtTotal(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final parts = <String>[];
    if (h > 0) parts.add('${h}h');
    if (m > 0) parts.add('${m}m');
    if (s > 0) parts.add('${s}s');
    return parts.join(' ');
  }

  Color get _ringColor {
    if (model.isFinished) return const Color(0xFFFF4757);
    if (model.isRunning)  return const Color(0xFF00FFB3);
    if (model.isPaused)   return const Color(0xFFFFD700);
    return const Color(0xFF00B4D8);
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('${model.id}_dismiss'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4757).withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFFF4757)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1526),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: model.isFinished
                ? const Color(0xFFFF4757).withOpacity(0.5)
                : model.isRunning
                ? const Color(0xFF00FFB3).withOpacity(0.3)
                : model.isPaused
                ? const Color(0xFFFFD700).withOpacity(0.3)
                : const Color(0xFF1E3A5F),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(80, 80),
                    painter: _RingPainter(progress: model.progress, color: _ringColor),
                  ),
                  Text(
                    _fmt(model.remaining),
                    style: TextStyle(
                      fontSize: model.remaining.inHours >= 1 ? 12 : 15,
                      fontWeight: FontWeight.w800,
                      color: model.isFinished ? const Color(0xFFFF4757) : Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(model.label,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    model.isFinished ? '⏰  Time\'s up!'
                        : model.isRunning ? 'Running…'
                        : model.isPaused  ? 'Paused'
                        : _fmtTotal(model.totalDuration),
                    style: TextStyle(
                      fontSize: 12,
                      color: model.isFinished ? const Color(0xFFFF4757)
                          : model.isRunning   ? const Color(0xFF00FFB3)
                          : model.isPaused    ? const Color(0xFFFFD700)
                          : const Color(0xFF4A6A90),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                if (model.isFinished)
                  _iconBtn(icon: Icons.volume_off, color: const Color(0xFFFF4757), onTap: onStopAlert)
                else
                  _iconBtn(
                    icon: model.isRunning ? Icons.pause : Icons.play_arrow,
                    color: model.isRunning ? const Color(0xFFFFD700) : const Color(0xFF00FFB3),
                    onTap: model.isRunning ? onPause : onStart,
                  ),
                const SizedBox(width: 8),
                _iconBtn(icon: Icons.refresh, color: const Color(0xFF4A6A90), onTap: onReset),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn({required IconData icon, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

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

class _AddTimerSheet extends StatefulWidget {
  final void Function(String label, Duration duration) onAdd;
  const _AddTimerSheet({required this.onAdd});

  @override
  State<_AddTimerSheet> createState() => _AddTimerSheetState();
}

class _AddTimerSheetState extends State<_AddTimerSheet> {
  int _hours = 0, _minutes = 5, _seconds = 0;
  late TextEditingController _labelCtrl;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: 'Timer');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  bool get _isValid => (_hours + _minutes + _seconds) > 0;

  void _save() {
    if (!_isValid) return;
    widget.onAdd(
      _labelCtrl.text.isEmpty ? 'Timer' : _labelCtrl.text,
      Duration(hours: _hours, minutes: _minutes, seconds: _seconds),
    );
    Navigator.pop(context);
  }

  Widget _spinner({required int value, required int max, required String label, required ValueChanged<int> onChange}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF4A6A90), letterSpacing: 1.5)),
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
                child: const Padding(padding: EdgeInsets.symmetric(vertical: 8),
                    child: Icon(Icons.keyboard_arrow_up, color: Color(0xFF00B4D8), size: 22)),
              ),
              Text(value.toString().padLeft(2, '0'),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800,
                      color: Colors.white, height: 1, fontFeatures: [FontFeature.tabularFigures()])),
              GestureDetector(
                onTap: () => onChange(value == 0 ? max : value - 1),
                child: const Padding(padding: EdgeInsets.symmetric(vertical: 8),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF1E3A5F))),
      ),
      padding: EdgeInsets.only(
          left: 24, right: 24, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFF1E3A5F), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _spinner(value: _hours,   max: 23, label: 'HOURS', onChange: (v) => setState(() => _hours = v)),
              const Padding(padding: EdgeInsets.only(top: 44, left: 8, right: 8),
                  child: Text(':', style: TextStyle(fontSize: 28, color: Color(0xFF1E3A5F), fontWeight: FontWeight.w700))),
              _spinner(value: _minutes, max: 59, label: 'MIN',   onChange: (v) => setState(() => _minutes = v)),
              const Padding(padding: EdgeInsets.only(top: 44, left: 8, right: 8),
                  child: Text(':', style: TextStyle(fontSize: 28, color: Color(0xFF1E3A5F), fontWeight: FontWeight.w700))),
              _spinner(value: _seconds, max: 59, label: 'SEC',   onChange: (v) => setState(() => _seconds = v)),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E3A5F))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E3A5F))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00B4D8))),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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