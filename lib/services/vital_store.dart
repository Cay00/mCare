import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VitalKind { glucose, bloodPressure, weight, temperature, saturation }

extension VitalKindCopy on VitalKind {
  String get label => switch (this) {
    VitalKind.glucose => 'Poziom cukru',
    VitalKind.bloodPressure => 'Ciśnienie',
    VitalKind.weight => 'Waga',
    VitalKind.temperature => 'Temperatura',
    VitalKind.saturation => 'Saturacja',
  };

  String get unit => switch (this) {
    VitalKind.glucose => 'mg/dl',
    VitalKind.bloodPressure => 'mmHg',
    VitalKind.weight => 'kg',
    VitalKind.temperature => '°C',
    VitalKind.saturation => '%',
  };

  String get entryHint => switch (this) {
    VitalKind.glucose => 'Wpisz wynik glukozy z dzisiejszego pomiaru.',
    VitalKind.bloodPressure =>
      'Wpisz ciśnienie skurczowe i rozkurczowe z dzisiaj.',
    VitalKind.weight => 'Wpisz dzisiejszą masę ciała.',
    VitalKind.temperature => 'Wpisz dzisiejszą temperaturę ciała.',
    VitalKind.saturation => 'Wpisz dzisiejsze nasycenie krwi tlenem.',
  };

  bool get usesDecimal =>
      this == VitalKind.weight || this == VitalKind.temperature;
}

class VitalReading {
  const VitalReading({
    required this.kind,
    required this.at,
    required this.primary,
    this.secondary,
  });

  final VitalKind kind;
  final DateTime at;
  final double primary;
  final double? secondary;

  Map<String, Object> toJson() => {
    'kind': kind.name,
    'at': at.toIso8601String(),
    'primary': primary,
    if (secondary != null) 'secondary': secondary!,
  };

  static VitalReading? fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String?;
    final kind = VitalKind.values.where((item) => item.name == kindName);
    if (kind.isEmpty) return null;
    return VitalReading(
      kind: kind.first,
      at: DateTime.parse(json['at'] as String),
      primary: (json['primary'] as num).toDouble(),
      secondary: (json['secondary'] as num?)?.toDouble(),
    );
  }
}

String formatVitalNumber(double value, {required bool decimal}) {
  if (!decimal || value == value.roundToDouble())
    return value.round().toString();
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String formatVitalValue(VitalReading reading) {
  if (reading.kind == VitalKind.bloodPressure) {
    final diastolic = reading.secondary ?? 0;
    return '${reading.primary.round()}/${diastolic.round()} ${reading.kind.unit}';
  }
  return '${formatVitalNumber(reading.primary, decimal: reading.kind.usesDecimal)} ${reading.kind.unit}';
}

String? validateVitalPrimary(VitalKind kind, String? raw) {
  final number = double.tryParse((raw ?? '').trim().replaceAll(',', '.'));
  if (number == null) return 'Podaj liczbę.';
  final (min, max, message) = switch (kind) {
    VitalKind.glucose => (20.0, 600.0, 'Podaj cukier w zakresie 20–600 mg/dl.'),
    VitalKind.bloodPressure => (
      70.0,
      250.0,
      'Podaj ciśnienie skurczowe w zakresie 70–250 mmHg.',
    ),
    VitalKind.weight => (20.0, 300.0, 'Podaj wagę w zakresie 20–300 kg.'),
    VitalKind.temperature => (
      30.0,
      45.0,
      'Podaj temperaturę w zakresie 30–45 °C.',
    ),
    VitalKind.saturation => (
      50.0,
      100.0,
      'Podaj saturację w zakresie 50–100%.',
    ),
  };
  if (number < min || number > max) return message;
  return null;
}

String? validateDiastolic(String? systolicRaw, String? diastolicRaw) {
  final systolic = double.tryParse(
    (systolicRaw ?? '').trim().replaceAll(',', '.'),
  );
  final diastolic = double.tryParse(
    (diastolicRaw ?? '').trim().replaceAll(',', '.'),
  );
  if (diastolic == null || diastolic < 40 || diastolic > 150) {
    return 'Podaj ciśnienie rozkurczowe w zakresie 40–150 mmHg.';
  }
  if (systolic != null && diastolic >= systolic) {
    return 'Rozkurczowe musi być niższe od skurczowego.';
  }
  return null;
}

class VitalStore {
  VitalStore._();

  static final VitalStore instance = VitalStore._();

  static const _storageKey = 'daily_vital_measurements';
  final ValueNotifier<int> revision = ValueNotifier(0);
  final List<VitalReading> _readings = [];
  Future<void>? _loading;
  bool isLoaded = false;

  List<VitalReading> get readings => List.unmodifiable(_readings);

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_storageKey);
      if (stored != null) {
        final decoded = jsonDecode(stored) as List<dynamic>;
        _readings
          ..clear()
          ..addAll(
            decoded
                .map(
                  (item) => VitalReading.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .whereType<VitalReading>(),
          );
        _readings.sort((a, b) => b.at.compareTo(a.at));
      }
    } catch (error) {
      debugPrint('Nie udało się wczytać pomiarów: $error');
    } finally {
      isLoaded = true;
      revision.value++;
    }
  }

  VitalReading? latest(VitalKind kind) {
    for (final reading in _readings) {
      if (reading.kind == kind) return reading;
    }
    return null;
  }

  List<VitalReading> readingsOf(VitalKind kind) =>
      _readings.where((item) => item.kind == kind).toList(growable: false);

  VitalReading? measurementForDay(VitalKind kind, DateTime date) {
    for (final item in _readings) {
      if (item.kind == kind && _sameDay(item.at, date)) return item;
    }
    return null;
  }

  int missingTodayCount([DateTime? date]) {
    final today = date ?? DateTime.now();
    return VitalKind.values
        .where((kind) => !hasMeasurementToday(kind, today))
        .length;
  }

  bool hasMeasurementToday(VitalKind kind, [DateTime? date]) {
    final today = date ?? DateTime.now();
    return _readings.any(
      (item) => item.kind == kind && _sameDay(item.at, today),
    );
  }

  Future<bool> addToday({
    required VitalKind kind,
    required double primary,
    double? secondary,
  }) async {
    await load();
    if (hasMeasurementToday(kind)) return false;
    final reading = VitalReading(
      kind: kind,
      at: DateTime.now(),
      primary: primary,
      secondary: secondary,
    );
    final updated = [reading, ..._readings];
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
    _readings
      ..clear()
      ..addAll(updated);
    revision.value++;
    return true;
  }

  static bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
