import 'package:flutter/material.dart';
import '../services/dose_schedule.dart';
import '../services/prescription_dosing.dart';
import 'care_components.dart';

class DoseScheduleEditor extends StatefulWidget {
  const DoseScheduleEditor({
    super.key,
    required this.onChanged,
    this.initialMinutes = const [],
    this.recognizedDosing,
    this.initialEveryDays = 1,
    this.initialStart,
    this.onPatternChanged,
  });
  final ValueChanged<List<int>> onChanged;
  final List<int> initialMinutes;
  final PrescriptionDosing? recognizedDosing;
  final int initialEveryDays;
  final DateTime? initialStart;
  final void Function(int days, DateTime start)? onPatternChanged;
  @override
  State<DoseScheduleEditor> createState() => _DoseScheduleEditorState();
}

class _DoseScheduleEditorState extends State<DoseScheduleEditor> {
  bool _enabled = false;
  int _count = 1;
  List<int> _times = [-1];
  late int _everyDays = widget.initialEveryDays;
  late DateTime _start = widget.initialStart ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.initialMinutes.isNotEmpty) {
      _enabled = true;
      _times = List.of(widget.initialMinutes);
      _count = _times.length;
    } else if (widget.recognizedDosing case final dosing?) {
      _count = dosing.dailyCount;
      _everyDays = dosing.everyDays;
      _times = List.filled(_count, -1);
      _enabled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _emit();
      });
    }
  }

  void _regenerate() {
    _times = List.generate(_count, (i) => i < _times.length ? _times[i] : -1);
    _emit();
  }

  void _emit() {
    widget.onChanged(_enabled ? List.of(_times) : []);
    widget.onPatternChanged?.call(_everyDays, _start);
  }

  Future<void> _pick(int index) async {
    final time = _times[index];
    final initial = time < 0 ? 8 * 60 : time;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
      initialEntryMode: TimePickerEntryMode.dialOnly,
      orientation: Orientation.portrait,
      helpText: index == 0
          ? 'Godzina pierwszej dawki'
          : 'Godzina dawki ${index + 1}',
      cancelText: 'Anuluj',
      confirmText: 'Ustaw',
      builder: (context, child) => MediaQuery(
        // The fixed clock face overlaps its labels at large system text scales.
        // Limit scaling only inside this standard picker; the form stays scalable.
        data: MediaQuery.of(context).copyWith(
          alwaysUse24HourFormat: true,
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(maxScaleFactor: 1.3),
        ),
        child: child!,
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _times[index] = selected.hour * 60 + selected.minute;
      _emit();
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.recognizedDosing case final dosing?) ...[
        CareNotice(
          'Odczytany zapis: ${dosing.description}. Sprawdź zgodność z receptą.',
        ),
        OutlinedButton(
          onPressed: () => setState(() {
            _count = dosing.dailyCount;
            _everyDays = dosing.everyDays;
            _times = List.filled(_count, -1);
            _enabled = true;
            _regenerate();
          }),
          child: Text(
            'Zastosuj schemat z recepty: ${dosing.dailyCount} przyjęć',
          ),
        ),
      ],
      SwitchListTile.adaptive(
        key: const Key('enableDoseSchedule'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Ustaw godziny dawek'),
        subtitle: const Text(
          'Wybierz osobno każdą godzinę. Wyłącz dla leków przyjmowanych doraźnie lub według zmiennego schematu.',
        ),
        value: _enabled,
        onChanged: (value) => setState(() {
          _enabled = value;
          _regenerate();
        }),
      ),
      if (_enabled) ...[
        const SizedBox(height: 12),
        CareField(
          label: 'Liczba przyjęć w dniu dawkowania',
          child: DropdownButtonFormField<int>(
            key: ValueKey('dailyDoseCount-$_count'),
            initialValue: _count,
            isExpanded: true,
            items: List.generate(
              24,
              (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
            ),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _count = value;
                  _regenerate();
                });
              }
            },
          ),
        ),
        CareField(
          label: 'Powtarzaj co ile dni',
          child: DropdownButtonFormField<int>(
            key: ValueKey('every-days-$_everyDays'),
            initialValue: _everyDays,
            isExpanded: true,
            items: List.generate(
              365,
              (i) => DropdownMenuItem(
                value: i + 1,
                child: Text(i == 0 ? 'Codziennie' : 'Co ${i + 1} dni'),
              ),
            ),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _everyDays = value;
                  _emit();
                });
              }
            },
          ),
        ),
        OutlinedButton.icon(
          key: const Key('schedule-start'),
          icon: const Icon(Icons.calendar_today),
          label: Text(
            'Pierwszy dzień: ${_start.day}.${_start.month}.${_start.year}',
          ),
          onPressed: () async {
            final selected = await showDatePicker(
              context: context,
              initialDate: _start,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (selected != null && mounted) {
              setState(() {
                _start = selected;
                _emit();
              });
            }
          },
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _times.length; i++) ...[
          OutlinedButton.icon(
            key: ValueKey('dose-time-$i'),
            onPressed: () => _pick(i),
            icon: const Icon(Icons.access_time),
            label: Text(
              '${i == 0 ? 'Pierwsza dawka' : 'Dawka ${i + 1}'}${widget.recognizedDosing?.periods.length == _count ? ' (${widget.recognizedDosing!.periods[i]})' : ''}: ${_times[i] < 0 ? 'wybierz godzinę' : doseTimeLabel(_times[i])}',
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    ],
  );
}
