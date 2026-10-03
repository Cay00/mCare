import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:m_opiekun/services/heart_rate_store.dart';
import 'package:m_opiekun/services/health_pdf_export.dart';
import 'package:m_opiekun/widgets/care_components.dart';
import 'package:m_opiekun/widgets/prototype_page.dart';
import 'package:m_opiekun/widgets/section_card.dart';

/// Karta medyczna pacjenta i ręcznie wprowadzane pomiary.
class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  String _name = 'Maria Kowalska';
  String _bloodType = 'A Rh+';
  String _allergies = 'Penicylina';
  String _conditions = 'Nadciśnienie, cukrzyca typu 2';
  String _doctor = 'dr Anna Nowak';
  String _emergencyContact = 'Jan Kowalski, syn · 500 100 200';
  final _heartRateStore = HeartRateStore.instance;

  @override
  void initState() {
    super.initState();
    _heartRateStore.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _editPatientData() async {
    final data = await showModalBottomSheet<_PatientData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PatientDataForm(
        initial: _PatientData(
          name: _name,
          bloodType: _bloodType,
          allergies: _allergies,
          conditions: _conditions,
          doctor: _doctor,
          emergencyContact: _emergencyContact,
        ),
      ),
    );
    if (!mounted || data == null) return;
    setState(() {
      _name = data.name;
      _bloodType = data.bloodType;
      _allergies = data.allergies;
      _conditions = data.conditions;
      _doctor = data.doctor;
      _emergencyContact = data.emergencyContact;
    });
  }

  Future<void> _addReading() async {
    await _heartRateStore.load();
    if (_heartRateStore.hasMeasurementToday()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dzisiejszy pomiar tętna jest już zapisany.'),
        ),
      );
      return;
    }
    final pulse = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _HeartRateForm(),
    );
    if (!mounted || pulse == null) return;
    late final bool saved;
    try {
      saved = await _heartRateStore.addToday(pulse);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się zapisać pomiaru: $error')),
      );
      return;
    }
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Zapisano dzienny pomiar tętna.'
              : 'Dzisiejszy pomiar tętna jest już zapisany.',
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    try {
      final bytes = await HealthPdfExport.build(
        name: _name,
        bloodType: _bloodType,
        allergies: _allergies,
        conditions: _conditions,
        doctor: _doctor,
        emergencyContact: _emergencyContact,
        readings: _heartRateStore.measurements.map(_readingText).toList(),
      );
      final renderBox = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(bytes),
            mimeType: 'application/pdf',
          ),
        ],
        fileNameOverrides: const ['karta_medyczna.pdf'],
        sharePositionOrigin: renderBox == null
            ? null
            : renderBox.localToGlobal(Offset.zero) & renderBox.size,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się przygotować PDF: $error')),
      );
    }
  }

  String _readingText(HeartRateMeasurement reading) =>
      '${_formatDate(reading.at)} · Tętno: ${reading.pulse} uderzeń/min';

  @override
  Widget build(BuildContext context) {
    return PrototypePage(
      children: [
        const CareHeading(
          'Karta medyczna',
          subtitle: 'Najważniejsze informacje na wizytę i dla opiekuna.',
        ),
        SectionCard(
          title: 'Dane medyczne',
          icon: Icons.medical_information_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Fact(label: 'Osoba', value: _name),
              _Fact(label: 'Grupa krwi', value: _bloodType),
              _Fact(label: 'Alergie', value: _allergies),
              _Fact(label: 'Choroby', value: _conditions),
              _Fact(label: 'Lekarz prowadzący', value: _doctor),
              _Fact(
                label: 'Kontakt alarmowy',
                value: _emergencyContact,
                isLast: true,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _editPatientData,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edytuj dane pacjenta'),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: _heartRateStore.hasMeasurementToday() ? null : _addReading,
          icon: const Icon(Icons.monitor_heart_outlined),
          label: Text(
            _heartRateStore.hasMeasurementToday()
                ? 'Dzisiejsze tętno zapisane'
                : 'Dodaj dzienny pomiar tętna',
          ),
        ),
        if (_heartRateStore.measurements.isNotEmpty) ...[
          SectionCard(
            title: 'Tętno z ostatnich 7 dni',
            icon: Icons.show_chart,
            child: _HeartRateChart(measurements: _heartRateStore.measurements),
          ),
          SectionCard(
            title: 'Dzienne pomiary tętna',
            icon: Icons.monitor_heart_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _heartRateStore.measurements.length; i++)
                  _ReadingTile(
                    reading: _heartRateStore.measurements[i],
                    isLast: i == _heartRateStore.measurements.length - 1,
                  ),
              ],
            ),
          ),
        ],
        FilledButton.tonalIcon(
          onPressed: _exportPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Pobierz kartę i pomiary do PDF'),
        ),
        const SectionCard(
          title: 'Zalecenia',
          icon: Icons.favorite_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Advice(text: 'Mierz ciśnienie każdego ranka, przed lekami.'),
              _Advice(text: 'Metformax bierz w trakcie posiłku.'),
              _Advice(text: 'Pij około 1,5 litra wody dziennie.'),
              _Advice(text: 'Krótki spacer, jeśli ciśnienie jest w normie.'),
              _Advice(text: 'Ogranicz sól.', isLast: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _PatientData {
  const _PatientData({
    required this.name,
    required this.bloodType,
    required this.allergies,
    required this.conditions,
    required this.doctor,
    required this.emergencyContact,
  });

  final String name;
  final String bloodType;
  final String allergies;
  final String conditions;
  final String doctor;
  final String emergencyContact;
}

class _PatientDataForm extends StatefulWidget {
  const _PatientDataForm({required this.initial});
  final _PatientData initial;

  @override
  State<_PatientDataForm> createState() => _PatientDataFormState();
}

class _PatientDataFormState extends State<_PatientDataForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial.name);
  late final _bloodType = TextEditingController(text: widget.initial.bloodType);
  late final _allergies = TextEditingController(text: widget.initial.allergies);
  late final _conditions = TextEditingController(
    text: widget.initial.conditions,
  );
  late final _doctor = TextEditingController(text: widget.initial.doctor);
  late final _contact = TextEditingController(
    text: widget.initial.emergencyContact,
  );

  @override
  void dispose() {
    _name.dispose();
    _bloodType.dispose();
    _allergies.dispose();
    _conditions.dispose();
    _doctor.dispose();
    _contact.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dane pacjenta',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _field(_name, 'Imię i nazwisko'),
            _field(_bloodType, 'Grupa krwi'),
            _field(_allergies, 'Alergie'),
            _field(_conditions, 'Choroby i schorzenia'),
            _field(_doctor, 'Lekarz prowadzący'),
            _field(_contact, 'Kontakt alarmowy'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(
                  context,
                  _PatientData(
                    name: _name.text.trim(),
                    bloodType: _bloodType.text.trim(),
                    allergies: _allergies.text.trim(),
                    conditions: _conditions.text.trim(),
                    doctor: _doctor.text.trim(),
                    emergencyContact: _contact.text.trim(),
                  ),
                );
              },
              child: const Text('Zapisz dane'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HeartRateForm extends StatefulWidget {
  const _HeartRateForm();

  @override
  State<_HeartRateForm> createState() => _HeartRateFormState();
}

class _HeartRateFormState extends State<_HeartRateForm> {
  final _formKey = GlobalKey<FormState>();
  final _pulse = TextEditingController();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String? _validPulse(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null || number < 30 || number > 220) {
      return 'Podaj tętno w zakresie 30–220 uderzeń/min.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dzienny pomiar tętna',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Wpisz tętno spoczynkowe zmierzone dzisiaj.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pulse,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tętno (uderzenia/min)',
                border: OutlineInputBorder(),
              ),
              validator: _validPulse,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(context, int.parse(_pulse.text.trim()));
              },
              child: const Text('Zapisz pomiar'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({required this.reading, required this.isLast});
  final HeartRateMeasurement reading;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final timestamp = _formatDate(reading.at);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(timestamp, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            '${reading.pulse} uderzeń/min',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _HeartRateChart extends StatelessWidget {
  const _HeartRateChart({required this.measurements});

  final List<HeartRateMeasurement> measurements;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (index) {
      final date = DateTime(now.year, now.month, now.day - (6 - index));
      return (date: date, measurement: _measurementOn(date));
    });
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          height: 170,
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
                          day.measurement == null
                              ? '–'
                              : '${day.measurement!.pulse}',
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: day.measurement == null
                              ? 4
                              : (day.measurement!.pulse / 220 * 118)
                                    .clamp(14, 118)
                                    .toDouble(),
                          decoration: BoxDecoration(
                            color: day.measurement == null
                                ? theme.colorScheme.outlineVariant
                                : theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
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
          'Uderzenia na minutę · brak słupka oznacza brak pomiaru',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  HeartRateMeasurement? _measurementOn(DateTime date) {
    for (final measurement in measurements) {
      if (measurement.at.year == date.year &&
          measurement.at.month == date.month &&
          measurement.at.day == date.day) {
        return measurement;
      }
    }
    return null;
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}, '
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

Widget _field(TextEditingController controller, String label) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextFormField(
    controller: controller,
    textCapitalization: TextCapitalization.sentences,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: (value) => value == null || value.trim().isEmpty
        ? 'Uzupełnij pole: $label.'
        : null,
  ),
);

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.isLast = false});
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Advice extends StatelessWidget {
  const _Advice({required this.text, this.isLast = false});
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(
              Icons.circle,
              size: 8,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
