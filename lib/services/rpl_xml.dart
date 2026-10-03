import 'package:xml/xml.dart';

import '../models/medication.dart';
import 'gtin.dart';

const rplReportUrl =
    'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/'
    'public-pl-report/6.0.0/overall.xml';
const rplNamespace =
    'http://rejestry.ezdrowie.gov.pl/rpl/eksport-danych-v6.0.0';

String _attribute(XmlElement node, String name) =>
    node.getAttribute(name)?.trim() ?? '';

double? _positiveNumber(String text) {
  if (!RegExp(r'^\d+(?:[.,]\d+)?$').hasMatch(text)) return null;
  final number = double.tryParse(text.replaceAll(',', '.'));
  return number != null && number.isFinite && number > 0 ? number : null;
}

/// Only explicit units from RPL; no conversion from strength or form.
const _units = {
  'tabl.': 'tabletki',
  'tabletek': 'tabletki',
  'kaps.': 'kapsułki',
  'kapsułek': 'kapsułki',
  'ml': 'ml',
  'g': 'g',
  'mg': 'mg',
  'dawka': 'dawki',
  'dawki': 'dawki',
  'dawek': 'dawki',
  'pastylki': 'pastylki',
  'pastylek': 'pastylki',
  'plastry': 'plastry',
  'plastrów': 'plastry',
};

({String description, double? quantity, String? unit}) readRplPackage(
  XmlElement package,
) {
  final parts = package.findAllElements('jednostkaOpakowania').toList();
  final description = parts
      .map((part) {
        final count = _attribute(part, 'liczbaOpakowan');
        final container = _attribute(part, 'rodzajOpakowania');
        final capacity = _attribute(part, 'pojemnosc');
        final unit = _attribute(part, 'jednostkaPojemnosci');
        final extra = _attribute(part, 'informacjeDodatkowe');
        return [
          count,
          container,
          capacity,
          unit,
          extra,
        ].where((value) => value.isNotEmpty).join(' ');
      })
      .where((part) => part.isNotEmpty)
      .join(' + ');

  // Mixed kits (e.g. medicine + solvent/needle) are intentionally not summed.
  if (parts.length != 1) {
    return (description: description, quantity: null, unit: null);
  }
  final part = parts.single;
  final countText = _attribute(part, 'liczbaOpakowan');
  final container = _attribute(part, 'rodzajOpakowania');
  final capacity = _positiveNumber(_attribute(part, 'pojemnosc'));
  final unit = _units[_attribute(part, 'jednostkaPojemnosci')];
  final count = countText.isEmpty && container.isEmpty
      ? 1.0
      : _positiveNumber(countText);
  // Free text can describe alternatives/combinations. Keep it verbatim and
  // leave the quantity for confirmation instead of interpreting it.
  if (_attribute(part, 'informacjeDodatkowe').isNotEmpty ||
      capacity == null ||
      count == null ||
      count != count.roundToDouble() ||
      unit == null) {
    return (description: description, quantity: null, unit: null);
  }
  final quantity = count * capacity;
  if (!quantity.isFinite ||
      (!{'ml', 'g', 'mg'}.contains(unit) &&
          quantity != quantity.roundToDouble())) {
    return (description: description, quantity: null, unit: null);
  }
  return (description: description, quantity: quantity, unit: unit);
}

Iterable<MedicationProduct> productsFromRpl(XmlElement product) sync* {
  if (_attribute(product, 'rodzajPreparatu') != 'ludzki') return;
  final name = _attribute(product, 'nazwaProduktu');
  if (name.isEmpty) return;
  for (final package in product.findAllElements('opakowanie')) {
    if (_attribute(package, 'skasowane') != 'NIE') continue;
    final gtin = normalizeGtin(_attribute(package, 'kodGTIN'));
    if (gtin == null) continue;
    final details = readRplPackage(package);
    yield MedicationProduct(
      name: name,
      strength: _attribute(product, 'moc'),
      pharmaceuticalForm: _attribute(product, 'nazwaPostaciFarmaceutycznej'),
      packageDescription: details.description,
      packageQuantity: details.quantity,
      packageUnit: details.unit,
      gtin: gtin,
    );
  }
}
