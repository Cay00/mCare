import 'package:flutter_test/flutter_test.dart';
import 'package:m_opiekun/models/medication.dart';
import 'package:m_opiekun/models/prescription.dart';
import 'package:m_opiekun/services/prescription_rpl_matcher.dart';
import 'package:m_opiekun/services/rpl_repository.dart';

MedicationProduct product({
  String name = 'Lek',
  String strength = '5 mg',
  String form = 'Tabletki',
  String gtin = '05900000000000',
}) => MedicationProduct(
  name: name,
  strength: strength,
  pharmaceuticalForm: form,
  packageDescription: '100 tabletek',
  packageQuantity: 100,
  packageUnit: 'tabletki',
  gtin: gtin,
);
PrescriptionDraft draft(String title) => PrescriptionDraft(
  product: MedicationProduct(
    name: title,
    strength: '',
    pharmaceuticalForm: '',
    packageDescription: '30 tabl.',
    packageQuantity: 30,
    packageUnit: 'tabletki',
    gtin: null,
  ),
  instruction: '1-0-1',
  sourceText: 'Oryginał',
  prescribedPackages: 2,
  warnings: [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'canonical fields replace title noise but never infer package GTIN or dosing',
    () {
      final result = matchPrescriptionToRpl(
        draft('Dodatkowy opis Lek tabl. 5 mg'),
        [product(), product(gtin: '05900000000017')],
      );
      expect(result.product.name, 'Lek');
      expect(result.product.strength, '5 mg');
      expect(result.product.pharmaceuticalForm, 'Tabletki');
      expect(result.product.gtin, isNull);
      expect(result.product.packageQuantity, 30);
      expect(result.instruction, '1-0-1');
      expect(result.sourceText, 'Oryginał');
      expect(result.prescribedPackages, 2);
    },
  );
  test('missing, conflicting or partial identities remain unconfirmed', () {
    final records = [
      product(),
      product(strength: '10 mg'),
      product(name: 'Lek Forte'),
    ];
    for (final title in [
      'Lek',
      'Lek 5 mg',
      'Lek tabl. 15 mg',
      'SuperLek tabl. 5 mg',
      'Lek Forte tabl. 5 mg',
      'Lek tabl. 5 mg 10 mg',
    ]) {
      final result = matchPrescriptionToRpl(draft(title), records);
      expect(result.product.name, title);
      expect(result.warnings.last, contains('Nie potwierdzono'));
    }
  });
  test(
    'actual scanner snapshot resolves printed strength abbreviation',
    () async {
      final records = await RplRepository().prescriptionProducts();
      final result = matchPrescriptionToRpl(
        draft('Lenzetto aerozol przezskórny, roztwór 1,53 mg/daw.'),
        records,
      );
      expect(result.product.name, 'Lenzetto');
      expect(result.product.strength, '1,53 mg/dawkę');
      expect(result.product.pharmaceuticalForm, 'Aerozol przezskórny, roztwór');
      expect(result.product.gtin, isNull);
    },
  );
}
