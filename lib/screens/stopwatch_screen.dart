import 'dart:async';
import 'package:flutter/material.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen>
    with SingleTickerProviderStateMixin {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final List<Duration> _laps = [];
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startStop() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _timer?.cancel();
    } else {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
        setState(() {});
      });
    }
    setState(() {});
  }

  void _lapReset() {
    if (_stopwatch.isRunning) {
      setState(() => _laps.insert(0, _stopwatch.elapsed));
    } else {
      setState(() {
        _stopwatch.reset();
        _laps.clear();
      });
    }
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$min:$sec.$ms';
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _stopwatch.elapsed;
    final isRunning = _stopwatch.isRunning;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  const Text('STOPWATCH',
                      style: TextStyle(fontSize: 13, letterSpacing: 4,
                          color: Color(0xFF4A6A90), fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            // Main display
            Expanded(
              flex: 3,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background ring
                    SizedBox(
                      width: 260, height: 260,
                      child: CircularProgressIndicator(
                        value: (elapsed.inMilliseconds % 60000) / 60000,
                        strokeWidth: 6,
                        backgroundColor: const Color(0xFF1E3A5F),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isRunning ? const Color(0xFF00FFB3) : const Color(0xFF00B4D8),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isRunning)
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (_, __) => Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: Color.lerp(const Color(0xFF00FFB3),
                                    const Color(0xFF00FFB3).withOpacity(0.2),
                                    _pulseController.value),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        if (isRunning) const SizedBox(height: 8),
                        Text(_formatDuration(elapsed),
                            style: const TextStyle(
                              fontSize: 42, fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFeatures: [FontFeature.tabularFigures()],
                            )),
                        if (_laps.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('LAP ${_laps.length + 1}',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF4A6A90), letterSpacing: 2)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlBtn(
                    isRunning ? 'LAP' : 'RESET',
                    isRunning ? Icons.flag_outlined : Icons.refresh,
                    const Color(0xFF1E3A5F),
                    _lapReset,
                  ),
                  const SizedBox(width: 20),
                  _controlBtn(
                    isRunning ? 'STOP' : 'START',
                    isRunning ? Icons.pause : Icons.play_arrow,
                    isRunning ? const Color(0xFFFF6B6B) : const Color(0xFF00FFB3),
                    _startStop,
                    large: true,
                  ),
                ],
              ),
            ),

            // Laps
            if (_laps.isNotEmpty)
              Expanded(
                flex: 2,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D1526),
                    border: Border(top: BorderSide(color: Color(0xFF1E3A5F))),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('LAP', style: TextStyle(fontSize: 10,
                                color: Color(0xFF4A6A90), letterSpacing: 1.5)),
                            const Text('TIME', style: TextStyle(fontSize: 10,
                                color: Color(0xFF4A6A90), letterSpacing: 1.5)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _laps.length,
                          itemBuilder: (_, i) {
                            final lapNum = _laps.length - i;
                            final isBest = _laps.reduce((a, b) => a < b ? a : b) == _laps[i];
                            final isWorst = _laps.reduce((a, b) => a > b ? a : b) == _laps[i];
                            Color? textColor;
                            if (isBest && _laps.length > 1) textColor = const Color(0xFF00FFB3);
                            if (isWorst && _laps.length > 1) textColor = const Color(0xFFFF6B6B);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Lap $lapNum',
                                      style: TextStyle(
                                          fontSize: 14, color: textColor ?? const Color(0xFF4A6A90))),
                                  Text(_formatDuration(_laps[i]),
                                      style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w700,
                                        color: textColor ?? Colors.white,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      )),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _controlBtn(String label, IconData icon, Color color, VoidCallback onTap,
      {bool large = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: large ? 80 : 64,
        height: large ? 80 : 64,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: large ? 28 : 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, color: color,
                fontWeight: FontWeight.w700, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}