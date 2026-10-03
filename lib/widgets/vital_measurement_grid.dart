import 'package:flutter/material.dart';

import 'package:m_opiekun/services/vital_store.dart';
import 'package:m_opiekun/theme/app_theme.dart';

class VitalMeasurementGrid extends StatelessWidget {
  const VitalMeasurementGrid({
    super.key,
    required this.vitals,
    required this.onVital,
  });

  final VitalStore vitals;
  final ValueChanged<VitalKind> onVital;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      for (final kind in VitalKind.values)
        _MeasurementTile(
          tileKey: Key('vital-tile-${kind.name}'),
          label: kind.label,
          icon: _icon(kind),
          value: _value(vitals.latest(kind)),
          unit: kind.unit,
          when: vitals.latest(kind)?.at,
          onTap: () => onVital(kind),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final columns = constraints.maxWidth / scale < 300 ? 1 : 2;
        final rows = <Widget>[];
        for (var index = 0; index < tiles.length; index += columns) {
          if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column > 0) const SizedBox(width: 12),
                    Expanded(
                      child: index + column < tiles.length
                          ? tiles[index + column]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }

  static IconData _icon(VitalKind kind) => switch (kind) {
    VitalKind.glucose => Icons.water_drop_outlined,
    VitalKind.bloodPressure => Icons.speed_outlined,
    VitalKind.weight => Icons.monitor_weight_outlined,
    VitalKind.temperature => Icons.thermostat_outlined,
    VitalKind.saturation => Icons.air_outlined,
  };

  static String? _value(VitalReading? reading) {
    if (reading == null) return null;
    if (reading.kind == VitalKind.bloodPressure) {
      return '${reading.primary.round()}/${reading.secondary?.round() ?? 0}';
    }
    return formatVitalNumber(
      reading.primary,
      decimal: reading.kind.usesDecimal,
    );
  }
}

class _MeasurementTile extends StatelessWidget {
  const _MeasurementTile({
    required this.tileKey,
    required this.label,
    required this.icon,
    required this.value,
    required this.unit,
    required this.when,
    required this.onTap,
  });

  final Key tileKey;
  final String label;
  final IconData icon;
  final String? value;
  final String unit;
  final DateTime? when;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recorded = value != null;
    final whenLabel = recorded ? _whenLabel(when!) : 'Zobacz wykres';
    final spoken = recorded
        ? '$label, $value $unit, $whenLabel'
        : '$label, brak pomiaru. Zobacz wykres';

    return Semantics(
      button: true,
      label: spoken,
      child: Card(
        key: tileKey,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CareColors.soft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: CareColors.primary, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(label, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    recorded ? value! : '—',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: recorded ? CareColors.ink : CareColors.muted,
                    ),
                  ),
                  Text(
                    unit,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: CareColors.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    whenLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: CareColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _whenLabel(DateTime at) {
    final now = DateTime.now();
    if (at.year == now.year && at.month == now.month && at.day == now.day) {
      return 'dziś';
    }
    return '${at.day.toString().padLeft(2, '0')}.${at.month.toString().padLeft(2, '0')}';
  }
}
