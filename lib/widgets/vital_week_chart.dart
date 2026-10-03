import 'package:flutter/material.dart';

import 'package:m_opiekun/services/vital_store.dart';
import 'package:m_opiekun/theme/app_theme.dart';

/// Słupkowy wykres ostatnich 7 dni dla jednego rodzaju pomiaru.
class VitalWeekChart extends StatelessWidget {
  const VitalWeekChart({super.key, required this.kind, required this.readings});

  final VitalKind kind;
  final List<VitalReading> readings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final days = List.generate(7, (index) {
      final date = DateTime(now.year, now.month, now.day - (6 - index));
      return (date: date, reading: _onDay(date));
    });
    final scale = _scale(
      days.map((day) => day.reading).whereType<VitalReading>(),
    );
    final pressure = kind == VitalKind.bloodPressure;

    return Column(
      children: [
        SizedBox(
          height: pressure ? 190 : 170,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final day in days)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _topLabel(day.reading),
                          style: theme.textTheme.labelSmall,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                        ),
                        const SizedBox(height: 6),
                        if (pressure)
                          _PressureBars(reading: day.reading, scale: scale)
                        else
                          _Bar(
                            height: day.reading == null
                                ? 4
                                : _height(day.reading!.primary, scale),
                            color: day.reading == null
                                ? theme.colorScheme.outlineVariant
                                : theme.colorScheme.primary,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          '${day.date.day}.${day.date.month}',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          pressure
              ? 'Skurczowe / rozkurczowe · ${kind.unit}'
              : '${kind.unit} · brak słupka oznacza brak pomiaru',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        if (pressure) ...[
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              _Legend(color: theme.colorScheme.primary, label: 'Skurczowe'),
              _Legend(
                color: CareColors.soft,
                label: 'Rozkurczowe',
                outlined: true,
              ),
            ],
          ),
        ],
      ],
    );
  }

  VitalReading? _onDay(DateTime date) {
    for (final reading in readings) {
      if (reading.at.year == date.year &&
          reading.at.month == date.month &&
          reading.at.day == date.day) {
        return reading;
      }
    }
    return null;
  }

  String _topLabel(VitalReading? reading) {
    if (reading == null) return '–';
    if (kind == VitalKind.bloodPressure) {
      return '${reading.primary.round()}\n${reading.secondary?.round() ?? 0}';
    }
    return formatVitalNumber(reading.primary, decimal: kind.usesDecimal);
  }

  (double min, double max) _scale(Iterable<VitalReading> present) {
    final defaults = switch (kind) {
      VitalKind.glucose => (60.0, 180.0),
      VitalKind.bloodPressure => (40.0, 180.0),
      VitalKind.weight => (50.0, 100.0),
      VitalKind.temperature => (35.0, 39.0),
      VitalKind.saturation => (90.0, 100.0),
    };
    if (present.isEmpty) return defaults;
    final values = <double>[
      for (final reading in present) ...[
        reading.primary,
        if (reading.secondary != null) reading.secondary!,
      ],
    ];
    var min = values.reduce((a, b) => a < b ? a : b);
    var max = values.reduce((a, b) => a > b ? a : b);
    if ((max - min).abs() < 1) {
      min -= 1;
      max += 1;
    }
    final pad = (max - min) * 0.15;
    return (min - pad, max + pad);
  }

  static double _height(double value, (double min, double max) scale) {
    final span = (scale.$2 - scale.$1).clamp(1, double.infinity);
    return ((value - scale.$1) / span * 118).clamp(14, 118).toDouble();
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
      border: color == CareColors.soft
          ? Border.all(color: CareColors.primary.withValues(alpha: 0.35))
          : null,
    ),
  );
}

class _PressureBars extends StatelessWidget {
  const _PressureBars({required this.reading, required this.scale});

  final VitalReading? reading;
  final (double min, double max) scale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (reading == null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _Bar(height: 4, color: theme.colorScheme.outlineVariant),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: _Bar(height: 4, color: theme.colorScheme.outlineVariant),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _Bar(
            height: VitalWeekChart._height(reading!.primary, scale),
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: _Bar(
            height: VitalWeekChart._height(reading!.secondary ?? 0, scale),
            color: CareColors.soft,
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    this.outlined = false,
  });

  final Color color;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: outlined
              ? Border.all(color: CareColors.primary.withValues(alpha: 0.35))
              : null,
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
