import 'package:flutter/material.dart';

import '../models/medication.dart';

Future<MedicationStock?> showMedicationForm(
  BuildContext context, {
  MedicationProduct? product,
}) => showModalBottomSheet<MedicationStock>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (_) => MedicationForm(product: product),
);

class MedicationForm extends StatefulWidget {
  const MedicationForm({this.product, super.key});
  final MedicationProduct? product;

  @override
  State<MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<MedicationForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _strength = TextEditingController(text: widget.product?.strength);
  late final _shape = TextEditingController(
    text: widget.product?.pharmaceuticalForm,
  );
  late final _description = TextEditingController(
    text: widget.product?.packageDescription,
  );
  late final _quantity = TextEditingController(
    text: widget.product?.packageQuantity == null
        ? ''
        : formatQuantity(widget.product!.packageQuantity!),
  );
  late final _unit = TextEditingController(text: widget.product?.packageUnit);
  final _instruction = TextEditingController();
  final _packages = TextEditingController();
  final _looseUnits = TextEditingController();

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
    if (!_form.currentState!.validate()) return;
    final product = MedicationProduct(
      name: _name.text.trim(),
      strength: _strength.text.trim(),
      pharmaceuticalForm: _shape.text.trim(),
      packageDescription: _description.text.trim(),
      packageQuantity: _number(_quantity.text),
      packageUnit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
      gtin: widget.product?.gtin,
    );
    Navigator.of(context).pop(
      MedicationStock(
        product: product,
        instruction: _instruction.text.trim(),
        ownedPackages: _number(_packages.text)?.toInt(),
        looseUnits: _number(_looseUnits.text),
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
                scanned ? 'Rozpoznano lek' : 'Dodaj nowy lek',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
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
              _field(
                'Dawkowanie według zaleceń lekarza',
                _instruction,
                maxLines: 2,
                hint: 'Wpisz zalecenie — możesz uzupełnić później',
              ),
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
              FilledButton(onPressed: _save, child: const Text('Zapisz lek')),
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
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : maxLines > 1
          ? TextInputType.multiline
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    ),
  );
}

String formatQuantity(double value) =>
    (value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString())
        .replaceAll('.', ',');
