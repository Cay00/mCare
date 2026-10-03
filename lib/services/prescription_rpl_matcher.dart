import '../models/medication.dart';
import '../models/prescription.dart';

/// Exact token matching with a small, explicit dictionary of printed abbreviations.
/// No edit distance, name guessing, dose inference or package/GTIN inference.
String _normalized(String value) {
  var text = value.toLowerCase().replaceAll(',', '.');
  const equivalents = {
    r'\bdaw(?:k[ęai])?\.?': 'dawka',
    r'\btabl\.?': 'tabletki',
    r'\bkaps\.?': 'kapsułki',
  };
  for (final entry in equivalents.entries) {
    text = text.replaceAll(
      RegExp('${entry.key}(?=\\s|/|\$|[,;)])'),
      entry.value,
    );
  }
  return text
      .replaceAll(RegExp(r'(?<=\d)\s+(?=[a-z])'), '')
      .replaceAll(RegExp(r'[^a-ząćęłńóśźż0-9]+'), ' ')
      .trim();
}

bool _contains(String text, String part) =>
    part.isNotEmpty && ' $text '.contains(' $part ');

PrescriptionDraft matchPrescriptionToRpl(
  PrescriptionDraft draft,
  Iterable<MedicationProduct> products,
) {
  final title = _normalized(draft.product.name);
  final candidates = <String, MedicationProduct>{};
  for (final product in products) {
    if (!_contains(title, _normalized(product.name))) continue;
    // Collapse packaging variants only; strength and form must remain distinct.
    final key =
        '${product.name}|${product.strength}|${product.pharmaceuticalForm}';
    candidates[key] = product;
  }
  final matches = candidates.values
      .where(
        (product) =>
            _contains(title, _normalized(product.strength)) &&
            _contains(title, _normalized(product.pharmaceuticalForm)),
      )
      .toList();
  // Another complete product name in the title is not harmless surrounding text.
  final names = candidates.values.map((p) => _normalized(p.name)).toSet();
  final matched = matches.length == 1 && names.length == 1
      ? matches.single
      : null;
  return PrescriptionDraft(
    product: matched == null
        ? draft.product
        : MedicationProduct(
            name: matched.name,
            strength: matched.strength,
            pharmaceuticalForm: matched.pharmaceuticalForm,
            packageDescription: draft.product.packageDescription,
            packageQuantity: draft.product.packageQuantity,
            packageUnit: draft.product.packageUnit,
            gtin: null,
          ),
    instruction: draft.instruction,
    sourceText: draft.sourceText,
    prescribedPackages: draft.prescribedPackages,
    warnings: [
      ...draft.warnings,
      matched == null
          ? 'Nie potwierdzono jednoznacznie nazwy, mocy i postaci w RPL. Sprawdź dane z recepty.'
          : 'Nazwa, moc i postać dopasowane do RPL. Sprawdź zgodność z receptą. Opakowanie pozostaje odczytane z PDF.',
    ],
  );
}
