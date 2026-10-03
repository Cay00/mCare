import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_opiekun/models/medication.dart';
import 'package:m_opiekun/services/prescription_dosing.dart';
import 'package:m_opiekun/widgets/dose_schedule_editor.dart';

void main() {
  test(
    'calendar intervals skip intervening days across month and DST boundaries',
    () {
      final stock = MedicationStock(
        product: const MedicationProduct(
          name: 'Test',
          strength: '',
          pharmaceuticalForm: '',
          packageDescription: '',
          packageQuantity: null,
          packageUnit: null,
          gtin: null,
        ),
        instruction: '1x1 co dwa dni',
        doseMinutes: const [480],
        everyDays: 2,
        scheduleStart: DateTime(2026, 3, 28),
      );
      expect(stock.isScheduledOn(DateTime(2026, 3, 27)), false);
      expect(stock.isScheduledOn(DateTime(2026, 3, 28)), true);
      expect(stock.isScheduledOn(DateTime(2026, 3, 29)), false);
      expect(stock.isScheduledOn(DateTime(2026, 3, 30)), true);
      expect(stock.isScheduledOn(DateTime(2026, 4, 1)), true);
    },
  );
  for (final code in ['1x1', '2x1', '1-0-1 co dwa dni']) {
    testWidgets('$code creates exactly the required unset time fields', (
      tester,
    ) async {
      List<int>? times;
      int? interval;
      final dosing = recognizePrescriptionDosing(code)!;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DoseScheduleEditor(
                recognizedDosing: dosing,
                onChanged: (value) => times = value,
                onPatternChanged: (days, _) => interval = days,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(times, List.filled(dosing.dailyCount, -1));
      expect(interval, dosing.everyDays);
      expect(
        find.byKey(ValueKey('dose-time-${dosing.dailyCount - 1}')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('dose-time-${dosing.dailyCount}')),
        findsNothing,
      );
      if (code.startsWith('1-0-1')) {
        expect(
          find.text('Pierwsza dawka (rano): wybierz godzinę'),
          findsOneWidget,
        );
        expect(
          find.text('Dawka 2 (wieczorem): wybierz godzinę'),
          findsOneWidget,
        );
      }
    });
  }
}
