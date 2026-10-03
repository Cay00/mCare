import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_opiekun/models/prescription.dart';
import 'package:m_opiekun/screens/prescription_import_screen.dart';
import 'package:m_opiekun/services/prescription_parser.dart';
import 'package:m_opiekun/theme/app_theme.dart';
import 'package:m_opiekun/widgets/dose_schedule_editor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const font = String.fromEnvironment('PREVIEW_FONT');
  setUpAll(() async {
    if (font.isNotEmpty) {
      await (FontLoader('Roboto')..addFont(
            Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
          ))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'import and time editor fit at text scale $scale, including keyboard',
      (tester) async {
        tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final key = GlobalKey();
        Widget app(Widget child) => MaterialApp(
          theme: buildAppTheme(),
          debugShowCheckedModeBanner: false,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: RepaintBoundary(key: key, child: child!),
          ),
          home: child,
        );
        final parsed = parsePrescription(
          'Recepta 1 z 1\nSpasmolina kaps. twarde (60 mg)\n2 op. po 20 szt.\nD.S. 2 x 1\nOdpłatność 100%',
        );
        await tester.pumpWidget(
          app(
            PrescriptionImportScreen(
              readPrescription: (_) async => PrescriptionImport(
                items: parsed.items,
                warnings: [],
                pdfBytes: Uint8List(0),
                usedOcr: true,
              ),
            ),
          ),
        );
        await tester.scrollUntilVisible(
          find.byKey(const Key('selectPrescriptionPdf')),
          250,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('selectPrescriptionPdf')));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const Key('review-prescription-0')),
          250,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (font.isNotEmpty) {
          await screenshot(tester, key, 'prescription-review-$scale');
        }
        await tester.pumpWidget(const SizedBox());
        List<int> edited = [];
        await tester.pumpWidget(
          app(
            Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: DoseScheduleEditor(
                  initialMinutes: const [480, 960, 0],
                  onChanged: (times) => edited = times,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const ValueKey('dose-time-0')));
        await tester.pumpAndSettle();
        if (font.isNotEmpty) {
          await screenshot(tester, key, 'prescription-schedule-$scale');
        }
        await tester.tap(find.byKey(const ValueKey('dose-time-0')));
        await tester.pumpAndSettle();
        if (font.isNotEmpty) {
          await screenshot(tester, key, 'prescription-clock-$scale');
        }
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.enterText(find.byKey(const ValueKey('dose-hour')), '23');
        await tester.enterText(find.byKey(const ValueKey('dose-minute')), '15');
        await tester.ensureVisible(find.text('Ustaw'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ustaw'));
        await tester.pumpAndSettle();
        expect(edited, [1395, 960, 0]);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> screenshot(WidgetTester tester, GlobalKey key, String name) =>
    tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 1.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('tmp/ui-previews').createSync(recursive: true);
      File(
        'tmp/ui-previews/$name.png',
      ).writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
