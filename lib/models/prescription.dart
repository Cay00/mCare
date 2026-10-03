import 'dart:typed_data';
import 'medication.dart';

class PrescriptionDraft {
  const PrescriptionDraft({
    required this.product,
    required this.instruction,
    required this.sourceText,
    required this.prescribedPackages,
    required this.warnings,
  });
  final MedicationProduct product;
  final String instruction;
  final String sourceText;
  final int? prescribedPackages;
  final List<String> warnings;
}

class PrescriptionImport {
  const PrescriptionImport({
    required this.items,
    required this.warnings,
    required this.pdfBytes,
    required this.usedOcr,
  });
  final List<PrescriptionDraft> items;
  final List<String> warnings;
  final Uint8List pdfBytes;
  final bool usedOcr;
}
