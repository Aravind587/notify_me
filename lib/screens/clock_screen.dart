import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  late DateTime _now;
  late Timer _timer;
  bool _showAnalog = true;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _formattedDate {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[_now.weekday - 1]}, ${months[_now.month - 1]} ${_now.day}, ${_now.year}';
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
                  const Text('CLOCK',
                      style: TextStyle(fontSize: 13, letterSpacing: 4,
                          color: Color(0xFF4A6A90), fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: () => setState(() => _showAnalog = !_showAnalog),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1E3A5F)),
                      ),
                      child: Row(
                        children: [
                          _toggleBtn('Analog', _showAnalog),
                          _toggleBtn('Digital', !_showAnalog),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _showAnalog
                          ? AnalogClock(now: _now, key: const ValueKey('analog'))
                          : DigitalClock(now: _now, key: const ValueKey('digital')),
                    ),
                    const SizedBox(height: 36),
                    Text(_formattedDate,
                        style: const TextStyle(fontSize: 15, color: Color(0xFF4A6A90), letterSpacing: 0.5)),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _infoPill('TIMEZONE', _now.timeZoneName),
                        const SizedBox(width: 12),
                        _infoPill('UTC OFFSET',
                            '${_now.timeZoneOffset.isNegative ? '-' : '+'}${_now.timeZoneOffset.inHours.abs().toString().padLeft(2, '0')}:00'),
                      ],
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

  Widget _toggleBtn(String label, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF00B4D8) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5,
            color: active ? Colors.white : const Color(0xFF4A6A90),
          )),
    );
  }

  Widget _infoPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF4A6A90), letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class AnalogClock extends StatelessWidget {
  final DateTime now;
  const AnalogClock({super.key, required this.now});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260, height: 260,
      child: CustomPaint(painter: _AnalogPainter(now)),
    );
  }
}

class _AnalogPainter extends CustomPainter {
  final DateTime now;
  _AnalogPainter(this.now);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(center, radius,
        Paint()..color = const Color(0xFF00B4D8).withOpacity(0.08));
    canvas.drawCircle(center, radius - 4,
        Paint()..color = const Color(0xFF0D1526));
    canvas.drawCircle(center, radius - 4,
        Paint()..color = const Color(0xFF1E3A5F)..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(center, radius - 12,
        Paint()..color = const Color(0xFF00B4D8).withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1);

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * pi / 180;
      final isQ = i % 3 == 0;
      final len = isQ ? 14.0 : 8.0;
      final outer = Offset(center.dx + (radius - 18) * cos(angle - pi / 2),
          center.dy + (radius - 18) * sin(angle - pi / 2));
      final inner = Offset(center.dx + (radius - 18 - len) * cos(angle - pi / 2),
          center.dy + (radius - 18 - len) * sin(angle - pi / 2));
      canvas.drawLine(outer, inner,
          Paint()..color = isQ ? const Color(0xFF00B4D8) : const Color(0xFF2A4A6A)
            ..strokeWidth = isQ ? 2.5 : 1.5..strokeCap = StrokeCap.round);
    }

    for (int i = 0; i < 60; i++) {
      if (i % 5 == 0) continue;
      final angle = (i * 6) * pi / 180;
      final outer = Offset(center.dx + (radius - 18) * cos(angle - pi / 2),
          center.dy + (radius - 18) * sin(angle - pi / 2));
      final inner = Offset(center.dx + (radius - 24) * cos(angle - pi / 2),
          center.dy + (radius - 24) * sin(angle - pi / 2));
      canvas.drawLine(outer, inner,
          Paint()..color = const Color(0xFF1E3A5F)..strokeWidth = 1..strokeCap = StrokeCap.round);
    }

    final hourAngle = ((now.hour % 12) + now.minute / 60) * 30 * pi / 180 - pi / 2;
    _drawHand(canvas, center, hourAngle, radius * 0.5, 5, const Color(0xFFE2EAF0));
    final minuteAngle = (now.minute + now.second / 60) * 6 * pi / 180 - pi / 2;
    _drawHand(canvas, center, minuteAngle, radius * 0.7, 3.5, const Color(0xFF00B4D8));
    final secondAngle = now.second * 6 * pi / 180 - pi / 2;
    _drawHand(canvas, center, secondAngle, radius * 0.78, 1.5, const Color(0xFF00FFB3));
    _drawHand(canvas, center, secondAngle + pi, radius * 0.15, 1.5, const Color(0xFF00FFB3));

    canvas.drawCircle(center, 6, Paint()..color = const Color(0xFF00B4D8));
    canvas.drawCircle(center, 3, Paint()..color = Colors.white);
  }

  void _drawHand(Canvas canvas, Offset center, double angle, double length, double width, Color color) {
    final tip = Offset(center.dx + length * cos(angle), center.dy + length * sin(angle));
    canvas.drawLine(center, tip,
        Paint()..color = color..strokeWidth = width..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_AnalogPainter old) => old.now != now;
}

class DigitalClock extends StatelessWidget {
  final DateTime now;
  const DigitalClock({super.key, required this.now});

  String _pad(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final ampm = now.hour >= 12 ? 'PM' : 'AM';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _timeSegment(_pad(h)), _colon(),
            _timeSegment(_pad(now.minute)), _colon(),
            _timeSegment(_pad(now.second)),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(ampm, style: const TextStyle(
                  fontSize: 22, color: Color(0xFF00B4D8), fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 280,
          child: Column(
            children: [
              _progressRow('H', now.hour / 23, const Color(0xFF00B4D8)),
              const SizedBox(height: 8),
              _progressRow('M', now.minute / 59, const Color(0xFF00FFB3)),
              const SizedBox(height: 8),
              _progressRow('S', now.second / 59, const Color(0xFFFF6B6B)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timeSegment(String val) {
    return Container(
      width: 76, height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1526), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      alignment: Alignment.center,
      child: Text(val, style: const TextStyle(
          fontSize: 52, fontWeight: FontWeight.w800, color: Colors.white, height: 1,
          fontFeatures: [FontFeature.tabularFigures()])),
    );
  }

  Widget _colon() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(height: 16),
        Text(':', style: TextStyle(fontSize: 44, color: Color(0xFF1E3A5F), fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _progressRow(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(width: 16, child: Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF4A6A90), letterSpacing: 1))),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value, backgroundColor: const Color(0xFF111827),
              valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 4,
            ),
          ),
        ),
      ],
    );
  }
}