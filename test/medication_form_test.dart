import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_opiekun/models/medication.dart';
import 'package:m_opiekun/screens/medications_screen.dart';
import 'package:m_opiekun/widgets/medication_form.dart';

const product = MedicationProduct(
  name: 'Lek testowy',
  strength: '5 mg',
  pharmaceuticalForm: 'Tabletki',
  packageDescription: '30 tabl.',
  packageQuantity: 30,
  packageUnit: 'tabletki',
  gtin: '05909990672516',
);

Finder field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  testWidgets(
    'existing scanner button fills form; saves user dosing and stock',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var scans = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MedicationsScreen(
            scanMedication: (_) async {
              scans++;
              return product;
            },
          ),
        ),
      );
      await tester.scrollUntilVisible(find.text('Dodaj lek'), 300);
      await tester.tap(find.text('Dodaj lek'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zeskanuj kod kreskowy'));
      await tester.pumpAndSettle();
      expect(scans, 1);
      expect(find.text('Rozpoznano lek'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(field('Nazwa leku')).controller!.text,
        'Lek testowy',
      );
      expect(
        tester.widget<TextFormField>(field('Moc')).controller!.text,
        '5 mg',
      );
      expect(
        tester
            .widget<TextFormField>(field('Ilość w jednym opakowaniu'))
            .controller!
            .text,
        '30',
      );
      expect(
        tester
            .widget<TextFormField>(field('Dawkowanie według zaleceń lekarza'))
            .controller!
            .text,
        isEmpty,
      );
      await tester.enterText(
        field('Dawkowanie według zaleceń lekarza'),
        '1/2 tabletki raz dziennie',
      );
      await tester.enterText(field('Posiadane pełne opakowania'), '2');
      await tester.enterText(
        field('Dodatkowe jednostki z otwartego opakowania'),
        '0,5',
      );
      await tester.ensureVisible(find.text('Zapisz lek'));
      await tester.tap(find.text('Zapisz lek'));
      await tester.pumpAndSettle();
      expect(find.byType(MedicationForm), findsNothing);
      expect(find.text('Lek testowy 5 mg'), findsOneWidget);
      expect(find.text('Zapas: 60,5 tabletki'), findsOneWidget);
      expect(find.text('1/2 tabletki raz dziennie'), findsOneWidget);
    },
  );

  testWidgets('cancelled scan does not open or save a form', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: MedicationsScreen(scanMedication: (_) async => null)),
    );
    await tester.scrollUntilVisible(find.text('Dodaj lek'), 300);
    await tester.tap(find.text('Dodaj lek'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zeskanuj kod kreskowy'));
    await tester.pumpAndSettle();
    expect(find.byType(MedicationForm), findsNothing);
    expect(find.textContaining('Dodano lek:'), findsNothing);
  });

  testWidgets('unknown package stays blank; rejects negative stock', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MedicationForm(
            product: MedicationProduct(
              name: 'Zestaw',
              strength: '',
              pharmaceuticalForm: '',
              packageDescription: '1 fiolka + 1 rozpuszczalnik',
              packageQuantity: null,
              packageUnit: null,
              gtin: '05909990672516',
            ),
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<TextFormField>(field('Ilość w jednym opakowaniu'))
          .controller!
          .text,
      isEmpty,
    );
    await tester.enterText(field('Posiadane pełne opakowania'), '-1');
    await tester.ensureVisible(find.text('Zapisz lek'));
    await tester.tap(find.text('Zapisz lek'));
    await tester.pumpAndSettle();
    expect(find.text('Wpisz liczbę całkowitą, co najmniej 0.'), findsOneWidget);
    expect(find.byType(MedicationForm), findsOneWidget);
  });
}
