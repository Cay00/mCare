import 'package:flutter/material.dart';

import 'package:m_opiekun/services/vital_store.dart';
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

class _VitalDetailScreenState extends State<VitalDetailScreen> {
  final _vitalStore = VitalStore.instance;

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
      appBar: careAppBar(context, kind.label),
      body: ListenableBuilder(
        listenable: _vitalStore.revision,
        builder: (context, _) {
          final readings = _vitalStore.readingsOf(kind);
          return PrototypePage(
            children: [
              CareHeading(
                'Ostatnie 7 dni',
                subtitle: 'Jeden słupek odpowiada jednemu dniu.',
              ),
              SectionCard(
                title: kind.label,
                icon: Icons.show_chart,
                child: VitalWeekChart(kind: kind, readings: readings),
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
          Text(stamp, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            formatVitalValue(reading),
            style: Theme.of(context).textTheme.bodyLarge,
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
