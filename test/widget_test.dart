import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:m_opiekun/auth/auth_service.dart';
import 'package:m_opiekun/main.dart';

void main() {
  testWidgets('prototyp pokazuje pięć ekranów', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(OpiekunApp(auth: AuthService()));

    await tester.enterText(find.byType(TextField).first, 'user1');
    await tester.enterText(find.byType(TextField).last, 'helpMe');
    await tester.tap(find.text('Zaloguj się'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Dziś'), findsOneWidget);
    expect(find.text('Dzień dobry'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Leki'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Leki'), findsOneWidget);
    expect(find.textContaining('Dawki na dziś'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Zdrowie'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Zdrowie'), findsOneWidget);
    expect(find.textContaining('Karta medyczna'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Wizyty'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Wizyty'), findsOneWidget);
    expect(find.textContaining('Nadchodzące wizyty'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Strefa'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Strefa'), findsOneWidget);
    expect(find.textContaining('Status pobytu'), findsOneWidget);
  });
}
