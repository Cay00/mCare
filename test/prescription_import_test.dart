import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_opiekun/models/prescription.dart';
import 'package:m_opiekun/screens/medications_screen.dart';
import 'package:m_opiekun/screens/prescription_import_screen.dart';
import 'package:m_opiekun/services/prescription_parser.dart';
import 'package:m_opiekun/theme/app_theme.dart';
import 'package:m_opiekun/widgets/medication_form.dart';

final draft = parsePrescription('''Recepta 1 z 1
Lek testowy 5 mg
2 op. po 30 tabl.
D.S. 3 x 1
Odpłatność 100%''').items.single;

PrescriptionImport result() => PrescriptionImport(
  items: [draft],
  warnings: [],
  pdfBytes: Uint8List(0),
  usedOcr: false,
);

Future<void> visibleTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'PDF import requires review; selected first time creates daily doses, not stock',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: MedicationsScreen(readPrescription: (_) async => result()),
          ),
        ),
      );
      await visibleTap(tester, find.byKey(const Key('importPrescription')));
      await visibleTap(tester, find.byKey(const Key('selectPrescriptionPdf')));
      await tester.scrollUntilVisible(
        find.byKey(const Key('savePrescriptionImport')),
        250,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('savePrescriptionImport')),
            )
            .onPressed,
        isNull,
      );
      await visibleTap(
        tester,
        find.byKey(const ValueKey('review-prescription-0')),
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(
                const ValueKey('medication-Dawkowanie według zaleceń lekarza'),
              ),
            )
            .controller!
            .text,
        '3 x 1',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(
                const ValueKey('medication-Posiadane pełne opakowania'),
              ),
            )
            .controller!
            .text,
        isEmpty,
      );
      await visibleTap(tester, find.text('Ustaw liczbę dawek z recepty: 3'));
      await visibleTap(tester, find.byKey(const ValueKey('dose-time-0')));
      await tester.enterText(find.byKey(const ValueKey('dose-hour')), '09');
      await tester.enterText(find.byKey(const ValueKey('dose-minute')), '30');
      await visibleTap(tester, find.text('Ustaw'));
      expect(find.text('Dawka 2: 17:30'), findsOneWidget);
      expect(find.text('Dawka 3: 01:30'), findsOneWidget);
      await visibleTap(tester, find.text('Zapisz lek'));
      expect(find.byType(MedicationForm), findsOneWidget);
      expect(
        find.text('Sprawdź dane leku i zaznacz potwierdzenie.'),
        findsOneWidget,
      );
      await visibleTap(tester, find.byKey(const Key('confirmPrescription')));
      await visibleTap(tester, find.text('Zapisz lek'));
      expect(find.byType(MedicationForm), findsNothing);
      await visibleTap(tester, find.byKey(const Key('savePrescriptionImport')));
      expect(find.byType(PrescriptionImportScreen), findsNothing);
      await tester.scrollUntilVisible(find.text('09:30'), 300, maxScrolls: 40);
      await tester.pumpAndSettle();
      expect(find.text('09:30'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Zapas do uzupełnienia'),
        300,
        maxScrolls: 40,
      );
      expect(find.text('Zapas do uzupełnienia'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancel selection and unreadable document never enable import', (
    tester,
  ) async {
    for (final loaded in [
      null,
      PrescriptionImport(
        items: [],
        warnings: ['Brak danych'],
        pdfBytes: Uint8List(0),
        usedOcr: false,
      ),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: PrescriptionImportScreen(readPrescription: (_) async => loaded),
        ),
      );
      await visibleTap(tester, find.byKey(const Key('selectPrescriptionPdf')));
      expect(find.byKey(const Key('savePrescriptionImport')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
