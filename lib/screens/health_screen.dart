import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:m_opiekun/services/health_pdf_export.dart';
import 'package:m_opiekun/services/vital_store.dart';
import 'package:m_opiekun/widgets/care_components.dart';
import 'package:m_opiekun/widgets/prototype_page.dart';
import 'package:m_opiekun/screens/measurement_history_screen.dart';
import 'package:m_opiekun/screens/vital_detail_screen.dart';
import 'package:m_opiekun/widgets/section_card.dart';
import 'package:m_opiekun/widgets/vital_measurement_grid.dart';

/// Karta medyczna, pomiary i terminy wizyt.
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
  final _vitalStore = VitalStore.instance;

  @override
  void initState() {
    super.initState();
    _vitalStore.load();
  }

  void _openVital(VitalKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => VitalDetailScreen(kind: kind)),
    );
  }

  Future<void> _editPatientData() async {
    final data = await Navigator.of(context).push<_PatientData>(
      MaterialPageRoute(
        builder: (_) => _PatientDataPage(
          initial: _PatientData(
            name: _name,
            bloodType: _bloodType,
            allergies: _allergies,
            conditions: _conditions,
            doctor: _doctor,
            emergencyContact: _emergencyContact,
          ),
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

  Future<void> _exportPdf() async {
    try {
      final bytes = await HealthPdfExport.build(
        name: _name,
        bloodType: _bloodType,
        allergies: _allergies,
        conditions: _conditions,
        doctor: _doctor,
        emergencyContact: _emergencyContact,
        readings: _vitalStore.readings.map(_vitalText).toList(),
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

  String _vitalText(VitalReading reading) =>
      '${_formatDate(reading.at)} · ${reading.kind.label}: ${formatVitalValue(reading)}';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vitalStore.revision,
      builder: (context, _) => PrototypePage(
        children: [
          const CareHeading(
            'Karta medyczna',
            subtitle: 'Najważniejsze informacje na wizytę i dla opiekuna.',
          ),
          _MedicalCard(
            name: _name,
            bloodType: _bloodType,
            allergies: _allergies,
            conditions: _conditions,
            doctor: _doctor,
            emergencyContact: _emergencyContact,
            onEdit: _editPatientData,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pomiary', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Najnowsze, aby zobaczyć wykres.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              VitalMeasurementGrid(vitals: _vitalStore, onVital: _openVital),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MeasurementHistoryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('Historia pomiarów'),
                ),
              ),
            ],
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
          const CareHeading(
            'Wizyty',
            subtitle: 'Przykładowe terminy i przypomnienia.',
          ),
          const _VisitCard(
            day: '4',
            month: 'paź',
            title: 'dr Anna Nowak',
            details: 'Kardiolog · Przychodnia Lipowa',
            time: '10:30',
            reminder: 'Przypomnienie: dzień wcześniej i 2 godziny przed',
          ),
          const _VisitCard(
            day: '12',
            month: 'paź',
            title: 'Badanie krwi',
            details: 'Laboratorium · na czczo',
            time: '09:00',
            reminder: 'Przypomnienie: wieczór wcześniej',
          ),
          Text('Historia', style: Theme.of(context).textTheme.titleLarge),
          const _VisitCard(
            day: '12',
            month: 'wrz',
            title: 'Kontrola ciśnienia',
            details: 'dr Anna Nowak · odbyta',
            time: '11:00',
            reminder: 'Bez kolejnego przypomnienia',
            muted: true,
          ),
          FilledButton.icon(
            onPressed: () => showPrototypeHint(context, 'Dodawanie wizyty'),
            icon: const Icon(Icons.add),
            label: const Text('Dodaj wizytę'),
          ),
        ],
      ),
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

class _PatientDataPage extends StatefulWidget {
  const _PatientDataPage({required this.initial});
  final _PatientData initial;

  @override
  State<_PatientDataPage> createState() => _PatientDataPageState();
}

class _PatientDataPageState extends State<_PatientDataPage> {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: careAppBar(context, 'Edytuj dane pacjenta'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
}

class _MedicalCard extends StatelessWidget {
  const _MedicalCard({
    required this.name,
    required this.bloodType,
    required this.allergies,
    required this.conditions,
    required this.doctor,
    required this.emergencyContact,
    required this.onEdit,
  });

  final String name;
  final String bloodType;
  final String allergies;
  final String conditions;
  final String doctor;
  final String emergencyContact;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final edit = TextButton(
      onPressed: onEdit,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      ),
      child: const Text('Edytuj dane pacjenta'),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text('Dane medyczne', style: theme.textTheme.titleMedium),
                edit,
              ],
            ),
            const SizedBox(height: 8),
            _Fact(label: 'Osoba', value: name),
            _Fact(label: 'Grupa krwi', value: bloodType),
            _Fact(label: 'Alergie', value: allergies),
            _Fact(label: 'Choroby', value: conditions),
            _Fact(label: 'Lekarz prowadzący', value: doctor),
            _Fact(
              label: 'Kontakt alarmowy',
              value: emergencyContact,
              isLast: true,
            ),
          ],
        ),
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
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.day,
    required this.month,
    required this.title,
    required this.details,
    required this.time,
    required this.reminder,
    this.muted = false,
  });

  final String day;
  final String month;
  final String title;
  final String details;
  final String time;
  final String reminder;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$day $month · $time',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              details,
              style: theme.textTheme.bodyMedium?.copyWith(color: mutedColor),
            ),
            const SizedBox(height: 10),
            Text(
              reminder,
              style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
            ),
            if (muted)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Wizyta odbyta',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: mutedColor,
                  ),
                ),
              ),
          ],
        ),
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
