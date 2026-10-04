import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_opiekun/widgets/medication_form.dart';
import 'package:m_opiekun/screens/prescription_import_screen.dart';

void main() {
  for (final keyboard in [0.0, 300.0]) {
    testWidgets('medication form avoids system bar and keyboard $keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewPadding = const FakeViewPadding(bottom: 48);
      tester.view.padding = FakeViewPadding(bottom: keyboard == 0 ? 48 : 0);
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showMedicationForm(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Zapisz lek'));
      await tester.pumpAndSettle();
      final rect = tester.getRect(
        find.widgetWithText(FilledButton, 'Zapisz lek'),
      );
      expect(
        rect.bottom,
        lessThanOrEqualTo(844 - (keyboard == 0 ? 48 : keyboard)),
      );
      expect(rect.top, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('prescription viewport excludes system navigation area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    tester.view.padding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: PrescriptionImportScreen()),
    );
    expect(
      tester.getRect(find.byType(ListView)).bottom,
      lessThanOrEqualTo(796),
    );
    expect(tester.takeException(), isNull);
  });
}
