import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:m_opiekun/screens/health_card_pdf_screen.dart';
import 'package:m_opiekun/services/health_card_pdf.dart';
import 'package:m_opiekun/widgets/prototype_page.dart';
import 'package:m_opiekun/widgets/section_card.dart';
import 'package:m_opiekun/widgets/status_pill.dart';

const _patientName = 'Maria Kowalska';

const _medicalFacts = [
  HealthPdfFact(label: 'Osoba', value: _patientName),
  HealthPdfFact(label: 'Grupa krwi', value: 'A Rh+'),
  HealthPdfFact(label: 'Alergie', value: 'Penicylina'),
  HealthPdfFact(label: 'Choroby', value: 'Nadciśnienie, cukrzyca typu 2'),
  HealthPdfFact(label: 'Lekarz prowadzący', value: 'dr Anna Nowak'),
  HealthPdfFact(
    label: 'Kontakt alarmowy',
    value: 'Jan Kowalski, syn · 500 100 200',
  ),
];

const _advice = [
  'Mierz ciśnienie każdego ranka, przed lekami.',
  'Metformax bierz w trakcie posiłku.',
  'Pij około 1,5 litra wody dziennie.',
  'Krótki spacer, jeśli ciśnienie jest w normie.',
  'Ogranicz sól.',
];

enum GlucoseContext { fasting, afterMeal, other }
enum VitalKind { glucose, pressure, pulse }

/// Zdrowie: pomiary (cukier, ciśnienie, tętno), karta medyczna i zalecenia.
class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final List<_VitalReading> _readings = [
    _VitalReading.glucose(
      at: DateTime(2026, 10, 3, 8, 10),
      mgDl: 118,
      context: GlucoseContext.fasting,
    ),
    _VitalReading.pressure(
      at: DateTime(2026, 10, 3, 8, 5),
      systolic: 132,
      diastolic: 78,
    ),
    _VitalReading.pulse(at: DateTime(2026, 10, 3, 8, 5), bpm: 72),
    _VitalReading.glucose(
      at: DateTime(2026, 10, 2, 19, 40),
      mgDl: 142,
      context: GlucoseContext.afterMeal,
    ),
    _VitalReading.glucose(
      at: DateTime(2026, 10, 1, 8, 15),
      mgDl: 109,
      context: GlucoseContext.fasting,
    ),
  ];

  _VitalReading? _latest(VitalKind kind) {
    final matches = _readings.where((r) => r.kind == kind);
    if (matches.isEmpty) return null;
    return matches.reduce((a, b) => a.at.isAfter(b.at) ? a : b);
  }

  Future<void> _addReading() async {
    final reading = await showModalBottomSheet<_VitalReading>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddReadingSheet(),
    );
    if (!mounted || reading == null) return;
    setState(() => _readings.insert(0, reading));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Zapisano pomiar: ${reading.headline}')),
    );
  }

  HealthCardPdfData _pdfData() {
    HealthPdfVital? vital(VitalKind kind, String label) {
      final reading = _latest(kind);
      if (reading == null) return null;
      return HealthPdfVital(
        label: label,
        value: reading.headline,
        detail: kind == VitalKind.glucose
            ? '${reading.contextLabel} · ${_formatWhen(reading.at)}'
            : _formatWhen(reading.at),
        status: reading.statusLabel,
      );
    }

    final history =
        (_readings.where((r) => r.kind == VitalKind.glucose).toList()
              ..sort((a, b) => b.at.compareTo(a.at)))
            .take(6)
            .map(
              (reading) => HealthPdfVital(
                label: 'Cukier',
                value: reading.headline,
                detail: '${reading.contextLabel} · ${_formatWhen(reading.at)}',
                status: reading.statusLabel,
              ),
            )
            .toList();

    return HealthCardPdfData(
      patientName: _patientName,
      generatedAt: DateTime.now(),
      latest: [
        ?vital(VitalKind.glucose, 'Poziom cukru'),
        ?vital(VitalKind.pressure, 'Ciśnienie krwi'),
        ?vital(VitalKind.pulse, 'Tętno'),
      ],
      glucoseHistory: history,
      medicalFacts: _medicalFacts,
      advice: _advice,
    );
  }

  Future<void> _exportPdf() async {
    final data = _pdfData();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HealthCardPdfScreen(data: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glucose = _latest(VitalKind.glucose);
    final pressure = _latest(VitalKind.pressure);
    final pulse = _latest(VitalKind.pulse);
    final glucoseHistory =
        (_readings.where((r) => r.kind == VitalKind.glucose).toList()
              ..sort((a, b) => b.at.compareTo(a.at)))
            .take(6)
            .toList();

    return PrototypePage(
      lead:
          'Karta medyczna, aktualne pomiary — poziom cukru, ciśnienie i tętno — '
          'oraz zalecenia do wizyty albo dla opiekuna.',
      children: [
        Text('Ostatnie pomiary', style: Theme.of(context).textTheme.titleLarge),
        if (glucose != null)
          _VitalTile(
            icon: Icons.water_drop_outlined,
            label: 'Poziom cukru',
            value: glucose.headline,
            detail: '${glucose.contextLabel} · ${_formatWhen(glucose.at)}',
            tone: glucose.statusTone,
            status: glucose.statusLabel,
          ),
        if (pressure != null)
          _VitalTile(
            icon: Icons.favorite_outline,
            label: 'Ciśnienie krwi',
            value: pressure.headline,
            detail: _formatWhen(pressure.at),
            tone: pressure.statusTone,
            status: pressure.statusLabel,
          ),
        if (pulse != null)
          _VitalTile(
            icon: Icons.monitor_heart_outlined,
            label: 'Tętno',
            value: pulse.headline,
            detail: _formatWhen(pulse.at),
            tone: pulse.statusTone,
            status: pulse.statusLabel,
          ),
        FilledButton.icon(
          onPressed: _addReading,
          icon: const Icon(Icons.add),
          label: const Text('Dodaj pomiar'),
        ),
        SectionCard(
          title: 'Historia cukru',
          icon: Icons.timeline,
          child: glucoseHistory.isEmpty
              ? const Text('Brak zapisanych pomiarów cukru.')
              : Column(
                  children: [
                    for (var i = 0; i < glucoseHistory.length; i++)
                      _HistoryRow(
                        reading: glucoseHistory[i],
                        isLast: i == glucoseHistory.length - 1,
                      ),
                  ],
                ),
        ),
        SectionCard(
          title: 'Dane medyczne',
          icon: Icons.medical_information_outlined,
          child: Column(
            children: [
              for (var i = 0; i < _medicalFacts.length; i++)
                _Fact(
                  label: _medicalFacts[i].label,
                  value: _medicalFacts[i].value,
                  isLast: i == _medicalFacts.length - 1,
                ),
            ],
          ),
        ),
        SectionCard(
          title: 'Zalecenia',
          icon: Icons.favorite_outline,
          child: Column(
            children: [
              for (var i = 0; i < _advice.length; i++)
                _Advice(text: _advice[i], isLast: i == _advice.length - 1),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: _exportPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Eksportuj kartę do PDF'),
        ),
      ],
    );
  }
}

class _VitalTile extends StatelessWidget {
  const _VitalTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.tone,
    required this.status,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final StatusTone tone;
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(detail, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
            StatusPill(label: status, tone: tone),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.isLast = false});

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
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

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.reading, this.isLast = false});

  final _VitalReading reading;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatWhen(reading.at),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${reading.headline} · ${reading.contextLabel}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          StatusPill(label: reading.statusLabel, tone: reading.statusTone),
        ],
      ),
    );
  }
}

class _AddReadingSheet extends StatefulWidget {
  const _AddReadingSheet();

  @override
  State<_AddReadingSheet> createState() => _AddReadingSheetState();
}

class _AddReadingSheetState extends State<_AddReadingSheet> {
  final _form = GlobalKey<FormState>();
  VitalKind _kind = VitalKind.glucose;
  GlucoseContext _glucoseContext = GlucoseContext.fasting;
  final _glucose = TextEditingController();
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  final _pulse = TextEditingController();

  @override
  void dispose() {
    _glucose.dispose();
    _systolic.dispose();
    _diastolic.dispose();
    _pulse.dispose();
    super.dispose();
  }

  int? _int(String value) => int.tryParse(value.trim());

  String? _requiredPositive(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Wpisz $label.';
    final n = _int(value);
    if (n == null || n <= 0) return 'Wpisz liczbę większą od 0.';
    return null;
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final now = DateTime.now();
    final reading = switch (_kind) {
      VitalKind.glucose => _VitalReading.glucose(
        at: now,
        mgDl: _int(_glucose.text)!,
        context: _glucoseContext,
      ),
      VitalKind.pressure => _VitalReading.pressure(
        at: now,
        systolic: _int(_systolic.text)!,
        diastolic: _int(_diastolic.text)!,
      ),
      VitalKind.pulse => _VitalReading.pulse(
        at: now,
        bpm: _int(_pulse.text)!,
      ),
    };
    Navigator.of(context).pop(reading);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nowy pomiar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SegmentedButton<VitalKind>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
                segments: const [
                  ButtonSegment(
                    value: VitalKind.glucose,
                    label: Text('Cukier'),
                    icon: Icon(Icons.water_drop_outlined),
                  ),
                  ButtonSegment(
                    value: VitalKind.pressure,
                    label: Text('Ciśnienie', maxLines: 1, softWrap: false),
                    icon: Icon(Icons.favorite_outline),
                  ),
                  ButtonSegment(
                    value: VitalKind.pulse,
                    label: Text('Tętno'),
                    icon: Icon(Icons.monitor_heart_outlined),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (value) {
                  setState(() => _kind = value.first);
                },
              ),
              const SizedBox(height: 16),
              if (_kind == VitalKind.glucose) ...[
                TextFormField(
                  controller: _glucose,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Poziom cukru (mg/dl)',
                    hintText: 'np. 118',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => _requiredPositive(v, 'poziom cukru'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<GlucoseContext>(
                  initialValue: _glucoseContext,
                  decoration: const InputDecoration(
                    labelText: 'Kiedy zmierzono',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: GlucoseContext.fasting,
                      child: Text('Na czczo'),
                    ),
                    DropdownMenuItem(
                      value: GlucoseContext.afterMeal,
                      child: Text('Po posiłku'),
                    ),
                    DropdownMenuItem(
                      value: GlucoseContext.other,
                      child: Text('Inny moment'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _glucoseContext = value);
                  },
                ),
              ],
              if (_kind == VitalKind.pressure)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _systolic,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Górne',
                          hintText: '132',
                          suffixText: 'mmHg',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            _requiredPositive(v, 'ciśnienie górne'),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 14, 8, 0),
                      child: Text(
                        '/',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _diastolic,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Dolne',
                          hintText: '78',
                          suffixText: 'mmHg',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            _requiredPositive(v, 'ciśnienie dolne'),
                      ),
                    ),
                  ],
                ),
              if (_kind == VitalKind.pulse)
                TextFormField(
                  controller: _pulse,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Tętno (uderzenia / min)',
                    hintText: 'np. 72',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => _requiredPositive(v, 'tętno'),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _save,
                child: const Text('Zapisz pomiar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Anuluj'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VitalReading {
  const _VitalReading._({
    required this.kind,
    required this.at,
    this.mgDl,
    this.systolic,
    this.diastolic,
    this.bpm,
    this.glucoseContext,
  });

  factory _VitalReading.glucose({
    required DateTime at,
    required int mgDl,
    required GlucoseContext context,
  }) => _VitalReading._(
    kind: VitalKind.glucose,
    at: at,
    mgDl: mgDl,
    glucoseContext: context,
  );

  factory _VitalReading.pressure({
    required DateTime at,
    required int systolic,
    required int diastolic,
  }) => _VitalReading._(
    kind: VitalKind.pressure,
    at: at,
    systolic: systolic,
    diastolic: diastolic,
  );

  factory _VitalReading.pulse({required DateTime at, required int bpm}) =>
      _VitalReading._(kind: VitalKind.pulse, at: at, bpm: bpm);

  final VitalKind kind;
  final DateTime at;
  final int? mgDl;
  final int? systolic;
  final int? diastolic;
  final int? bpm;
  final GlucoseContext? glucoseContext;

  String get headline => switch (kind) {
    VitalKind.glucose => '$mgDl mg/dl',
    VitalKind.pressure => '$systolic/$diastolic mmHg',
    VitalKind.pulse => '$bpm / min',
  };

  String get contextLabel => switch (glucoseContext) {
    GlucoseContext.fasting => 'Na czczo',
    GlucoseContext.afterMeal => 'Po posiłku',
    GlucoseContext.other => 'Inny moment',
    null => 'Pomiar',
  };

  String get statusLabel => switch (kind) {
    VitalKind.glucose => _glucoseStatus.$1,
    VitalKind.pressure => _pressureStatus.$1,
    VitalKind.pulse => _pulseStatus.$1,
  };

  StatusTone get statusTone => switch (kind) {
    VitalKind.glucose => _glucoseStatus.$2,
    VitalKind.pressure => _pressureStatus.$2,
    VitalKind.pulse => _pulseStatus.$2,
  };

  (String, StatusTone) get _glucoseStatus {
    final value = mgDl ?? 0;
    if (glucoseContext == GlucoseContext.afterMeal) {
      if (value < 140) return ('W normie', StatusTone.done);
      if (value < 180) return ('Podwyższony', StatusTone.ready);
      return ('Wysoki', StatusTone.ready);
    }
    if (value < 70) return ('Niski', StatusTone.ready);
    if (value < 100) return ('W normie', StatusTone.done);
    if (value < 126) return ('Podwyższony', StatusTone.ready);
    return ('Wysoki', StatusTone.ready);
  }

  (String, StatusTone) get _pressureStatus {
    final sys = systolic ?? 0;
    final dia = diastolic ?? 0;
    if (sys >= 140 || dia >= 90) return ('Wysokie', StatusTone.ready);
    if (sys >= 130 || dia >= 85) return ('Lekko wyższe', StatusTone.ready);
    if (sys < 90 || dia < 60) return ('Niskie', StatusTone.ready);
    return ('W normie', StatusTone.done);
  }

  (String, StatusTone) get _pulseStatus {
    final value = bpm ?? 0;
    if (value < 60) return ('Wolne', StatusTone.ready);
    if (value > 100) return ('Szybkie', StatusTone.ready);
    return ('W normie', StatusTone.done);
  }
}

String _formatWhen(DateTime at) {
  const months = [
    'sty',
    'lut',
    'mar',
    'kwi',
    'maj',
    'cze',
    'lip',
    'sie',
    'wrz',
    'paź',
    'lis',
    'gru',
  ];
  final hh = at.hour.toString().padLeft(2, '0');
  final mm = at.minute.toString().padLeft(2, '0');
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  if (day == today) return 'Dziś, $hh:$mm';
  if (day == today.subtract(const Duration(days: 1))) return 'Wczoraj, $hh:$mm';
  return '${at.day} ${months[at.month - 1]}, $hh:$mm';
}
