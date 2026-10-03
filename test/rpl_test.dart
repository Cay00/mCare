import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_opiekun/models/medication.dart';
import 'package:m_opiekun/services/rpl_repository.dart';
import 'package:m_opiekun/services/rpl_xml.dart';
import 'package:xml/xml.dart';

class _Bundle extends CachingAssetBundle {
  _Bundle(this.bytes);
  final List<int> bytes;
  int loads = 0;
  @override
  Future<ByteData> load(String key) async {
    loads++;
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('real namespace-qualified RPL: package-specific tablets and liquid', () {
    final xml = XmlDocument.parse(
      File('test/fixtures/rpl_sample.xml').readAsStringSync(),
    );
    final products = xml.rootElement.childElements
        .expand(productsFromRpl)
        .toList();
    final acard = products.singleWhere((p) => p.gtin == '05909990672516');
    expect(acard.toJson(), {
      'name': 'Acard',
      'strength': '75 mg',
      'pharmaceuticalForm': 'Tabletki dojelitowe',
      'packageDescription': '30 tabl.',
      'packageQuantity': 30.0,
      'packageUnit': 'tabletki',
      'gtin': '05909990672516',
    });
    expect(
      products.singleWhere((p) => p.gtin == '05909990672523').packageQuantity,
      60,
    );
    final liquid = products.singleWhere((p) => p.gtin == '05909991023669');
    expect(liquid.packageDescription, '4 fiol. 5 ml');
    expect(liquid.packageQuantity, 20);
    expect(liquid.packageUnit, 'ml');
  });

  test('ambiguous, mixed and textual packages preserve descriptions', () {
    for (final fields in [
      '<jednostkaOpakowania pojemnosc="30 lub 60" jednostkaPojemnosci="tabl."/>',
      '<jednostkaOpakowania liczbaOpakowan="1" pojemnosc="100" jednostkaPojemnosci="ml" informacjeDodatkowe="lub 2 po 50 ml"/>',
      '<jednostkaOpakowania liczbaOpakowan="1" pojemnosc="5" jednostkaPojemnosci="ml"/>'
          '<jednostkaOpakowania liczbaOpakowan="1" rodzajOpakowania="igła"/>',
      '<jednostkaOpakowania rodzajOpakowania="butelka" pojemnosc="100" jednostkaPojemnosci="ml"/>',
      '<jednostkaOpakowania pojemnosc="30" jednostkaPojemnosci="nieznana"/>',
    ]) {
      final result = readRplPackage(
        XmlDocument.parse('<opakowanie>$fields</opakowanie>').rootElement,
      );
      expect(result.quantity, isNull);
      expect(result.unit, isNull);
      expect(result.description, isNotEmpty);
    }
  });

  test(
    'decimal capacity and explicit container count; no strength conversion',
    () {
      final result = readRplPackage(
        XmlDocument.parse(
          '<opakowanie>'
          '<jednostkaOpakowania liczbaOpakowan="2" rodzajOpakowania="butelka" '
          'pojemnosc="100,5" jednostkaPojemnosci="ml"/></opakowanie>',
        ).rootElement,
      );
      expect(result.quantity, 201);
      expect(result.unit, 'ml');
    },
  );

  test('excludes deleted, veterinary, missing and invalid GTIN packages', () {
    String product(String kind, String deleted, String gtin) =>
        '<produktLeczniczy rodzajPreparatu="$kind" nazwaProduktu="Test">'
        '<opakowania><opakowanie skasowane="$deleted" kodGTIN="$gtin"/>'
        '</opakowania></produktLeczniczy>';
    for (final xml in [
      product('weterynaryjny', 'NIE', '05909990672516'),
      product('ludzki', 'TAK', '05909990672516'),
      product('ludzki', 'NIE', ''),
      product('ludzki', 'NIE', '05909990672517'),
    ]) {
      expect(productsFromRpl(XmlDocument.parse(xml).rootElement), isEmpty);
    }
  });

  test(
    'shipped index resolves equivalent codes, loads once and returns null for missing',
    () async {
      final bundle = _Bundle(
        await File('assets/data/rpl_packages.json.gz').readAsBytes(),
      );
      final repository = RplRepository(bundle: bundle);
      final ean = await repository.findByBarcode('5909990672516');
      final gtin = await repository.findByBarcode('05909990672516');
      expect(ean!.name, 'Acard');
      expect(gtin!.toJson(), ean.toJson());
      expect(await repository.findByBarcode('1234567890128'), isNull);
      expect(bundle.loads, 1);
      await expectLater(repository.findByBarcode('bad'), throwsFormatException);
    },
  );

  test('ambiguous code is not a guessed match', () async {
    final bundle = _Bundle(
      gzip.encode(
        utf8.encode(
          jsonEncode({
            'schemaVersion': 1,
            'packages': {},
            'ambiguousGtins': ['05909990672516'],
          }),
        ),
      ),
    );
    await expectLater(
      RplRepository(bundle: bundle).findByBarcode('5909990672516'),
      throwsA(isA<AmbiguousMedicationException>()),
    );
  });

  test(
    'corrupt index is an error, not a not-found; loading can be retried',
    () async {
      final bundle = _Bundle([1, 2, 3]);
      final repository = RplRepository(bundle: bundle);
      await expectLater(
        repository.findByBarcode('5909990672516'),
        throwsA(anything),
      );
      await expectLater(
        repository.findByBarcode('5909990672516'),
        throwsA(anything),
      );
      expect(bundle.loads, 2);
    },
  );

  test(
    'stock combines packages and loose units without inventing unknown quantities',
    () {
      const product = MedicationProduct(
        name: 'Test',
        strength: '5 mg',
        pharmaceuticalForm: 'Tabletki',
        packageDescription: '30 tabl.',
        packageQuantity: 30,
        packageUnit: 'tabletki',
        gtin: null,
      );
      const stock = MedicationStock(
        product: product,
        instruction: '1/2 tabletki raz dziennie',
        ownedPackages: 2,
        looseUnits: 0.5,
      );
      expect(stock.totalUnits, 60.5);
      expect(
        const MedicationStock(product: product, instruction: '').totalUnits,
        isNull,
      );
      const unknown = MedicationProduct(
        name: 'Test',
        strength: '',
        pharmaceuticalForm: '',
        packageDescription: 'zestaw',
        packageQuantity: null,
        packageUnit: null,
        gtin: null,
      );
      expect(
        const MedicationStock(
          product: unknown,
          instruction: '',
          ownedPackages: 2,
        ).totalUnits,
        isNull,
      );
    },
  );
}
