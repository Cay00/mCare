import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/dose_schedule.dart';
import '../services/prescription_dosing.dart';
import 'care_components.dart';

class DoseScheduleEditor extends StatefulWidget {
  const DoseScheduleEditor({
    super.key,
    required this.onChanged,
    this.initialMinutes = const [],
    this.recognizedDosing,
  });
  final ValueChanged<List<int>> onChanged;
  final List<int> initialMinutes;
  final PrescriptionDosing? recognizedDosing;
  @override
  State<DoseScheduleEditor> createState() => _DoseScheduleEditorState();
}

class _DoseScheduleEditorState extends State<DoseScheduleEditor> {
  bool _enabled = false;
  int _count = 1;
  int _first = 8 * 60;
  List<int> _times = [8 * 60];

  @override
  void initState() {
    super.initState();
    if (widget.initialMinutes.isNotEmpty) {
      _enabled = true;
      _times = List.of(widget.initialMinutes);
      _first = _times.first;
      _count = _times.length;
    }
  }

  void _regenerate() {
    _times = evenlySpacedDoseMinutes(_first, _count);
    widget.onChanged(_enabled ? List.of(_times) : []);
  }

  Future<void> _pick(int index) async {
    final time = _times[index];
    final selected = await showDialog<int>(
      context: context,
      builder: (_) => _DoseTimeDialog(
        minutes: time,
        title: index == 0
            ? 'Godzina pierwszej dawki'
            : 'Godzina dawki ${index + 1}',
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      final minutes = selected;
      if (index == 0) {
        _first = minutes;
        _regenerate();
      } else {
        _times[index] = minutes;
        widget.onChanged(List.of(_times));
      }
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
            _enabled = true;
            _regenerate();
          }),
          child: Text('Ustaw liczbę dawek z recepty: ${dosing.dailyCount}'),
        ),
      ],
      SwitchListTile.adaptive(
        key: const Key('enableDoseSchedule'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Ustaw godziny dawek'),
        subtitle: const Text(
          'Plan powtarzany codziennie. Wyłącz dla leków przyjmowanych doraźnie lub według zmiennego schematu.',
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
          label: 'Liczba dawek dziennie według zalecenia',
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
        const CareNotice(
          'Kolejne godziny wyliczamy w równych odstępach w ciągu 24 godzin, także w nocy. Sprawdź je z zaleceniem i w razie potrzeby zmień. Zmiana pierwszej godziny lub liczby dawek przelicza cały plan.',
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _times.length; i++) ...[
          OutlinedButton.icon(
            key: ValueKey('dose-time-$i'),
            onPressed: () => _pick(i),
            icon: const Icon(Icons.access_time),
            label: Text(
              '${i == 0 ? 'Pierwsza dawka' : 'Dawka ${i + 1}'}: ${doseTimeLabel(_times[i])}',
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    ],
  );
}

/// A scrollable numeric picker remains usable with large text and a keyboard.
class _DoseTimeDialog extends StatefulWidget {
  const _DoseTimeDialog({required this.minutes, required this.title});
  final int minutes;
  final String title;
  @override
  State<_DoseTimeDialog> createState() => _DoseTimeDialogState();
}

class _DoseTimeDialogState extends State<_DoseTimeDialog> {
  final _form = GlobalKey<FormState>();
  late final _hour = TextEditingController(
    text: (widget.minutes ~/ 60).toString().padLeft(2, '0'),
  );
  late final _minute = TextEditingController(
    text: (widget.minutes % 60).toString().padLeft(2, '0'),
  );
  void _save() {
    if (_form.currentState!.validate()) {
      Navigator.of(
        context,
      ).pop(int.parse(_hour.text) * 60 + int.parse(_minute.text));
    }
  }

  @override
  void dispose() {
    _hour.dispose();
    _minute.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(widget.title),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field('Godzina (00–23)', 'dose-hour', _hour, 23),
          _field('Minuta (00–59)', 'dose-minute', _minute, 59),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Anuluj'),
      ),
      FilledButton(onPressed: _save, child: const Text('Ustaw')),
    ],
  );
  Widget _field(
    String label,
    String key,
    TextEditingController controller,
    int max,
  ) => CareField(
    label: label,
    child: TextFormField(
      key: ValueKey(key),
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      validator: (text) {
        final value = int.tryParse(text ?? '');
        return value == null || value < 0 || value > max
            ? 'Wpisz liczbę od 0 do $max.'
            : null;
      },
    ),
  );
}
