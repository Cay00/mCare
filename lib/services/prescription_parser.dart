import '../models/medication.dart';
import '../models/prescription.dart';
import 'prescription_dosing.dart';

class PrescriptionParseResult {
  const PrescriptionParseResult(this.items, this.warnings);
  final List<PrescriptionDraft> items;
  final List<String> warnings;
}

/// Reads explicit printed prescription blocks, never patient/access identifiers.
/// D.S. stays verbatim: no inferred amounts, frequency, clock times or GTIN.
PrescriptionParseResult parsePrescription(String text) {
  final normalized = text
      .replaceAll('\r', '\n')
      .replaceAll('\u00a0', ' ')
      .replaceAllMapped(
        RegExp(r'\b(D\s*\.\s*S\s*\.?|Dawkowanie\s*:)', caseSensitive: false),
        (m) => '\n${m[0]}',
      )
      .replaceAllMapped(
        RegExp(r'\b(Odpłatność|Odplatnosc)', caseSensitive: false),
        (m) => '\n${m[0]}',
      );
  final headers = RegExp(
    r'\bRecepta\s+(\d+)\s+z\s+(\d+)(?:\s+ogółem)?',
    caseSensitive: false,
  ).allMatches(normalized).toList();
  final items = <PrescriptionDraft>[];
  final warnings = <String>[];
  if (headers.isEmpty) {
    return const PrescriptionParseResult([], [
      'Nie rozpoznano bloków „Recepta X z Y”. Wybierz PDF e-recepty lub wpisz lek ręcznie.',
    ]);
  }
  final totals = headers.map((m) => int.parse(m[2]!)).toSet();
  if (totals.length == 1 &&
      headers.map((m) => m[1]).toSet().length < totals.single) {
    warnings.add(
      'Dokument może być niepełny: odczytano ${headers.length} z ${totals.single} pozycji.',
    );
  }
  for (var i = 0; i < headers.length; i++) {
    final block = normalized.substring(
      headers[i].end,
      i + 1 < headers.length ? headers[i + 1].start : normalized.length,
    );
    final lines = block
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    // End before reimbursement/footer, which can contain contact and patient data.
    final stop = lines.indexWhere(
      (s) => RegExp(
        r'^(Odpłatność|Odplatnosc|Wejdź|Wejdz|Oświadczam|Oswiadczam|Pacjent|Wystawca|Kod dostępu|Informacja o)',
        caseSensitive: false,
      ).hasMatch(s),
    );
    final content = (stop < 0 ? lines : lines.take(stop)).toList();
    content.removeWhere(_technicalLine);
    content.removeWhere((line) => RegExp(r'^\d+\s*%$').hasMatch(line));
    // Identifiers may precede the title. Numeric lines AFTER the title can be
    // dosing (e.g. D.S. on one line and 1-0-1 on the next) and must be retained.
    while (content.isNotEmpty &&
        (RegExp(r'^[\d\s.\-/]+$').hasMatch(content.first) ||
            RegExp(r'^\d{8,}[a-zA-Z]*\d*$').hasMatch(content.first))) {
      content.removeAt(0);
    }
    final ds = RegExp(
      r'^(?:D\s*\.?\s*S\s*\.?\s*:?|Dawkowanie\s*:)\s*',
      caseSensitive: false,
    );
    final dsIndex = content.indexWhere(
      (line) => ds.hasMatch(line) || recognizePrescriptionDosing(line) != null,
    );
    final quantityPattern = RegExp(
      r'^(\d+)\s*op\.?\s*(?:po\s+)?(.+)?$',
      caseSensitive: false,
    );
    final packageIndex = content.indexWhere(quantityPattern.hasMatch);
    final boundary = [
      if (dsIndex >= 0) dsIndex,
      if (packageIndex >= 0) packageIndex,
      content.length,
    ].reduce((a, b) => a < b ? a : b);
    final title = content
        .take(boundary)
        .join(' ')
        .replaceFirst(RegExp(r'\s*\|?\s*\d+\s*%\s*$'), '')
        .trim();
    if (title.isEmpty ||
        _technicalLine(title) ||
        !RegExp(r'[a-zA-ZąćęłńóśźżĄĆĘŁŃÓŚŹŻ]').hasMatch(title)) {
      warnings.add(
        'Nie odczytano nazwy leku w pozycji ${i + 1}. Sprawdź ją w PDF.',
      );
      continue;
    }
    final instruction = dsIndex < 0
        ? ''
        : content.skip(dsIndex).join('\n').replaceFirst(ds, '').trim();
    final packageMatch = packageIndex < 0
        ? null
        : quantityPattern.firstMatch(content[packageIndex]);
    final package = packageMatch?[2]?.trim() ?? '';
    final units = RegExp(
      r'^(\d+(?:[.,]\d+)?)\s*(tabl\.?|tabletek|tabletki|kaps\.?|kapsułek|kapsułki|ml|dawki|dawek|szt\.?)$',
      caseSensitive: false,
    ).firstMatch(package);
    final unit = switch (units?[2]?.toLowerCase()) {
      'tabl.' || 'tabl' || 'tabletek' || 'tabletki' => 'tabletki',
      'kaps.' || 'kaps' || 'kapsułek' || 'kapsułki' => 'kapsułki',
      'ml' => 'ml',
      'dawki' || 'dawek' => 'dawki',
      'szt.' || 'szt' => 'szt.',
      _ => null,
    };
    // Keep the printed title intact rather than guessing its name/form split.
    items.add(
      PrescriptionDraft(
        product: MedicationProduct(
          name: title,
          strength: '',
          pharmaceuticalForm: '',
          packageDescription: package,
          packageQuantity: units == null
              ? null
              : double.tryParse(units[1]!.replaceAll(',', '.')),
          packageUnit: unit,
          gtin: null,
        ),
        instruction: instruction,
        sourceText: content.join('\n'),
        prescribedPackages: int.tryParse(packageMatch?[1] ?? ''),
        warnings: [
          if (instruction.isEmpty)
            'Brak odczytanego dawkowania. Sprawdź zalecenie na recepcie.',
          if (units == null)
            'Nie odczytano jednoznacznej wielkości opakowania.',
        ],
      ),
    );
  }
  return PrescriptionParseResult(items, warnings);
}

bool _technicalLine(String line) {
  return RegExp(
        r'(?:Prefiks\s*ID|Prefix\s*ID|Kod\s+dostępu|Wystawiono|^Pacjent\b|^Wystawca\b|^PESEL\b|^PWZ\b)',
        caseSensitive: false,
      ).hasMatch(line) ||
      RegExp(r'^\d{1,3}(?:\.\d+){4,}$').hasMatch(line) ||
      RegExp(r'^\d{12,}(?:\s.*)?$').hasMatch(line) ||
      RegExp(r'^[A-Z0-9]{16,}$').hasMatch(line) ||
      RegExp(r'^\d{8,}[a-zA-Z]+\d*$').hasMatch(line);
}

/// Text length alone does not detect broken PDF font maps or barcode-only text.
bool prescriptionNeedsOcr(String text) {
  final parsed = parsePrescription(text);
  return parsed.items.isEmpty ||
      parsed.items.any((item) => item.instruction.isEmpty);
}
