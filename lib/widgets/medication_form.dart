import 'package:m_opiekun/widgets/care_components.dart';
import 'package:flutter/material.dart';

import '../models/medication.dart';
import '../services/prescription_dosing.dart';
import 'dose_schedule_editor.dart';

Future<MedicationStock?> showMedicationForm(
  BuildContext context, {
  MedicationProduct? product,
  MedicationStock? initialStock,
  String? prescriptionSource,
  int? prescribedPackages,
}) => showModalBottomSheet<MedicationStock>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (_) => MedicationForm(
    product: product,
    initialStock: initialStock,
    prescriptionSource: prescriptionSource,
    prescribedPackages: prescribedPackages,
  ),
);

class MedicationForm extends StatefulWidget {
  const MedicationForm({
    this.product,
    this.initialStock,
    this.prescriptionSource,
    this.prescribedPackages,
    super.key,
  });
  final MedicationProduct? product;
  final MedicationStock? initialStock;
  final String? prescriptionSource;
  final int? prescribedPackages;

  @override
  State<MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<MedicationForm> {
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  MedicationProduct? get _initialProduct =>
      widget.initialStock?.product ?? widget.product;
  late List<int> _doseMinutes = List.of(widget.initialStock?.doseMinutes ?? []);
  late int _everyDays = widget.initialStock?.everyDays ?? 1;
  late DateTime _scheduleStart =
      widget.initialStock?.scheduleStart ?? DateTime.now();
  late final _name = TextEditingController(text: _initialProduct?.name);
  late final _strength = TextEditingController(text: _initialProduct?.strength);
  late final _shape = TextEditingController(
    text: _initialProduct?.pharmaceuticalForm,
  );
  late final _description = TextEditingController(
    text: _initialProduct?.packageDescription,
  );
  late final _quantity = TextEditingController(
    text: _initialProduct?.packageQuantity == null
        ? ''
        : formatQuantity(_initialProduct!.packageQuantity!),
  );
  late final _unit = TextEditingController(text: _initialProduct?.packageUnit);
  late final _instruction = TextEditingController(
    text: widget.initialStock?.instruction,
  );
  late final _packages = TextEditingController(
    text: widget.initialStock?.ownedPackages?.toString(),
  );
  late final _looseUnits = TextEditingController(
    text: widget.initialStock?.looseUnits == null
        ? ''
        : formatQuantity(widget.initialStock!.looseUnits!),
  );

  double? _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  String? _validateNumber(
    String? value, {
    bool integer = false,
    bool positive = false,
  }) {
    if (value == null || value.trim().isEmpty) return null;
    final number = _number(value);
    if (number == null ||
        !number.isFinite ||
        number < 0 ||
        (positive && number == 0) ||
        (integer && number != number.roundToDouble())) {
      return integer
          ? 'Wpisz liczbę całkowitą, co najmniej 0.'
          : positive
          ? 'Wpisz liczbę większą od 0.'
          : 'Wpisz liczbę, co najmniej 0.';
    }
    return null;
  }

  void _save() {
    if (_saving) return;
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final product = MedicationProduct(
      name: _name.text.trim(),
      strength: _strength.text.trim(),
      pharmaceuticalForm: _shape.text.trim(),
      packageDescription: _description.text.trim(),
      packageQuantity: _number(_quantity.text),
      packageUnit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
      gtin: _initialProduct?.gtin,
    );
    Navigator.of(context).pop(
      MedicationStock(
        product: product,
        instruction: _instruction.text.trim(),
        ownedPackages: _number(_packages.text)?.toInt(),
        looseUnits: _number(_looseUnits.text),
        doseMinutes: List.unmodifiable(_doseMinutes),
        everyDays: _everyDays,
        scheduleStart: _scheduleStart,
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _strength,
      _shape,
      _description,
      _quantity,
      _unit,
      _instruction,
      _packages,
      _looseUnits,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanned = widget.product != null;
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
                widget.prescriptionSource != null
                    ? 'Sprawdź lek z recepty'
                    : scanned
                    ? 'Rozpoznano lek'
                    : 'Dodaj nowy lek',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (widget.prescriptionSource != null) ...[
                const CareNotice(
                  'Porównaj nazwę i dawkowanie z PDF. Odczyt, zwłaszcza ze skanu, może zawierać błędy.',
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  title: const Text('Odczytany fragment recepty'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(widget.prescriptionSource!),
                    ),
                  ],
                ),
                if (widget.prescribedPackages != null)
                  Text(
                    'Przepisane opakowania: ${widget.prescribedPackages}. Posiadany zapas wpisz osobno.',
                  ),
                const SizedBox(height: 20),
              ],
              _field(
                'Nazwa leku',
                _name,
                readOnly: scanned,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Wpisz nazwę leku.' : null,
              ),
              _field('Moc', _strength, readOnly: scanned),
              _field('Postać leku', _shape, readOnly: scanned),
              _field('Opis opakowania', _description, readOnly: scanned),
              if (widget.product?.gtin != null) ...[
                Text('GTIN: ${widget.product!.gtin}'),
                const SizedBox(height: 12),
              ],
              if (scanned && widget.product!.packageQuantity == null) ...[
                const Text(
                  'Rejestr nie podaje jednoznacznej liczby jednostek. '
                  'Możesz uzupełnić ją z opakowania lub pozostawić pustą.',
                ),
                const SizedBox(height: 12),
              ],
              _field(
                'Ilość w jednym opakowaniu',
                _quantity,
                readOnly: scanned && widget.product!.packageQuantity != null,
                numeric: true,
                validator: (value) {
                  final error = _validateNumber(value, positive: true);
                  if (error != null) return error;
                  if ((value == null || value.trim().isEmpty) &&
                      _unit.text.trim().isNotEmpty) {
                    return 'Podaj ilość albo pozostaw ilość i jednostkę puste.';
                  }
                  return null;
                },
              ),
              _field(
                'Jednostka (np. tabletki, kapsułki, ml)',
                _unit,
                readOnly: scanned && widget.product!.packageUnit != null,
                validator: (value) {
                  if (_quantity.text.trim().isNotEmpty ||
                      _looseUnits.text.trim().isNotEmpty) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Podaj jednostkę.';
                    }
                  }
                  return null;
                },
              ),
              const CareHeading('Dawkowanie i zapas'),
              const SizedBox(height: 20),
              _field(
                'Dawkowanie według zaleceń lekarza',
                _instruction,
                maxLines: 2,
                hint: 'Wpisz zalecenie — możesz uzupełnić później',
              ),
              FormField<List<int>>(
                initialValue: _doseMinutes,
                validator: (times) =>
                    times != null && times.any((time) => time < 0)
                    ? 'Ustaw osobno godzinę każdego przyjęcia leku.'
                    : times != null && times.toSet().length != times.length
                    ? 'Godziny dawek nie mogą się powtarzać.'
                    : null,
                builder: (state) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _instruction,
                      builder: (context, value, child) => DoseScheduleEditor(
                        recognizedDosing: recognizePrescriptionDosing(
                          value.text,
                        ),
                        initialMinutes: _doseMinutes,
                        initialEveryDays: _everyDays,
                        initialStart: _scheduleStart,
                        onPatternChanged: (days, start) {
                          _everyDays = days;
                          _scheduleStart = start;
                        },
                        onChanged: (times) {
                          _doseMinutes = times;
                          state.didChange(times);
                        },
                      ),
                    ),
                    if (state.hasError)
                      CareNotice(state.errorText!, error: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _field(
                'Posiadane pełne opakowania',
                _packages,
                numeric: true,
                validator: (v) => _validateNumber(v, integer: true),
              ),
              _field(
                'Dodatkowe jednostki z otwartego opakowania',
                _looseUnits,
                numeric: true,
                validator: (v) => _validateNumber(v),
              ),
              const Text(
                'Zapas możesz uzupełnić później. Dodatkowe jednostki '
                'wpisz w tej samej jednostce co ilość w opakowaniu.',
              ),
              const SizedBox(height: 16),
              if (widget.prescriptionSource != null)
                FormField<bool>(
                  initialValue: false,
                  validator: (value) => value == true
                      ? null
                      : 'Sprawdź dane leku i zaznacz potwierdzenie.',
                  builder: (state) => Column(
                    children: [
                      CheckboxListTile(
                        key: const Key('confirmPrescription'),
                        value: state.value ?? false,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Sprawdziłem nazwę, dawkowanie i godziny z zaleceniem',
                        ),
                        onChanged: state.didChange,
                      ),
                      if (state.hasError)
                        CareNotice(state.errorText!, error: true),
                    ],
                  ),
                ),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Zapisz lek'),
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

  Widget _field(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    bool numeric = false,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) => CareField(
    label: label,
    child: TextFormField(
      key: ValueKey('medication-$label'),
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : maxLines > 1
          ? TextInputType.multiline
          : TextInputType.text,
      decoration: InputDecoration(hintText: hint, hintMaxLines: 4),
      validator: validator,
    ),
  );
}

String formatQuantity(double value) =>
    (value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString())
        .replaceAll('.', ',');
