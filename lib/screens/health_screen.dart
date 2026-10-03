import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

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
  final List<_HealthReading> _readings = [];

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
    final reading = await showModalBottomSheet<_HealthReading>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ReadingForm(),
    );
    if (!mounted || reading == null) return;
    setState(() {
      if (reading.conditions.isNotEmpty) _conditions = reading.conditions;
      _readings.insert(0, reading);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Zapisano dane zdrowotne.')));
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
        readings: _readings.map(_readingText).toList(),
      );
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: 'karta_medyczna.pdf',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się przygotować PDF: $error')),
      );
    }
  }

  String _readingText(_HealthReading reading) {
    final values = <String>[
      if (reading.conditions.isNotEmpty) 'Choroba: ${reading.conditions}',
      if (reading.pulse != null) 'Tętno: ${reading.pulse} uderzeń/min',
      if (reading.glucose != null) 'Poziom cukru: ${reading.glucose} mg/dl',
    ];
    return '${_formatDate(reading.at)} · ${values.join(' · ')}';
  }

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
          onPressed: _addReading,
          icon: const Icon(Icons.add),
          label: const Text('Dodaj pomiar'),
        ),
        if (_readings.isNotEmpty)
          SectionCard(
            title: 'Pomiary i wpisy zdrowotne',
            icon: Icons.monitor_heart_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _readings.length; i++)
                  _ReadingTile(
                    reading: _readings[i],
                    isLast: i == _readings.length - 1,
                  ),
              ],
            ),
          ),
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

class _HealthReading {
  const _HealthReading({
    required this.conditions,
    required this.pulse,
    required this.glucose,
    required this.at,
  });

  final String conditions;
  final int? pulse;
  final int? glucose;
  final DateTime at;
}

class _ReadingForm extends StatefulWidget {
  const _ReadingForm();

  @override
  State<_ReadingForm> createState() => _ReadingFormState();
}

class _ReadingFormState extends State<_ReadingForm> {
  final _formKey = GlobalKey<FormState>();
  final _conditions = TextEditingController();
  final _pulse = TextEditingController();
  final _glucose = TextEditingController();

  @override
  void dispose() {
    _conditions.dispose();
    _pulse.dispose();
    _glucose.dispose();
    super.dispose();
  }

  String? _positiveNumber(String? value, String label) {
    if (value == null || value.trim().isEmpty) return null;
    final number = int.tryParse(value.trim());
    if (number == null || number <= 0) return 'Podaj poprawną wartość: $label.';
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
              'Nowy wpis zdrowotny',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Wpisz cukrzycę lub inną chorobę, tętno i poziom cukru.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _conditions,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Choroba (np. cukrzyca typu 2)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pulse,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tętno (uderzenia/min)',
                border: OutlineInputBorder(),
              ),
              validator: (value) => _positiveNumber(value, 'tętno'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _glucose,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Poziom cukru (mg/dl)',
                border: OutlineInputBorder(),
              ),
              validator: (value) => _positiveNumber(value, 'poziom cukru'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(
                  context,
                  _HealthReading(
                    conditions: _conditions.text.trim(),
                    pulse: int.tryParse(_pulse.text.trim()),
                    glucose: int.tryParse(_glucose.text.trim()),
                    at: DateTime.now(),
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

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({required this.reading, required this.isLast});
  final _HealthReading reading;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final values = <String>[
      if (reading.conditions.isNotEmpty) 'Choroba: ${reading.conditions}',
      if (reading.pulse != null) 'Tętno: ${reading.pulse} uderzeń/min',
      if (reading.glucose != null) 'Cukier: ${reading.glucose} mg/dl',
    ];
    final timestamp = _formatDate(reading.at);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(timestamp, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            values.join(' · '),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
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
