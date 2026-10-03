import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../widgets/medication_form.dart';
import 'medication_scanner_screen.dart';

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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => Padding(
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
              const SizedBox(height: 16),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Text(
            'Dawki na dziś i lista leków stałych. Zarządzaj dawkami i zapasami.',
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          const SizedBox(height: 10),
          const Text(
            'Dziś',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._dosesToday.map((dose) => _buildDoseCard(dose)),
          const SizedBox(height: 24),
          _buildPermanentMedsCard(),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openAddMedicationModal,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Dodaj lek',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005F56),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDoseCard(MedicationDose dose) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Text(
            dose.time,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dose.instruction,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _toggleDose(dose),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: dose.isTaken
                    ? const Color(0xFF8CE0D8)
                    : const Color(0xFFFFECE5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                dose.isTaken ? 'Przyjęty' : 'Do przyjęcia',
                style: TextStyle(
                  color: dose.isTaken
                      ? const Color(0xFF004D40)
                      : const Color(0xFFBF360C),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermanentMedsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.local_hospital_outlined,
                color: Color(0xFF005F56),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Leki stałe i stan zapasów',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildPermanentMedRow(
            'Acard 75 mg',
            'Codziennie rano',
            'Zapas: 28 dni',
          ),
          const SizedBox(height: 12),
          _buildPermanentMedRow(
            'Prestarium 5 mg',
            'Codziennie rano',
            'Zapas: 14 dni',
          ),
          const SizedBox(height: 12),
          _buildPermanentMedRow(
            'Metformax 500 mg',
            'Obiad i kolacja',
            'Uwaga: Zostało na 3 dni!',
            isLow: true,
          ),
          for (final medication in _medications) ...[
            const SizedBox(height: 12),
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
  }

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                dosage,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            stockInfo,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isLow ? Colors.orange[800] : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
}
