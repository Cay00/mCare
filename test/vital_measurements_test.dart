import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_opiekun/screens/health_screen.dart';
import 'package:m_opiekun/services/vital_store.dart';
import 'package:m_opiekun/theme/app_theme.dart';
import 'package:m_opiekun/widgets/vital_week_chart.dart';

void main() {
  test('walidacja odrzuca wynik poza zakresem', () {
    expect(validateVitalPrimary(VitalKind.glucose, '10'), isNotNull);
    expect(validateVitalPrimary(VitalKind.glucose, '126'), isNull);
    expect(validateVitalPrimary(VitalKind.weight, '72,5'), isNull);
    expect(validateVitalPrimary(VitalKind.temperature, '36,6'), isNull);
    expect(validateDiastolic('140', '90'), isNull);
    expect(validateDiastolic('80', '90'), isNotNull);
  });

  test('formatuje ciśnienie i wagę z przecinkiem', () {
    expect(
      formatVitalValue(
        VitalReading(
          kind: VitalKind.bloodPressure,
          at: DateTime(2026, 10, 4),
          primary: 128,
          secondary: 76,
        ),
      ),
      '128/76 mmHg',
    );
    expect(
      formatVitalValue(
        VitalReading(
          kind: VitalKind.weight,
          at: DateTime(2026, 10, 4),
          primary: 72.5,
        ),
      ),
      '72,5 kg',
    );
  });

  testWidgets('pomiary są kafelkami w dwóch kolumnach', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: HealthScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final sugar = find.byKey(const Key('vital-tile-glucose'));
    await tester.scrollUntilVisible(sugar, 200);
    await tester.pumpAndSettle();
    final pressure = find.byKey(const Key('vital-tile-bloodPressure'));
    expect(tester.getTopLeft(sugar).dy, tester.getTopLeft(pressure).dy);
    expect(
      tester.getTopLeft(pressure).dx,
      greaterThan(tester.getTopLeft(sugar).dx),
    );
    expect(find.text('Tętno'), findsNothing);
    expect(find.text('Waga'), findsOneWidget);
    expect(find.text('Temperatura'), findsOneWidget);
    expect(find.text('Saturacja'), findsOneWidget);

    expect(find.text('Wykresy z ostatnich 7 dni'), findsNothing);

    await tester.ensureVisible(sugar);
    await tester.tap(
      find.descendant(of: sugar, matching: find.byType(InkWell)),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Poziom cukru'), findsOneWidget);
    expect(find.textContaining('mg/dl'), findsOneWidget);

    await tester.tap(find.text('Zapisz dzisiejszy pomiar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Wpisz wynik glukozy z dzisiejszego pomiaru.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), '10');
    await tester.tap(find.text('Zapisz pomiar'));
    await tester.pumpAndSettle();
    expect(find.text('Podaj cukier w zakresie 20–600 mg/dl.'), findsOneWidget);
  });

  testWidgets('przy dużym tekście kafelki układają się w jednej kolumnie', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const Scaffold(body: HealthScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final sugar = find.byKey(const Key('vital-tile-glucose'));
    await tester.scrollUntilVisible(sugar, 300, maxScrolls: 40);
    await tester.pumpAndSettle();
    final pressure = find.byKey(const Key('vital-tile-bloodPressure'));
    await tester.scrollUntilVisible(pressure, 300, maxScrolls: 40);
    expect(
      tester.getTopLeft(pressure).dy,
      greaterThan(tester.getTopLeft(sugar).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('wykres pokazuje wartości z ostatnich dni', (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: VitalWeekChart(
            kind: VitalKind.glucose,
            readings: [
              VitalReading(
                kind: VitalKind.glucose,
                at: DateTime(now.year, now.month, now.day),
                primary: 126,
              ),
              VitalReading(
                kind: VitalKind.glucose,
                at: DateTime(now.year, now.month, now.day - 1),
                primary: 118,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('126'), findsOneWidget);
    expect(find.text('118'), findsOneWidget);
    expect(find.textContaining('mg/dl'), findsOneWidget);
  });
}
