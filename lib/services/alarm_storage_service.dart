// lib/services/alarm_storage_service.dart
//
// Handles all alarm persistence using SharedPreferences.
// Call AlarmStorageService.saveAlarms() / loadAlarms() from AlarmScreen.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/alarm_screen.dart';

class AlarmStorageService {
  static const String _key = 'saved_alarms';

  /// Serialize one AlarmModel to a JSON-compatible Map.
  static Map<String, dynamic> _toMap(AlarmModel a) => {
    'id': a.id,
    'label': a.label,
    'hour': a.hour,
    'minute': a.minute,
    'isEnabled': a.isEnabled,
    'repeatDays': a.repeatDays,
    'sound': a.sound,
  };

  /// Deserialize one AlarmModel from a JSON-compatible Map.
  static AlarmModel _fromMap(Map<String, dynamic> m) => AlarmModel(
    id: m['id'] as String,
    label: m['label'] as String,
    hour: m['hour'] as int,
    minute: m['minute'] as int,
    isEnabled: m['isEnabled'] as bool? ?? true,
    repeatDays: (m['repeatDays'] as List<dynamic>?)
        ?.map((e) => e as bool)
        .toList() ??
        List.filled(7, false),
    sound: m['sound'] as String? ?? 'Default',
  );

  /// Persist the full alarm list.
  static Future<void> saveAlarms(List<AlarmModel> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
    jsonEncode(alarms.map(_toMap).toList());
    await prefs.setString(_key, encoded);
  }

  /// Load the full alarm list (returns [] on first run).
  static Future<List<AlarmModel>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => _fromMap(e as Map<String, dynamic>))
        .toList();
  }
}