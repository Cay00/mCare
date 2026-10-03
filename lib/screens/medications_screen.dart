import 'package:flutter/material.dart';
import 'add_medication_screen.dart';

enum MedicationTimeOfDay { morning, noon, evening }

class MedicationDose {
  final String id;
  final String time;
  final String name;
  final String instruction;
  final MedicationTimeOfDay timeOfDay;
  bool isTaken;

  MedicationDose({
    required this.id,
    required this.time,
    required this.name,
    required this.instruction,
    required this.timeOfDay,
    this.isTaken = false,
  });
}

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  int _selectedFilterIndex = 0;

  final List<MedicationDose> _dosesToday = [
    MedicationDose(
      id: '1',
      time: '08:00',
      name: 'Acard 75 mg',
      instruction: '1 tabletka • po śniadaniu',
      timeOfDay: MedicationTimeOfDay.morning,
      isTaken: true,
    ),
    MedicationDose(
      id: '2',
      time: '08:00',
      name: 'Prestarium 5 mg',
      instruction: '1 tabletka • po śniadaniu',
      timeOfDay: MedicationTimeOfDay.morning,
      isTaken: true,
    ),
    MedicationDose(
      id: '3',
      time: '14:00',
      name: 'Metformax 500 mg',
      instruction: '1 tabletka • w trakcie obiadu',
      timeOfDay: MedicationTimeOfDay.noon,
      isTaken: false,
    ),
    MedicationDose(
      id: '4',
      time: '20:00',
      name: 'Metformax 500 mg',
      instruction: '1 tabletka • w trakcie kolacji',
      timeOfDay: MedicationTimeOfDay.evening,
      isTaken: false,
    ),
  ];

  void _toggleDose(MedicationDose dose) {
    setState(() {
      dose.isTaken = !dose.isTaken;
    });
  }

  void _openAddMedicationModal() {
    showModalBottomSheet(
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Symulacja OCR: Rozpoznano "Milurit 100 mg"')),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Zeskanuj opakowanie / ulotkę'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final nav = Navigator.of(context);
                Navigator.pop(ctx); // Zamyka modal

                // Otwiera osobną trasę (Route) dla pełnego formularza
                final result = await nav.push<MedicationModel>(
                  MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
                );

                if (result != null) {
                  setState(() {
                    final formattedHour = result.time.hour.toString().padLeft(2, '0');
                    final formattedMin = result.time.minute.toString().padLeft(2, '0');
                    final reminderText = result.reminderOffsetMinutes > 0
                        ? ' • Dzwonek ${result.reminderOffsetMinutes} min wcześniej'
                        : '';

                    _dosesToday.add(
                      MedicationDose(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        time: '$formattedHour:$formattedMin',
                        name: result.name,
                        instruction: '${result.doseAmount}$reminderText',
                        timeOfDay: result.time.hour < 12
                            ? MedicationTimeOfDay.morning
                            : (result.time.hour < 18
                                ? MedicationTimeOfDay.noon
                                : MedicationTimeOfDay.evening),
                        isTaken: false,
                      ),
                    );
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Dodano lek: ${result.name}')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.edit),
              label: const Text('Wpisz dane ręcznie'),
            ),
          ],
        ),
      ),
    );
  }

  List<MedicationDose> get _filteredDoses {
    if (_selectedFilterIndex == 1) {
      return _dosesToday.where((d) => d.timeOfDay == MedicationTimeOfDay.morning).toList();
    } else if (_selectedFilterIndex == 2) {
      return _dosesToday.where((d) => d.timeOfDay == MedicationTimeOfDay.noon).toList();
    } else if (_selectedFilterIndex == 3) {
      return _dosesToday.where((d) => d.timeOfDay == MedicationTimeOfDay.evening).toList();
    }
    return _dosesToday;
  }

  @override
  Widget build(BuildContext context) {
    final takenCount = _dosesToday.where((d) => d.isTaken).length;
    final totalCount = _dosesToday.length;
    final progress = totalCount > 0 ? takenCount / totalCount : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            const Text(
              'Leki',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Harmonogram na dziś i stan apteczki',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildProgressCard(takenCount, totalCount, progress),
            const SizedBox(height: 16),
            _buildFilterTabs(),
            const SizedBox(height: 16),
            const Text(
              'Zaplanowane dawki',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_filteredDoses.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'Brak zaplanowanych dawek w tej porze dnia',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ..._filteredDoses.map((dose) => _buildDoseCard(dose)),
            const SizedBox(height: 24),
            _buildPermanentMedsCard(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openAddMedicationModal,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Dodaj lek', style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005F56),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final labels = ['Wszystkie', 'Rano', 'Obiad', 'Wieczór'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(labels[index]),
              selected: isSelected,
              selectedColor: const Color(0xFF005F56),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.white,
              onSelected: (val) {
                if (val) setState(() => _selectedFilterIndex = index);
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProgressCard(int taken, int total, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Postęp na dzisiaj',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              Text(
                '$taken z $total dawek',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF005F56)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF005F56)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseCard(MedicationDose dose) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
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
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  dose.instruction,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                color: dose.isTaken ? const Color(0xFF8CE0D8) : const Color(0xFFFFECE5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dose.isTaken) ...[
                    const Icon(Icons.check, size: 14, color: Color(0xFF004D40)),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    dose.isTaken ? 'Przyjęty' : 'Do przyjęcia',
                    style: TextStyle(
                      color: dose.isTaken ? const Color(0xFF004D40) : const Color(0xFFBF360C),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
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
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.inventory_2_outlined, color: Color(0xFF005F56), size: 20),
              SizedBox(width: 8),
              Text(
                'Leki stałe i stan apteczki',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildPermanentMedRow('Acard 75 mg', 'Codziennie rano', 'Zapas: 28 dni (28 szt.)'),
          const SizedBox(height: 12),
          _buildPermanentMedRow('Prestarium 5 mg', 'Codziennie rano', 'Zapas: 14 dni (14 szt.)'),
          const SizedBox(height: 12),
          _buildPermanentMedRow(
            'Metformax 500 mg',
            'Obiad i kolacja',
            'Zapas: 3 dni (6 szt.)',
            isLow: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPermanentMedRow(String name, String dosage, String stockInfo, {bool isLow = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(dosage, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isLow ? const Color(0xFFFFF1F0) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isLow ? const Color(0xFFFFA39E) : Colors.transparent),
          ),
          child: Text(
            stockInfo,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isLow ? Colors.red[800] : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}