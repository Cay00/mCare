import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:m_opiekun/models/medication.dart';
import 'package:m_opiekun/screens/medication_scanner_screen.dart';
import 'package:m_opiekun/services/rpl_repository.dart';

class _Camera extends MobileScannerPlatform {
  final captures = StreamController<BarcodeCapture?>.broadcast();
  bool denied = false;
  int stops = 0;

  @override
  Stream<BarcodeCapture?> get barcodesStream => captures.stream;
  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();
  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();
  @override
  Widget buildCameraView() => const SizedBox.expand();
  @override
  Future<MobileScannerViewAttributes> start(StartOptions options) async {
    if (denied) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );
    }
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(640, 480),
    );
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {}
  @override
  Future<void> updateScanWindow(Rect? window) async {}

  void detect(String code) => captures.add(
    BarcodeCapture(
      barcodes: [Barcode(rawValue: code, format: BarcodeFormat.ean13)],
    ),
  );
}

class _Repository extends RplRepository {
  final result = Completer<MedicationProduct?>();
  int calls = 0;
  @override
  Future<MedicationProduct?> findByBarcode(String code) {
    calls++;
    return result.future;
  }
}

void main() {
  late _Camera camera;
  late MobileScannerPlatform original;
  setUp(() {
    original = MobileScannerPlatform.instance;
    camera = _Camera();
    MobileScannerPlatform.instance = camera;
  });
  tearDown(() async {
    await camera.captures.close();
    MobileScannerPlatform.instance = original;
  });

  testWidgets(
    'successful scan returns one typed product; late result after cancel is ignored',
    (tester) async {
      for (final cancel in [false, true]) {
        final repository = _Repository();
        MedicationProduct? returned;
        var returns = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    returned = await Navigator.of(context)
                        .push<MedicationProduct>(
                          MaterialPageRoute(
                            builder: (_) =>
                                MedicationScannerScreen(repository: repository),
                          ),
                        );
                    returns++;
                  },
                  child: const Text('Otwórz'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Otwórz'));
        await tester.pumpAndSettle();
        camera.detect('5909990672516');
        camera.detect('5909990672516');
        await tester.pump();
        await tester.pump();
        expect(repository.calls, 1);
        if (cancel) {
          await tester.tap(find.text('Wróć'));
          await tester.pump();
        }
        const product = MedicationProduct(
          name: 'Acard',
          strength: '75 mg',
          pharmaceuticalForm: 'Tabletki dojelitowe',
          packageDescription: '30 tabl.',
          packageQuantity: 30,
          packageUnit: 'tabletki',
          gtin: '05909990672516',
        );
        repository.result.complete(product);
        await tester.pumpAndSettle();
        expect(returns, 1);
        expect(returned, cancel ? isNull : same(product));
        expect(find.text('Otwórz'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets('unknown code pauses scanning, shows error and allows retry', (
    tester,
  ) async {
    final repository = _Repository();
    await tester.pumpWidget(
      MaterialApp(home: MedicationScannerScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    camera.detect('5909990672516');
    camera.detect('5909990672516');
    await tester.pump();
    await tester.pump();
    expect(repository.calls, 1);
    expect(find.text('Wyszukiwanie leku w rejestrze…'), findsOneWidget);
    repository.result.complete(null);
    await tester.pumpAndSettle();
    expect(
      find.text('Nie znaleziono leku dla zeskanowanego kodu.'),
      findsOneWidget,
    );
    expect(camera.stops, greaterThan(0));
    await tester.tap(find.text('Skanuj ponownie'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nie znaleziono leku dla zeskanowanego kodu.'),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('camera permission failure has Polish guidance and back action', (
    tester,
  ) async {
    camera.denied = true;
    await tester.pumpWidget(const MaterialApp(home: MedicationScannerScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Brak uprawnień do aparatu.'), findsOneWidget);
    expect(find.text('Wróć'), findsOneWidget);
    expect(find.text('Spróbuj ponownie'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('invalid checksum does not query RPL', (tester) async {
    final repository = _Repository();
    await tester.pumpWidget(
      MaterialApp(home: MedicationScannerScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    camera.detect('5909990672517');
    await tester.pumpAndSettle();
    expect(repository.calls, 0);
    expect(
      find.text('Nie rozpoznano poprawnego kodu EAN/GTIN.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('lookup failure is distinct from missing code', (tester) async {
    final repository = _Repository();
    await tester.pumpWidget(
      MaterialApp(home: MedicationScannerScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    camera.detect('5909990672516');
    await tester.pump();
    repository.result.completeError(const FormatException('broken asset'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nie udało się odczytać danych leku. Spróbuj ponownie.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
