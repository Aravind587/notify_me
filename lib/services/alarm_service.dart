// lib/services/alarm_service.dart

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../screens/alarm_screen.dart';
import 'alarm_storage_service.dart';

class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  Timer? _ticker;
  final AudioPlayer _player = AudioPlayer();
  final Set<String> _firedThisMinute = {};

  final StreamController<AlarmModel> _firingController =
  StreamController<AlarmModel>.broadcast();

  Stream<AlarmModel> get firingStream => _firingController.stream;

  void init() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _check());
  }

  void dispose() {
    _ticker?.cancel();
    _firingController.close();
    _player.dispose();
  }

  Future<void> _check() async {
    final now = DateTime.now();
    final alarms = await AlarmStorageService.loadAlarms();

    for (final alarm in alarms) {
      if (!alarm.isEnabled) continue;

      if (alarm.hour != now.hour || alarm.minute != now.minute) {
        _firedThisMinute.remove(alarm.id);
        continue;
      }

      if (_firedThisMinute.contains(alarm.id)) continue;

      final bool anyRepeat = alarm.repeatDays.any((d) => d);
      if (anyRepeat) {
        final todayIndex = now.weekday - 1;
        if (!alarm.repeatDays[todayIndex]) continue;
      }

      _firedThisMinute.add(alarm.id);
      await _fire(alarm);
    }
  }

  Future<void> _fire(AlarmModel alarm) async {
    // IMPORTANT: These keys must EXACTLY match the sound labels
    // shown inside alarm_screen.dart _sounds list below.
    // The filenames must EXACTLY match files inside assets/sounds/
    const soundMap = {
      'Default':             'sounds/alarm_default.mp3',
      'Morning Walkup Call': 'sounds/morning_walkup_call.mp3',
      'Warning Alert':       'sounds/warning_alert.mp3',
    };

    final assetPath = soundMap[alarm.sound] ?? soundMap['Default']!;

    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(assetPath));
      _firingController.add(alarm);
    } catch (e) {
      debugPrint('[AlarmService] Could not play sound: $e');
    }
  }

  Future<void> stopSound() async {
    await _player.stop();
  }

  Future<void> snooze({int minutes = 5}) async {
    await stopSound();
    await Future.delayed(Duration(minutes: minutes), () async {
      try {
        await _player.play(AssetSource('sounds/alarm_default.mp3'));
      } catch (_) {}
    });
  }
}