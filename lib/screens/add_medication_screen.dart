import 'package:flutter/material.dart';

enum FrequencyType { daily, interval, specificDays }

class MedicationModel {
  final String name;
  final String doseAmount;
  final FrequencyType frequencyType;
  final int intervalDays;
  final List<int> selectedDays;
  final TimeOfDay time;
  final int reminderOffsetMinutes;

  MedicationModel({
    required this.name,
    required this.doseAmount,
    required this.frequencyType,
    this.intervalDays = 2,
    this.selectedDays = const [],
    required this.time,
    required this.reminderOffsetMinutes,
  });
}

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _doseController = TextEditingController(text: '1 tabletka (500 mg)');

  FrequencyType _frequencyType = FrequencyType.daily;
  int _intervalDays = 2;
  final Set<int> _selectedDays = {1, 2, 3, 4, 5};

  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  int _reminderOffsetMinutes = 30;

  final List<String> _dayNames = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'So', 'Nd'];

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    super.dispose();
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF005F56),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveMedication() {
    if (_formKey.currentState!.validate()) {
      if (_frequencyType == FrequencyType.specificDays && _selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wybierz przynajmniej jeden dzień tygodnia.')),
        );
        return;
      }

      final newMed = MedicationModel(
        name: _nameController.text.trim(),
        doseAmount: _doseController.text.trim(),
        frequencyType: _frequencyType,
        intervalDays: _intervalDays,
        selectedDays: _selectedDays.toList()..sort(),
        time: _selectedTime,
        reminderOffsetMinutes: _reminderOffsetMinutes,
      );

      Navigator.pop(context, newMed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      appBar: AppBar(
        title: const Text(
          'Nowy lek',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _buildSection(
              title: 'Podstawowe informacje',
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nazwa leku',
                      hintText: 'np. Metformax, Euthyrox',
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.medication_outlined, color: Color(0xFF005F56)),
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Podaj nazwę leku' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _doseController,
                    decoration: InputDecoration(
                      labelText: 'Wielkość dawki i forma',
                      hintText: 'np. 1 tabletka, 2 krople, 1 saszetka',
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.scale_outlined, color: Color(0xFF005F56)),
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Podaj dawkę' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Częstotliwość przyjmowania',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioListTile<FrequencyType>(
                    title: const Text('Codziennie'),
                    subtitle: const Text('Stała rutyna każdego dnia'),
                    value: FrequencyType.daily,
                    groupValue: _frequencyType,
                    activeColor: const Color(0xFF005F56),
                    onChanged: (val) => setState(() => _frequencyType = val!),
                  ),
                  RadioListTile<FrequencyType>(
                    title: const Text('Co określoną liczbę dni'),
                    subtitle: Text('Co $_intervalDays dni'),
                    value: FrequencyType.interval,
                    groupValue: _frequencyType,
                    activeColor: const Color(0xFF005F56),
                    onChanged: (val) => setState(() => _frequencyType = val!),
                  ),
                  if (_frequencyType == FrequencyType.interval)
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 16, bottom: 8),
                      child: Row(
                        children: [
                          const Text('Powtarzaj co:'),
                          const Spacer(),
                          IconButton(
                            onPressed: _intervalDays > 2
                                ? () => setState(() => _intervalDays--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$_intervalDays dni',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _intervalDays++),
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF005F56)),
                          ),
                        ],
                      ),
                    ),
                  RadioListTile<FrequencyType>(
                    title: const Text('Wybrane dni tygodnia'),
                    subtitle: const Text('Tylko w wybrane dni'),
                    value: FrequencyType.specificDays,
                    groupValue: _frequencyType,
                    activeColor: const Color(0xFF005F56),
                    onChanged: (val) => setState(() => _frequencyType = val!),
                  ),
                  if (_frequencyType == FrequencyType.specificDays)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (index) {
                          final dayIndex = index + 1;
                          final isSelected = _selectedDays.contains(dayIndex);
                          return FilterChip(
                            label: Text(_dayNames[index]),
                            selected: isSelected,
                            showCheckmark: false,
                            selectedColor: const Color(0xFF005F56),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedDays.add(dayIndex);
                                } else {
                                  _selectedDays.remove(dayIndex);
                                }
                              });
                            },
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Godzina i powiadomienie',
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.access_time, color: Color(0xFF005F56)),
                    title: const Text('Godzina przyjęcia dawki'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5F3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedTime.format(context),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF005F56),
                        ),
                      ),
                    ),
                    onTap: _pickTime,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.alarm, color: Color(0xFF005F56)),
                    title: const Text('Przypomnienie z wyprzedzeniem'),
                    subtitle: const Text('Powiadomienie w telefonie przed czasem'),
                    trailing: DropdownButton<int>(
                      value: _reminderOffsetMinutes,
                      underline: const SizedBox(),
                      borderRadius: BorderRadius.circular(12),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('O godzinie dawki')),
                        DropdownMenuItem(value: 15, child: Text('15 min wcześniej')),
                        DropdownMenuItem(value: 30, child: Text('30 min wcześniej')),
                        DropdownMenuItem(value: 60, child: Text('1 godz. wcześniej')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _reminderOffsetMinutes = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveMedication,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005F56),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: const Text(
                'Zapisz lek i harmonogram',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
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
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}