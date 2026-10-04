import 'package:flutter/material.dart';

import 'package:m_opiekun/services/vital_store.dart';
import 'package:m_opiekun/theme/app_theme.dart';
import 'package:m_opiekun/widgets/care_components.dart';
import 'package:m_opiekun/widgets/prototype_page.dart';
import 'package:m_opiekun/widgets/section_card.dart';
import 'package:m_opiekun/widgets/vital_week_chart.dart';

/// Wykres i zapis dzisiejszego pomiaru dla jednego rodzaju wyniku.
class VitalDetailScreen extends StatefulWidget {
  const VitalDetailScreen({super.key, required this.kind});

  final VitalKind kind;

  @override
  State<VitalDetailScreen> createState() => _VitalDetailScreenState();
}

enum _ChartRange { day, week, month }

class _VitalDetailScreenState extends State<VitalDetailScreen> {
  final _vitalStore = VitalStore.instance;
  _ChartRange _range = _ChartRange.week;

  @override
  void initState() {
    super.initState();
    _vitalStore.load();
  }

  Future<void> _addVital() async {
    final kind = widget.kind;
    if (_vitalStore.hasMeasurementToday(kind)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dzisiejszy pomiar (${kind.label}) jest już zapisany.'),
        ),
      );
      return;
    }
    final result = await showModalBottomSheet<_VitalDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _VitalForm(kind: kind),
    );
    if (!mounted || result == null) return;
    late final bool saved;
    try {
      saved = await _vitalStore.addToday(
        kind: kind,
        primary: result.primary,
        secondary: result.secondary,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się zapisać pomiaru: $error')),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Zapisano dzienny pomiar: ${kind.label}.'
              : 'Dzisiejszy pomiar (${kind.label}) jest już zapisany.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    return Scaffold(
      appBar: careAppBar(
        context,
        kind.label,
        actions: [
          IconButton(
            tooltip: 'Dodaj pomiar',
            onPressed: _addVital,
            icon: const Icon(Icons.calendar_today_outlined),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _vitalStore.revision,
        builder: (context, _) {
          final readings = _vitalStore.readingsOf(kind);
          final latest = _vitalStore.latest(kind);
          return PrototypePage(
            children: [
              _RangeSelector(
                range: _range,
                onChanged: (range) => setState(() => _range = range),
              ),
              _VitalHero(kind: kind, latest: latest),
              if (_range == _ChartRange.week)
                SectionCard(
                  title: 'Ostatnie 7 dni',
                  icon: Icons.show_chart,
                  child: VitalWeekChart(kind: kind, readings: readings),
                )
              else if (_range == _ChartRange.day)
                CareNotice(
                  _vitalStore.hasMeasurementToday(kind)
                      ? 'Dzisiejszy pomiar jest zapisany.'
                      : 'Brak pomiaru na dziś. Zapisz wynik przyciskiem na dole.',
                )
              else
                CareNotice(
                  readings.isEmpty
                      ? 'Brak zapisanych pomiarów w tym miesiącu.'
                      : 'Zapisane wyniki: ${readings.length}.',
                ),
              if (readings.isNotEmpty)
                SectionCard(
                  title: 'Zapisane pomiary',
                  icon: Icons.history,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < readings.length; i++)
                        _ReadingLine(
                          reading: readings[i],
                          isLast: i == readings.length - 1,
                        ),
                    ],
                  ),
                ),
              FilledButton.icon(
                onPressed: _addVital,
                icon: const Icon(Icons.add),
                label: const Text('Zapisz dzisiejszy pomiar'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.range, required this.onChanged});

  final _ChartRange range;
  final ValueChanged<_ChartRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in _ChartRange.values) ...[
            if (item != _ChartRange.day) const SizedBox(width: 8),
            ChoiceChip(
              label: Text(switch (item) {
                _ChartRange.day => 'Dzień',
                _ChartRange.week => 'Tydzień',
                _ChartRange.month => 'Miesiąc',
              }),
              selected: range == item,
              showCheckmark: false,
              onSelected: (_) => onChanged(item),
              selectedColor: CareColors.primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: range == item ? Colors.white : CareColors.ink,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: range == item ? CareColors.primary : CareColors.line,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VitalHero extends StatelessWidget {
  const _VitalHero({required this.kind, required this.latest});

  final VitalKind kind;
  final VitalReading? latest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = latest == null
        ? _preview(kind)
        : kind == VitalKind.bloodPressure
        ? '${latest!.primary.round()}/${latest!.secondary?.round() ?? 0}'
        : formatVitalNumber(latest!.primary, decimal: kind.usesDecimal);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineLarge?.copyWith(
            color: CareColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          _reference(kind),
          style: theme.textTheme.titleMedium?.copyWith(color: CareColors.ink),
        ),
      ],
    );
  }

  static String _preview(VitalKind kind) => switch (kind) {
    VitalKind.glucose => '118',
    VitalKind.bloodPressure => '120/80',
    VitalKind.weight => '68,5',
    VitalKind.temperature => '36,6',
    VitalKind.saturation => '98',
  };

  static String _reference(VitalKind kind) => switch (kind) {
    VitalKind.glucose => '80 – 160',
    VitalKind.bloodPressure => '90 – 140',
    VitalKind.weight => 'kontrola',
    VitalKind.temperature => '36,0 – 37,5',
    VitalKind.saturation => '95 – 100',
  };
}

class _ReadingLine extends StatelessWidget {
  const _ReadingLine({required this.reading, required this.isLast});

  final VitalReading reading;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final date = reading.at;
    final stamp =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stamp,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatVitalValue(reading),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _VitalDraft {
  const _VitalDraft({required this.primary, this.secondary});

  final double primary;
  final double? secondary;
}

class _VitalForm extends StatefulWidget {
  const _VitalForm({required this.kind});

  final VitalKind kind;

  @override
  State<_VitalForm> createState() => _VitalFormState();
}

class _VitalFormState extends State<_VitalForm> {
  final _formKey = GlobalKey<FormState>();
  final _primary = TextEditingController();
  final _secondary = TextEditingController();

  @override
  void dispose() {
    _primary.dispose();
    _secondary.dispose();
    super.dispose();
  }

  double _number(String value) =>
      double.parse(value.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final pressure = kind == VitalKind.bloodPressure;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(kind.label, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(kind.entryHint),
              const SizedBox(height: 16),
              TextFormField(
                key: Key('vital-primary-${kind.name}'),
                controller: _primary,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: kind.usesDecimal,
                ),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: pressure
                      ? 'Skurczowe (mmHg)'
                      : '${kind.label} (${kind.unit})',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => validateVitalPrimary(kind, value),
              ),
              if (pressure) ...[
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('vital-diastolic'),
                  controller: _secondary,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Rozkurczowe (mmHg)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => validateDiastolic(_primary.text, value),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.pop(
                    context,
                    _VitalDraft(
                      primary: _number(_primary.text),
                      secondary: pressure ? _number(_secondary.text) : null,
                    ),
                  );
                },
                child: const Text('Zapisz pomiar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
