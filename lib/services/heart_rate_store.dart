import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HeartRateMeasurement {
  const HeartRateMeasurement({required this.pulse, required this.at});

  final int pulse;
  final DateTime at;

  Map<String, Object> toJson() => {'pulse': pulse, 'at': at.toIso8601String()};

  factory HeartRateMeasurement.fromJson(Map<String, dynamic> json) =>
      HeartRateMeasurement(
        pulse: json['pulse'] as int,
        at: DateTime.parse(json['at'] as String),
      );
}

class HeartRateStore {
  HeartRateStore._();

  static final HeartRateStore instance = HeartRateStore._();

  static const _storageKey = 'daily_heart_rate_measurements';
  final ValueNotifier<int> revision = ValueNotifier(0);
  final List<HeartRateMeasurement> _measurements = [];
  Future<void>? _loading;
  bool isLoaded = false;

  List<HeartRateMeasurement> get measurements =>
      List.unmodifiable(_measurements);

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_storageKey);
      if (stored != null) {
        final decoded = jsonDecode(stored) as List<dynamic>;
        _measurements
          ..clear()
          ..addAll(
            decoded.map(
              (item) => HeartRateMeasurement.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            ),
          );
        _measurements.sort((a, b) => b.at.compareTo(a.at));
      }
    } catch (error) {
      debugPrint('Nie udało się wczytać pomiarów tętna: $error');
    } finally {
      isLoaded = true;
      revision.value++;
    }
  }

  bool hasMeasurementToday([DateTime? date]) {
    final today = date ?? DateTime.now();
    return _measurements.any((item) => _sameDay(item.at, today));
  }

  HeartRateMeasurement? measurementForDay(DateTime date) {
    for (final item in _measurements) {
      if (_sameDay(item.at, date)) return item;
    }
    return null;
  }

  Future<bool> addToday(int pulse) async {
    await load();
    if (hasMeasurementToday()) return false;
    final measurement = HeartRateMeasurement(pulse: pulse, at: DateTime.now());
    final updatedMeasurements = [measurement, ..._measurements];
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(updatedMeasurements.map((item) => item.toJson()).toList()),
    );
    _measurements
      ..clear()
      ..addAll(updatedMeasurements);
    revision.value++;
    return true;
  }

  static bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
