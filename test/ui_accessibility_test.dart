import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_opiekun/app_shell.dart';
import 'package:m_opiekun/auth/auth_service.dart';
import 'package:m_opiekun/models/wellness_guide.dart';
import 'package:m_opiekun/screens/appointments_screen.dart';
import 'package:m_opiekun/screens/change_password_screen.dart';
import 'package:m_opiekun/screens/connect_patient_screen.dart';
import 'package:m_opiekun/screens/health_screen.dart';
import 'package:m_opiekun/screens/home_screen.dart';
import 'package:m_opiekun/screens/login_screen.dart';
import 'package:m_opiekun/screens/medications_screen.dart';
import 'package:m_opiekun/screens/profile_screen.dart';
import 'package:m_opiekun/screens/safe_zone_screen.dart';
import 'package:m_opiekun/screens/shared_patient_screen.dart';
import 'package:m_opiekun/screens/vital_detail_screen.dart';
import 'package:m_opiekun/screens/wellness_guide_screen.dart';
import 'package:m_opiekun/services/vital_store.dart';
import 'package:m_opiekun/sharing/sharing_service.dart';
import 'package:m_opiekun/theme/app_theme.dart';
import 'package:m_opiekun/widgets/care_components.dart';
import 'package:m_opiekun/widgets/medication_form.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const fontPath = String.fromEnvironment('PREVIEW_FONT');
  const previews = bool.fromEnvironment('UI_PREVIEW');
  setUpAll(() async {
    if (fontPath.isNotEmpty) {
      final loader = FontLoader('Roboto')
        ..addFont(
          Future.value(ByteData.sublistView(File(fontPath).readAsBytesSync())),
        );
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });

  for (final scenario in [
    (name: 'phone', size: const Size(390, 844), scale: 1.0),
    (name: 'large-text', size: const Size(320, 740), scale: 2.0),
    (name: 'landscape', size: const Size(844, 390), scale: 1.0),
    (name: 'tablet', size: const Size(1024, 768), scale: 1.0),
  ]) {
    testWidgets(
      'all screens remain scrollable without overflow: ${scenario.name}',
      (tester) async {
        tester.view.physicalSize = scenario.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final patient = AuthService()..login('user1', 'helpMe');
        final caregiver = AuthService()..login('caregiver', 'careme');
        final empty = SharingService();
        final pending = SharingService()
          ..requestAccess(caregiverId: 'ANN-2208', patientId: 'JKB-1042');
        final accepted = SharingService()
          ..requestAccess(caregiverId: 'ANN-2208', patientId: 'JKB-1042')
          ..accept(
            patientId: 'JKB-1042',
            caregiverId: 'ANN-2208',
            scopes: Set.of(ShareScope.values),
          );
        final pages = <String, Widget>{
          'login': LoginScreen(auth: patient),
          'home': Scaffold(body: HomeScreen(onOpenTab: (_) {})),
          'medications': const Scaffold(body: MedicationsScreen()),
          'health': const Scaffold(body: HealthScreen()),
          'appointments': const Scaffold(body: AppointmentsScreen()),
          'profile': Scaffold(
            body: ProfileScreen(auth: patient, sharing: empty),
          ),
          'consent': Scaffold(
            body: ProfileScreen(auth: patient, sharing: pending),
          ),
          'permissions': Scaffold(
            body: ProfileScreen(auth: patient, sharing: accepted),
          ),
          'caregiver': Scaffold(
            body: ProfileScreen(auth: caregiver, sharing: accepted),
          ),
          'shared': SharedPatientScreen(
            auth: caregiver,
            sharing: accepted,
            patientId: 'JKB-1042',
            caregiverId: 'ANN-2208',
          ),
          'connect': ConnectPatientScreen(auth: caregiver, sharing: empty),
          'password': const ChangePasswordScreen(),
          'zone': const Scaffold(body: SafeZoneScreen()),
          'guide': WellnessGuideScreen(guide: wellnessGuides.first),
          'vital': const VitalDetailScreen(kind: VitalKind.bloodPressure),
          'form': const Scaffold(body: MedicationForm()),
        };
        for (final entry in pages.entries) {
          final boundary = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(),
              debugShowCheckedModeBanner: false,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scenario.scale)),
                child: RepaintBoundary(key: boundary, child: child!),
              ),
              home: entry.value,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${scenario.name}/${entry.key} initial',
          );
          if (previews &&
              (scenario.name == 'phone' || scenario.name == 'large-text')) {
            await _capture(tester, boundary, '${scenario.name}-${entry.key}');
          }
          // Exercise every viewport, including content lazily built below the fold.
          final scrollable = find.byType(Scrollable).first;
          final position = tester.state<ScrollableState>(scrollable).position;
          for (
            var count = 0;
            count < 100 && position.extentAfter > 0;
            count++
          ) {
            position.jumpTo(
              (position.pixels + scenario.size.height * .55).clamp(
                0,
                position.maxScrollExtent,
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${scenario.name}/${entry.key} at ${position.pixels}',
            );
          }
          expect(
            position.extentAfter,
            0,
            reason: '${entry.key} can reach the end',
          );
          await tester.pumpWidget(const SizedBox());
        }
      },
    );
  }

  testWidgets(
    'large text navigation retains all five destinations and dose toggle',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = AuthService()..login('user1', 'helpMe');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: AppShell(auth: auth, sharing: SharingService()),
        ),
      );
      const headings = {
        'Dziś': 'Dzień dobry',
        'Leki': 'Twoje leki',
        'Zdrowie': 'Karta medyczna',
        'Porady': 'Porady',
        'Profil': 'Twoje konto',
      };
      for (final label in [
        'Leki',
        'Zdrowie',
        'Porady',
        'Profil',
        'Dziś',
        'Leki',
      ]) {
        await tester.tap(find.byKey(ValueKey('nav-$label')));
        await tester.pumpAndSettle();
        expect(
          find.text(headings[label]!).hitTestable(),
          findsNWidgets(label == 'Porady' ? 2 : 1),
        );
        expect(tester.takeException(), isNull);
      }
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('dose-1')),
        250,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('dose-card-1'));
      final compactHeight = tester.getSize(card).height;
      await tester.tap(find.byKey(const ValueKey('dose-1')));
      await tester.pumpAndSettle();
      expect(find.text('Potwierdź przyjęcie'), findsWidgets);
      expect(tester.getSize(card).height, greaterThan(compactHeight));
      await tester.ensureVisible(find.text('Potwierdź przyjęcie').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Potwierdź przyjęcie').first);
      await tester.pumpAndSettle();
      expect(
        find.byTooltip('Cofnij potwierdzenie: Acard 75 mg, 08:00'),
        findsOneWidget,
      );
      expect(tester.getSize(card).height, compactHeight);
      expect(tester.takeException(), isNull);
      final viewport = tester.getRect(
        find.byKey(const Key('tabContentViewport')),
      );
      final navigation = tester.getRect(find.byKey(const ValueKey('nav-Dziś')));
      expect(navigation.top - viewport.bottom, greaterThanOrEqualTo(16));
    },
  );

  testWidgets('form labels are exposed to assistive technology', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: MedicationForm()),
      ),
    );
    expect(find.bySemanticsLabel('Nazwa leku'), findsOneWidget);
    final field = find.byKey(const ValueKey('medication-Nazwa leku'));
    expect(tester.getSize(field).height, greaterThanOrEqualTo(48));
    expect(find.byType(CareField), findsNWidgets(9));
    semantics.dispose();
  });

  testWidgets('shell controls have usable touch targets and labels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    final auth = AuthService()..login('user1', 'helpMe');
    final boundary = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: boundary,
          child: AppShell(auth: auth, sharing: SharingService()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final label in ['Dziś', 'Leki', 'Zdrowie', 'Porady', 'Profil']) {
      await tester.tap(find.widgetWithText(NavigationDestination, label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .getSize(find.widgetWithText(NavigationDestination, label))
            .height,
        greaterThanOrEqualTo(48),
      );
      if (previews) await _capture(tester, boundary, 'shell-$label');
      expect(
        tester.getRect(find.byType(NavigationBar)).top -
            tester.getRect(find.byKey(const Key('tabContentViewport'))).bottom,
        greaterThanOrEqualTo(16),
      );
    }
    await tester.tap(find.widgetWithText(NavigationDestination, 'Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Wyloguj się').hitTestable(), findsOneWidget);
    semantics.dispose();
  });
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('tmp/ui-previews')..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}
