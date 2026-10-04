import 'package:flutter/material.dart';

import 'package:m_opiekun/services/vital_store.dart';
import 'package:m_opiekun/theme/app_theme.dart';
import 'package:m_opiekun/widgets/care_components.dart';

class MeasurementHistoryScreen extends StatelessWidget {
  const MeasurementHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = VitalStore.instance;
    return Scaffold(
      appBar: careAppBar(context, 'Historia pomiarów'),
      body: ListenableBuilder(
        listenable: store.revision,
        builder: (context, _) {
          final groups = store.readings.isEmpty
              ? _sampleGroups()
              : _groupsFrom(store.readings);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              for (final group in groups) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Text(
                    group.dateLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: CareColors.muted,
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        for (var i = 0; i < group.rows.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                          ListTile(
                            dense: true,
                            title: Text(group.rows[i].time),
                            subtitle: Text(group.rows[i].label),
                            trailing: Text(
                              group.rows[i].value,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(color: CareColors.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              if (store.readings.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Podgląd zawiera dane przykładowe.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: CareColors.muted,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryGroup {
  const _HistoryGroup({required this.dateLabel, required this.rows});

  final String dateLabel;
  final List<_HistoryRow> rows;
}

class _HistoryRow {
  const _HistoryRow({
    required this.time,
    required this.label,
    required this.value,
  });

  final String time;
  final String label;
  final String value;
}

List<_HistoryGroup> _groupsFrom(List<VitalReading> readings) {
  final groups = <String, List<_HistoryRow>>{};
  final order = <String>[];
  for (final reading in readings) {
    final key = _dateLabel(reading.at);
    if (!groups.containsKey(key)) {
      groups[key] = [];
      order.add(key);
    }
    final time =
        '${reading.at.hour.toString().padLeft(2, '0')}:${reading.at.minute.toString().padLeft(2, '0')}';
    groups[key]!.add(
      _HistoryRow(
        time: time,
        label: reading.kind.label,
        value: formatVitalValue(reading),
      ),
    );
  }
  return [
    for (final key in order) _HistoryGroup(dateLabel: key, rows: groups[key]!),
  ];
}

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

List<_HistoryGroup> _sampleGroups() => const [
  _HistoryGroup(
    dateLabel: '20.05.2024',
    rows: [
      _HistoryRow(time: '08:16', label: 'Poziom cukru', value: '120 mg/dl'),
      _HistoryRow(time: '08:16', label: 'Ciśnienie', value: '120/80 mmHg'),
      _HistoryRow(time: '08:17', label: 'Waga', value: '68,5 kg'),
    ],
  ),
  _HistoryGroup(
    dateLabel: '19.05.2024',
    rows: [
      _HistoryRow(time: '08:15', label: 'Poziom cukru', value: '118 mg/dl'),
      _HistoryRow(time: '08:15', label: 'Ciśnienie', value: '118/76 mmHg'),
      _HistoryRow(time: '08:13', label: 'Waga', value: '68,7 kg'),
    ],
  ),
  _HistoryGroup(
    dateLabel: '18.05.2024',
    rows: [
      _HistoryRow(time: '08:20', label: 'Poziom cukru', value: '122 mg/dl'),
    ],
  ),
];
