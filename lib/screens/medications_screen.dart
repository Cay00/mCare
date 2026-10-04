import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../widgets/medication_form.dart';
import 'medication_scanner_screen.dart';
import '../widgets/care_components.dart';
import '../widgets/prototype_page.dart';
import '../widgets/section_card.dart';
import '../widgets/status_pill.dart';
import '../theme/app_theme.dart';
import 'prescription_import_screen.dart';
import '../services/dose_schedule.dart';
import '../models/prescription.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({
    super.key,
    this.scanMedication,
    this.readPrescription,
  });

  final Future<MedicationProduct?> Function(BuildContext)? scanMedication;
  final Future<PrescriptionImport?> Function(void Function(String))?
  readPrescription;

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final List<MedicationStock> _medications = [];
  bool _addingMedication = false;
  int _nextDoseId = 5;
  final List<MedicationDose> _dosesToday = [
    MedicationDose(
      id: '1',
      time: '08:00',
      name: 'Acard 75 mg',
      instruction: '1 tabletka • po śniadaniu',
      isTaken: true,
    ),
    MedicationDose(
      id: '2',
      time: '08:00',
      name: 'Prestarium 5 mg',
      instruction: '1 tabletka • po śniadaniu',
      isTaken: true,
    ),
    MedicationDose(
      id: '3',
      time: '14:00',
      name: 'Metformax 500 mg',
      instruction: '1 tabletka • w trakcie obiadu',
      isTaken: false,
    ),
    MedicationDose(
      id: '4',
      time: '20:00',
      name: 'Metformax 500 mg',
      instruction: '1 tabletka • w trakcie kolacji',
      isTaken: false,
    ),
  ];

  void _toggleDose(MedicationDose dose) {
    setState(() {
      dose.isTaken = !dose.isTaken;
    });
  }

  void _addMedications(List<MedicationStock> medications) {
    setState(() {
      _medications.addAll(medications);
      for (final medication in medications) {
        for (final minute in medication.doseMinutes) {
          _dosesToday.add(
            MedicationDose(
              id: '${_nextDoseId++}',
              time: doseTimeLabel(minute),
              name: medication.product.displayName,
              product: medication.product,
              schedule: medication,
              instruction: medication.instruction.isEmpty
                  ? 'Dawkowanie do uzupełnienia'
                  : 'Dawkowanie: ${medication.instruction}',
            ),
          );
        }
      }
      _dosesToday.sort((a, b) => a.time.compareTo(b.time));
    });
  }

  Future<void> _importPrescription() async {
    if (_addingMedication) return;
    _addingMedication = true;
    try {
      final items = await Navigator.of(context).push<List<MedicationStock>>(
        MaterialPageRoute(
          builder: (_) => PrescriptionImportScreen(
            readPrescription: widget.readPrescription,
          ),
        ),
      );
      if (!mounted || items == null || items.isEmpty) return;
      _addMedications(items);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dodano leki z recepty: ${items.length}.')),
      );
    } finally {
      _addingMedication = false;
    }
  }

  Future<void> _openAddMedicationModal() async {
    if (_addingMedication) return;
    _addingMedication = true;
    try {
      final scan = await showModalBottomSheet<_AddPath>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => const _AddMedicationSheet(),
      );
      if (!mounted || scan == null || scan == _AddPath.dismissed) return;
      if (scan == _AddPath.pdf) {
        _addingMedication = false;
        await _importPrescription();
        return;
      }
      MedicationProduct? product;
      if (scan == _AddPath.scan) {
        product =
            await (widget.scanMedication?.call(context) ??
                Navigator.of(context).push<MedicationProduct>(
                  MaterialPageRoute(
                    builder: (_) => const MedicationScannerScreen(),
                  ),
                ));
        if (!mounted || product == null) return;
      }
      final medication = await showMedicationForm(context, product: product);
      if (!mounted || medication == null) return;
      _addMedications([medication]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dodano lek: ${medication.product.displayName}'),
        ),
      );
    } finally {
      _addingMedication = false;
    }
  }

  @override
  Widget build(BuildContext context) => PrototypePage(
    children: [
      const CareHeading(
        'Twoje leki',
        subtitle: 'Twój plan przyjmowania leków i stan zapasów.',
      ),
      _MedicationActions(
        onAdd: _openAddMedicationModal,
        onImport: _importPrescription,
      ),
      const CareHeading('Dawki na dziś'),
      ..._dosesToday
          .where((dose) => dose.schedule?.isScheduledOn(DateTime.now()) ?? true)
          .map(_buildDoseCard),
      _buildPermanentMedsCard(),
    ],
  );

  Widget _buildDoseCard(MedicationDose dose) {
    final theme = Theme.of(context);
    final pill = StatusPill(
      label: dose.isTaken ? 'Przyjęty' : 'Do przyjęcia',
      tone: dose.isTaken ? StatusTone.done : StatusTone.ready,
    );
    return Semantics(
      container: true,
      child: Card(
        key: ValueKey('dose-card-${dose.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (dose.isTaken)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    key: ValueKey('dose-${dose.id}'),
                    tooltip: 'Cofnij potwierdzenie: ${dose.name}, ${dose.time}',
                    onPressed: () => _toggleDose(dose),
                    style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                    icon: const Icon(Icons.undo_rounded, size: 22),
                  ),
                )
              else
                Semantics(
                  label: '${dose.name}, godzina ${dose.time}',
                  child: FilledButton.icon(
                    key: ValueKey('dose-${dose.id}'),
                    onPressed: () => _toggleDose(dose),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Potwierdź przyjęcie'),
                  ),
                ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide =
                      constraints.maxWidth > 260 &&
                      MediaQuery.textScalerOf(context).scale(1) < 1.35;
                  final details = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dose.time, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(dose.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        dose.instruction,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: CareColors.muted,
                        ),
                      ),
                    ],
                  );
                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(dose.time, style: theme.textTheme.titleLarge),
                            pill,
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(dose.name, style: theme.textTheme.titleMedium),
                        Text(
                          dose.instruction,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: CareColors.muted,
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: details),
                      const SizedBox(width: 8),
                      pill,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermanentMedsCard() => SectionCard(
    title: 'Leki stałe i stan zapasów',
    icon: Icons.inventory_2_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPermanentMedRow(
          'Acard 75 mg',
          'Codziennie rano',
          'Zapas: 28 dni',
        ),
        const Divider(),
        _buildPermanentMedRow(
          'Prestarium 5 mg',
          'Codziennie rano',
          'Zapas: 14 dni',
        ),
        const Divider(),
        _buildPermanentMedRow(
          'Metformax 500 mg',
          'Obiad i kolacja',
          'Uwaga: Zostało na 3 dni!',
          isLow: true,
        ),
        for (final medication in _medications) ...[
          const Divider(),
          _buildPermanentMedRow(
            medication.product.displayName,
            medication.instruction.isEmpty
                ? 'Dawkowanie do uzupełnienia'
                : medication.instruction,
            _stockLabel(medication),
          ),
        ],
      ],
    ),
  );

  String _stockLabel(MedicationStock medication) {
    final total = medication.totalUnits;
    if (total != null && medication.product.packageUnit != null) {
      return 'Zapas: ${formatQuantity(total)} ${medication.product.packageUnit}';
    }
    if (medication.ownedPackages != null) {
      return 'Zapas: ${medication.ownedPackages} opak.';
    }
    return 'Zapas do uzupełnienia';
  }

  Widget _buildPermanentMedRow(
    String name,
    String dosage,
    String stockInfo, {
    bool isLow = false,
  }) {
    final pill = StatusPill(
      label: stockInfo,
      tone: isLow ? StatusTone.ready : StatusTone.neutral,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth > 240 &&
            MediaQuery.textScalerOf(context).scale(1) < 1.35;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(
              dosage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: CareColors.muted),
            ),
          ],
        );
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              copy,
              const SizedBox(height: 8),
              pill,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: copy),
            const SizedBox(width: 12),
            Flexible(child: pill),
          ],
        );
      },
    );
  }
}

enum _AddPath { scan, manual, pdf, dismissed }

class _MedicationActions extends StatelessWidget {
  const _MedicationActions({required this.onAdd, required this.onImport});

  final VoidCallback onAdd;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final add = OutlinedButton.icon(
      onPressed: onAdd,
      icon: const Icon(Icons.add),
      label: const Text('Dodaj lek'),
    );
    final upload = OutlinedButton.icon(
      key: const Key('importPrescription'),
      onPressed: onImport,
      icon: const Icon(Icons.upload_file_outlined),
      label: const Text('Wczytaj receptę'),
    );
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [add, const SizedBox(height: 12), upload],
      );
    }
    return Row(
      children: [
        Expanded(child: add),
        const SizedBox(width: 12),
        Expanded(child: upload),
      ],
    );
  }
}

class _AddMedicationSheet extends StatelessWidget {
  const _AddMedicationSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CareColors.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Dodaj nowy lek', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Wybierz sposób dodania leku.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: CareColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          _AddOption(
            icon: Icons.description_outlined,
            title: 'Wybierz plik PDF',
            subtitle: 'Wczytaj receptę z pliku',
            onTap: () => Navigator.pop(context, _AddPath.pdf),
          ),
          _AddOption(
            icon: Icons.qr_code_scanner,
            title: 'Zeskanuj kod kreskowy',
            subtitle: 'Użyj aparatu, aby zeskanować kod leku',
            onTap: () => Navigator.pop(context, _AddPath.scan),
          ),
          _AddOption(
            icon: Icons.edit_outlined,
            title: 'Wpisz dane ręcznie',
            subtitle: 'Uzupełnij nazwę i dawkowanie ręcznie',
            onTap: () => Navigator.pop(context, _AddPath.manual),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, _AddPath.dismissed),
            child: const Text('Anuluj'),
          ),
        ],
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  const _AddOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CareColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CareIcon(icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: CareColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
