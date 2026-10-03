import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart';
import 'package:m_opiekun/services/prescription_pdf_service.dart';

void main() {
  test(
    'PDF object order does not move patient metadata into medication block',
    () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (_) => pw.Stack(
            children: [
              pw.Positioned(
                left: 0,
                top: 150,
                child: pw.Text('Recepta 1 z 1 32.1.00000000001340364'),
              ),
              pw.Positioned(
                left: 0,
                top: 0,
                child: pw.Text('10502651685488725317592673429986433730998330'),
              ),
              pw.Positioned(
                left: 0,
                top: 25,
                child: pw.Text('Kod dostepu 0000'),
              ),
              pw.Positioned(left: 0, top: 50, child: pw.Text('Pacjent TEST')),
              pw.Positioned(
                left: 0,
                top: 180,
                child: pw.Text('Lek testowy aerozol,'),
              ),
              pw.Positioned(left: 250, top: 180, child: pw.Text('100%')),
              pw.Positioned(
                left: 0,
                top: 200,
                child: pw.Text('roztwor 1,53 mg/daw.'),
              ),
              pw.Positioned(
                left: 0,
                top: 225,
                child: pw.Text('30 op. po 1 fiol.po6,5ml'),
              ),
              pw.Positioned(
                left: 0,
                top: 250,
                child: pw.Text('D.S. 1 x dziennie 1 fiol. przez 30 dni'),
              ),
              pw.Positioned(
                left: 0,
                top: 270,
                child: pw.Text('(rano: 1 fiol.) przezskornie'),
              ),
              pw.Positioned(
                left: 0,
                top: 295,
                child: pw.Text('Odplatnosc 100%'),
              ),
            ],
          ),
        ),
      );
      var calls = 0;
      final result = await PrescriptionPdfService(
        ocrPage: (_) async {
          calls++;
          return '';
        },
      ).read(await pdf.save());
      expect(calls, 0);
      final item = result.items.single;
      expect(item.product.name, 'Lek testowy aerozol, roztwor 1,53 mg/daw.');
      expect(
        item.instruction,
        '1 x dziennie 1 fiol. przez 30 dni\n(rano: 1 fiol.) przezskornie',
      );
      expect(item.prescribedPackages, 30);
      expect(item.product.packageDescription, '1 fiol.po6,5ml');
      expect(item.product.packageQuantity, isNull);
    },
  );
  test('browser never invokes native OCR, including mobile browsers', () {
    for (final platform in TargetPlatform.values) {
      expect(supportsPrescriptionOcr(isWeb: true, platform: platform), false);
      expect(
        supportsPrescriptionOcr(isWeb: false, platform: platform),
        platform == TargetPlatform.android || platform == TargetPlatform.iOS,
      );
    }
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    Pdfrx.cacheDirectoryPath = Directory.systemTemp.path;
  });
  test(
    'text extraction failure falls back to OCR and retains PDF preview',
    () async {
      final pdf = pw.Document();
      pdf.addPage(pw.Page(build: (_) => pw.Text('Example')));
      final bytes = await pdf.save();
      final result = await PrescriptionPdfService(
        extractPageText: (_) async => throw StateError('broken text map'),
        ocrPage: (_) async => 'Recepta 1 z 1\nLek 5 mg\nD.S. 2x1',
      ).read(bytes);
      expect(result.items.single.instruction, '2x1');
      expect(result.pdfBytes, bytes);
      expect(result.usedOcr, true);
    },
  );
  test(
    'failed text extraction and OCR still allow original PDF preview',
    () async {
      final pdf = pw.Document();
      pdf.addPage(pw.Page(build: (_) => pw.Text('Example')));
      final bytes = await pdf.save();
      final result = await PrescriptionPdfService(
        extractPageText: (_) async => throw StateError('text'),
        ocrPage: (_) async => throw StateError('OCR'),
      ).read(bytes);
      expect(result.items, isEmpty);
      expect(result.pdfBytes, bytes);
      expect(result.usedOcr, false);
      expect(result.warnings.any((s) => s.contains('OCR')), true);
    },
  );
  test('long barcode-only PDF text triggers OCR fallback', () async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (_) => pw.Column(
          children: [
            pw.Text('Recepta 1 z 1'),
            pw.Text('ZZZZ8DCA4B32C65B37CZ20'),
            pw.Text('10500303495089270312369752664573748022567510'),
          ],
        ),
      ),
    );
    var calls = 0;
    final result = await PrescriptionPdfService(
      ocrPage: (_) async {
        calls++;
        return 'Recepta 1 z 1\nLek 5 mg\n1 op. po 30 tabl.\nD.S. 2x1';
      },
    ).read(await pdf.save());
    expect(calls, 1);
    expect(result.usedOcr, isTrue);
    expect(result.items.single.product.name, 'Lek 5 mg');
    expect(result.items.single.instruction, '2x1');
  });

  test(
    'real PDF text extraction preserves separate prescriptions across pages',
    () async {
      final pdf = pw.Document();
      for (var i = 1; i <= 2; i++) {
        pdf.addPage(
          pw.Page(
            build: (_) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final line in [
                  'Recepta $i z 2',
                  'Spasmolina kaps. twarde (60 mg)',
                  '2 op. po 20 szt.',
                  'D.S. $i x 1',
                  'Odplatnosc 100%',
                ])
                  pw.Text(line),
              ],
            ),
          ),
        );
      }
      final result = await PrescriptionPdfService().read(await pdf.save());
      expect(result.usedOcr, false);
      expect(result.items, hasLength(2));
      expect(result.items.map((item) => item.instruction), ['1 x 1', '2 x 1']);
      expect(result.items.first.product.packageQuantity, 20);
    },
  );

  test('non PDF and oversize data fail before engine initialization', () async {
    await expectLater(
      PrescriptionPdfService().read(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<PrescriptionReadException>()),
    );
    await expectLater(
      PrescriptionPdfService().read(Uint8List(20 * 1024 * 1024 + 1)),
      throwsA(isA<PrescriptionReadException>()),
    );
  });

  test('page limit is enforced before extraction', () async {
    final pdf = pw.Document();
    for (var i = 0; i < 21; i++) {
      pdf.addPage(pw.Page(build: (_) => pw.Text('Page')));
    }
    await expectLater(
      PrescriptionPdfService().read(await pdf.save()),
      throwsA(isA<PrescriptionReadException>()),
    );
  });
}
