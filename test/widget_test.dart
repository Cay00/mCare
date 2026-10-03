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
    expect(find.text('Nawodnienie'), findsOneWidget);

    await tester.tap(find.text('Nawodnienie'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Nawodnienie'), findsOneWidget);
    expect(find.textContaining('małymi porcjami'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.drag(find.text('Porady'), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('dr Anna Nowak'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Profil'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Profil'), findsOneWidget);
    expect(find.text('Jakub B'), findsOneWidget);
    expect(find.text('Zmień hasło'), findsOneWidget);

    await tester.tap(find.text('Zmień hasło'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Zmiana hasła'), findsOneWidget);
    expect(find.text('Zapisz hasło'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('openSafeZone')));
    await tester.tap(find.byKey(const Key('openSafeZone')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Strefa'), findsOneWidget);
    expect(find.textContaining('Status pobytu'), findsOneWidget);
  });

  testWidgets('opiekun dostaje dane dopiero po zgodzie chorego', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(OpiekunApp(auth: AuthService()));

    await tester.tap(find.text('Zaloguj jako opiekun'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Profil'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('connectPatient')));
    await tester.tap(find.byKey(const Key('connectPatient')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('patientCodeField')),
      'JKB-1042',
    );
    await tester.tap(find.byKey(const Key('sendLinkRequest')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Czekamy, aż Jakub B'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zaloguj jako chory'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Profil'));
    await tester.pumpAndSettle();

    await _scrollProfileTo(tester, find.text('Strefa'));
    await tester.tap(find.text('Strefa'));
    await tester.pumpAndSettle();
    await _scrollProfileTo(tester, find.byKey(const Key('acceptShare')));
    await tester.tap(find.byKey(const Key('acceptShare')));
    await tester.pumpAndSettle();
    await _jumpProfileToTop(tester);
    expect(find.text('Widzi: Leki, Zdrowie, Wizyty'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zaloguj jako opiekun'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Profil'));
    await tester.pumpAndSettle();

    await _scrollProfileTo(tester, find.byKey(const Key('viewSharedData')));
    await tester.tap(find.byKey(const Key('viewSharedData')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('zgodził się pokazać: Leki, Zdrowie, Wizyty'),
      findsOneWidget,
    );
    expect(find.text('Prestarium 5 mg · przyjęty'), findsOneWidget);
    expect(find.text('A Rh+'), findsOneWidget);
    expect(find.textContaining('Strefa'), findsNothing);
  });
}

Future<void> _jumpProfileToTop(WidgetTester tester) async {
  final scrollable = find.descendant(
    of: find.byKey(const Key('profileScroll')),
    matching: find.byType(Scrollable),
  );
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pumpAndSettle();
}

Future<void> _scrollProfileTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.descendant(
      of: find.byKey(const Key('profileScroll')),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
}
