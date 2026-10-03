import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'package:m_opiekun/services/health_pdf_export.dart';
import 'package:m_opiekun/widgets/care_components.dart';
import 'package:flutter/material.dart';

import 'package:m_opiekun/widgets/prototype_page.dart';
import 'package:m_opiekun/widgets/section_card.dart';

/// Zdrowie: dane medyczne, zalecenia i eksport PDF.
///
/// Do zbudowania: edycja karty, lista zaleceń od lekarza oraz
/// generowanie jednego PDF z tych informacji. Przycisk nic nie eksportuje.
class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrototypePage(
      children: [
        const CareHeading(
          'Karta medyczna',
          subtitle: 'Najważniejsze informacje na wizytę i dla opiekuna.',
        ),
        const CareNotice(
          'Dane i zalecenia poniżej są przykładowe. Eksport PDF jest w przygotowaniu.',
        ),
        const SectionCard(
          title: 'Dane medyczne',
          icon: Icons.medical_information_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Fact(label: 'Osoba', value: 'Maria Kowalska'),
              _Fact(label: 'Grupa krwi', value: 'A Rh+'),
              _Fact(label: 'Alergie', value: 'Penicylina'),
              _Fact(label: 'Choroby', value: 'Nadciśnienie, cukrzyca typu 2'),
              _Fact(label: 'Lekarz prowadzący', value: 'dr Anna Nowak'),
              _Fact(
                label: 'Kontakt alarmowy',
                value: 'Jan Kowalski, syn · 500 100 200',
                isLast: true,
              ),
            ],
          ),
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
        FilledButton.icon(
          onPressed: () => showPrototypeHint(context, 'Eksport karty do PDF'),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Eksportuj kartę do PDF'),
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
