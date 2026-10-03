import 'package:flutter_test/flutter_test.dart';
import 'package:m_opiekun/services/prescription_parser.dart';
import 'package:m_opiekun/services/dose_schedule.dart';
import 'package:m_opiekun/services/prescription_dosing.dart';

void main() {
  test(
    'recognizes explicit dosing without inventing schedules for extra instructions',
    () {
      expect(recognizePrescriptionDosing('D.S. 2x1')?.dailyCount, 2);
      expect(recognizePrescriptionDosing('D.S. 1x1')?.dailyCount, 1);
      expect(recognizePrescriptionDosing('1-0-1')?.amounts, ['1', '1']);
      expect(recognizePrescriptionDosing('1-0-2')?.amounts, ['1', '2']);
      expect(recognizePrescriptionDosing('2 × 1/2')?.amounts, ['1/2', '1/2']);
      for (final text in [
        '2x1 co drugi dzień',
        'doraźnie 1x1',
        '0x1',
        '2x1/0',
        '0-0-0',
      ]) {
        expect(recognizePrescriptionDosing(text), isNull);
      }
    },
  );
  test('barcode and OID text cannot become medication names', () {
    const ids =
        'ZZZZ8DCA4B32C65B37CZ20\n10500303495089270312369752664573748022567510 Prefiks ID\n2.16.840.1.113883.3.4424.2.7.41527.2.1';
    expect(parsePrescription('Recepta 1 z 1\n$ids').items, isEmpty);
    expect(prescriptionNeedsOcr('Recepta 1 z 1\n$ids'), isTrue);
    final item = parsePrescription(
      'Recepta 1 z 1\n$ids\nLek 5 mg\n1 op. po 30 tabl.\n1-0-1\nOdpłatność 100%',
    ).items.single;
    expect(item.product.name, 'Lek 5 mg');
    expect(item.instruction, '1-0-1');
    expect(item.product.packageQuantity, 30);
  });
  test('inline DS is separated from the medicine title', () {
    final item = parsePrescription(
      'Recepta 1 z 1\nLek 5 mg D.S. 2x1 Odpłatność 100%',
    ).items.single;
    expect(item.product.name, 'Lek 5 mg');
    expect(item.instruction, '2x1');
  });
  test(
    'patient/access identifiers are excluded; package count is not stock',
    () {
      final result = parsePrescription('''e-recepta
1050339443612496207226
Kod dostępu 6770 Wystawiono 10.04.2020
Pacjent Przykładowy Pacjent
Wystawca Testowy Lekarz
Recepta 1 z 1 0000000000mm307425305
Spasmolina kaps. twarde (60 mg) | 100%
2 op. po 20 szt.
D.S. 2 x 1
Odpłatność 100%
Wejdź na pacjent.gov.pl''');
      expect(result.items, hasLength(1));
      final item = result.items.single;
      expect(item.product.name, 'Spasmolina kaps. twarde (60 mg)');
      expect(item.instruction, '2 x 1');
      expect(item.prescribedPackages, 2);
      expect(item.product.packageQuantity, 20);
      expect(item.product.packageUnit, 'szt.');
      expect(item.product.gtin, isNull);
      expect(item.sourceText, isNot(contains('6770')));
      expect(item.sourceText, isNot(contains('Pacjent')));
    },
  );

  test(
    'separate blocks keep distinct D.S. and flag incomplete screenshot layout',
    () {
      final result = parsePrescription('''Recepta 1 z 5 ogółem
Lek (tab. powlekane) 30 tabl. /10mg
1 op. po 30 tabl.
D.S 1-0-1
Odpłatność: 20%

Recepta 2 z 5 ogółem
Lek (tab. powlekane) 5 tabl. /300mg
1 op. po 5 tabl.
D.S. 1-0-2
Odpłatność: 100%''');
      expect(result.items.map((i) => i.instruction), ['1-0-1', '1-0-2']);
      expect(result.items.map((i) => i.product.packageQuantity), [30, 5]);
      expect(result.warnings, isNotEmpty);
    },
  );

  test(
    'multiline dosing is copied without interpreting fractions or timing',
    () {
      final result = parsePrescription('''Recepta 1 z 1
Lek testowy 20 mg/ml
1 op. po 1 butelka 100 ml
Dawkowanie: 1/2 tabletki rano,
co drugi dzień, przez 7 dni
Odpłatność: 100%''');
      expect(
        result.items.single.instruction,
        '1/2 tabletki rano,\nco drugi dzień, przez 7 dni',
      );
      expect(result.items.single.product.packageQuantity, isNull);
      expect(
        result.items.single.product.packageDescription,
        '1 butelka 100 ml',
      );
    },
  );

  test('no headings means no guesses; missing dosing remains empty', () {
    expect(
      parsePrescription('Pacjent Jan Kowalski\nD.S. 2 x 1').items,
      isEmpty,
    );
    final result = parsePrescription(
      'Recepta 1 z 1\nLek testowy\n1 op. po 30 tabl.\nOdpłatność: 100%',
    );
    expect(result.items.single.instruction, isEmpty);
    expect(result.items.single.warnings, isNotEmpty);
  });

  test(
    'numeric dosing on its own line is preserved, not mistaken for an identifier',
    () {
      final result = parsePrescription(
        'Recepta 1 z 1\n1234567890123456789\nLek testowy\n1 op. po 30 tabl.\nD.S.\n1-0-1\nOdpłatność: 100%',
      );
      expect(result.items.single.instruction, '1-0-1');
      expect(result.items.single.product.name, 'Lek testowy');
    },
  );

  test('equal daily times, midnight wrap and fractional interval rounding', () {
    expect(evenlySpacedDoseMinutes(8 * 60, 1).map(doseTimeLabel), ['08:00']);
    expect(evenlySpacedDoseMinutes(8 * 60, 2).map(doseTimeLabel), [
      '08:00',
      '20:00',
    ]);
    expect(evenlySpacedDoseMinutes(8 * 60, 3).map(doseTimeLabel), [
      '08:00',
      '16:00',
      '00:00',
    ]);
    expect(evenlySpacedDoseMinutes(23 * 60 + 30, 4).map(doseTimeLabel), [
      '23:30',
      '05:30',
      '11:30',
      '17:30',
    ]);
    final seven = evenlySpacedDoseMinutes(0, 7);
    expect(seven, [0, 206, 411, 617, 823, 1029, 1234]);
    expect(() => evenlySpacedDoseMinutes(1440, 1), throwsArgumentError);
    expect(() => evenlySpacedDoseMinutes(0, 0), throwsArgumentError);
  });
}
