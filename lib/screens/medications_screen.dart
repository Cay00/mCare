import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../widgets/medication_form.dart';
import 'medication_scanner_screen.dart';
import '../widgets/care_components.dart';
import '../widgets/prototype_page.dart';
import '../widgets/section_card.dart';
import '../widgets/status_pill.dart';
import '../theme/app_theme.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key, this.scanMedication});

  final Future<MedicationProduct?> Function(BuildContext)? scanMedication;

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final List<MedicationStock> _medications = [];
  bool _addingMedication = false;
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

  Future<void> _openAddMedicationModal() async {
    if (_addingMedication) return;
    _addingMedication = true;
    try {
      final scan = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Dodaj nowy lek',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Wybierz sposób dodania leku.'),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(ctx, true);
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Zeskanuj kod kreskowy'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx, false),
                icon: const Icon(Icons.edit),
                label: const Text('Wpisz dane ręcznie'),
              ),
            ],
          ),
        ),
      );
      if (!mounted || scan == null) return;
      MedicationProduct? product;
      if (scan) {
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
      setState(() => _medications.add(medication));
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
      FilledButton.icon(
        onPressed: _openAddMedicationModal,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj lek'),
      ),
      const CareHeading('Dawki na dziś'),
      ..._dosesToday.map(_buildDoseCard),
      _buildPermanentMedsCard(),
    ],
  );

  Widget _buildDoseCard(MedicationDose dose) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      child: Card(
        key: ValueKey('dose-card-${dose.id}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(dose.time, style: theme.textTheme.titleLarge),
                        StatusPill(
                          label: dose.isTaken ? 'Przyjęty' : 'Do przyjęcia',
                          tone: dose.isTaken
                              ? StatusTone.done
                              : StatusTone.ready,
                        ),
                      ],
                    ),
                  ),
                  if (dose.isTaken)
                    IconButton(
                      key: ValueKey('dose-${dose.id}'),
                      tooltip:
                          'Cofnij potwierdzenie: ${dose.name}, ${dose.time}',
                      onPressed: () => _toggleDose(dose),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.undo_rounded, size: 22),
                    ),
                ],
              ),
              SizedBox(height: dose.isTaken ? 10 : 18),
              Text(dose.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                dose.instruction,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: CareColors.muted,
                ),
              ),
              if (!dose.isTaken) ...[
                const SizedBox(height: 20),
                Semantics(
                  label: '${dose.name}, godzina ${dose.time}',
                  child: FilledButton.icon(
                    key: ValueKey('dose-${dose.id}'),
                    onPressed: () => _toggleDose(dose),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Potwierdź przyjęcie'),
                  ),
                ),
              ],
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
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(name, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 6),
      Text(
        dosage,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: CareColors.muted),
      ),
      const SizedBox(height: 12),
      StatusPill(
        label: stockInfo,
        tone: isLow ? StatusTone.ready : StatusTone.neutral,
      ),
    ],
  );
}
