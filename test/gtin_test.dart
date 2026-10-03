import 'package:flutter_test/flutter_test.dart';
import 'package:m_opiekun/services/gtin.dart';

void main() {
  test('EAN-13 and zero-padded GTIN-14 identify the same package', () {
    expect(normalizeGtin('5909990672516'), '05909990672516');
    expect(normalizeGtin(' 05909990672516 '), '05909990672516');
    expect(normalizeGtin('15909990672513'), '15909990672513');
  });

  test('rejects bad checksum, truncated, overlong and non-numeric codes', () {
    for (final code in [
      '5909990672517',
      '590999067251',
      '059099906725160',
      '0000000000000',
      'Acard 75 mg',
      '5909990672516x',
    ]) {
      expect(gtinFromBarcode(code), isNull, reason: code);
    }
  });

  test('GS1 AI 01 with expiry, lot, serial and symbology prefix', () {
    for (final code in [
      '(01)05909990672516(17)281231(10)BATCH(21)SERIAL',
      ']d201059099906725161728123110BATCH\u001d21SERIAL',
      '01059099906725161728123110BATCH\u001d21SERIAL',
      ']C1172812310105909990672516',
      '(17)281231(01)05909990672516',
      '10BATCH\u001d0105909990672516',
    ]) {
      expect(gtinFromBarcode(code), '05909990672516', reason: code);
    }
  });

  test('does not search inside serial/lot or accept malformed AI 01', () {
    for (final code in [
      '21SERIAL0105909990672516',
      '(01)5909990672516',
      '(01)05909990672517',
      '(01)059099906725160',
      '(21)0105909990672516',
      '(01)05909990672516(01)05909990672516',
    ]) {
      expect(gtinFromBarcode(code), isNull, reason: code);
    }
  });
}
