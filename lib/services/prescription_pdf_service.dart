import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import '../models/prescription.dart';
import 'prescription_parser.dart';
import 'prescription_pdf_layout.dart';
import 'prescription_rpl_matcher.dart';
import 'rpl_repository.dart';

class PrescriptionReadException implements Exception {
  const PrescriptionReadException(this.message);
  final String message;
}

bool supportsPrescriptionOcr({
  required bool isWeb,
  required TargetPlatform platform,
}) =>
    !isWeb &&
    (platform == TargetPlatform.android || platform == TargetPlatform.iOS);

class PrescriptionPdfService {
  PrescriptionPdfService({
    this.ocrPage,
    this.extractPageText,
    RplRepository? repository,
  }) : _repository = repository ?? RplRepository();
  final RplRepository _repository;

  /// Optional OCR adapter, also usable in desktop extraction tests.
  final Future<String> Function(PdfPage)? ocrPage;
  final Future<String> Function(PdfPage)? extractPageText;
  Future<PrescriptionImport?> pickAndRead({
    void Function(String)? onProgress,
  }) async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Recepta PDF',
          extensions: ['pdf'],
          mimeTypes: ['application/pdf'],
          uniformTypeIdentifiers: ['com.adobe.pdf'],
        ),
      ],
    );
    if (file == null) return null;
    if (await file.length() > 20 * 1024 * 1024) {
      throw const PrescriptionReadException(
        'PDF jest za duży. Wybierz plik do 20 MB.',
      );
    }
    return read(await file.readAsBytes(), onProgress: onProgress);
  }

  Future<PrescriptionImport> read(
    Uint8List bytes, {
    void Function(String)? onProgress,
  }) async {
    if (bytes.length > 20 * 1024 * 1024 ||
        bytes.length < 5 ||
        String.fromCharCodes(bytes.take(5)) != '%PDF-') {
      throw const PrescriptionReadException(
        'Wybierz poprawny plik PDF do 20 MB.',
      );
    }
    PdfDocument? document;
    final pageTexts = <String>[];
    final warnings = <String>[];
    var usedOcr = false;
    var stage = 'inicjalizacja';
    try {
      await pdfrxFlutterInitialize();
      stage = 'otwieranie dokumentu';
      document = await PdfDocument.openData(
        bytes,
        passwordProvider: () => null,
      );
      if (document.pages.length > 20) {
        throw const PrescriptionReadException(
          'Dokument ma więcej niż 20 stron. Wybierz PDF zawierający tylko receptę.',
        );
      }
      for (final page in document.pages) {
        onProgress?.call(
          'Odczyt strony ${page.pageNumber} z ${document.pages.length}…',
        );
        stage = 'odczyt tekstu';
        var text = '';
        try {
          text = extractPageText != null
              ? await extractPageText!(page)
              : prescriptionReadingOrder(await page.loadStructuredText());
        } catch (error) {
          _logFailure(stage, error);
          warnings.add(
            'Nie udało się odczytać warstwy tekstowej strony ${page.pageNumber}. Spróbujemy odczytu obrazu.',
          );
        }
        stage = 'ocena tekstu i dostępności OCR';
        // Image-only PDFs require OCR. No automatic correction of OCR digits.
        final declarationOnly =
            !RegExp(r'\bRecepta\s+\d', caseSensitive: false).hasMatch(text) &&
            RegExp(
              r'Oświadczam.*nie realizowa',
              caseSensitive: false,
              dotAll: true,
            ).hasMatch(text);
        if (!declarationOnly &&
            (text.replaceAll(RegExp(r'\s'), '').length < 20 ||
                prescriptionNeedsOcr(text))) {
          if (ocrPage == null &&
              !supportsPrescriptionOcr(
                isWeb: kIsWeb,
                platform: defaultTargetPlatform,
              )) {
            warnings.add(
              'Strona ${page.pageNumber} może wymagać OCR. Dodatkowy odczyt obrazu jest dostępny na Androidzie i iOS.',
            );
          } else {
            onProgress?.call('Rozpoznawanie skanu: strona ${page.pageNumber}…');
            try {
              final String scanned;
              if (ocrPage != null) {
                scanned = await ocrPage!(page);
              } else {
                scanned = await _ocr(page);
              }
              int quality(String value) => parsePrescription(value).items.fold(
                0,
                (score, item) =>
                    score + 1 + (item.instruction.isNotEmpty ? 2 : 0),
              );
              if (quality(scanned) >= quality(text)) text = scanned;
              usedOcr = true;
            } catch (error) {
              _logFailure('OCR', error);
              warnings.add(
                'Nie udało się wykonać OCR strony ${page.pageNumber}. Sprawdź dane w oryginale PDF.',
              );
            }
          }
        }
        if (text.length > 100000) {
          throw const PrescriptionReadException(
            'Strona zawiera zbyt dużo tekstu. Wybierz PDF zawierający tylko receptę.',
          );
        }
        pageTexts.add(text);
      }
      stage = 'rozpoznawanie danych recepty';
      PrescriptionParseResult parsed;
      try {
        parsed = parsePrescription(pageTexts.join('\n'));
      } catch (error) {
        _logFailure(stage, error);
        parsed = const PrescriptionParseResult([], [
          'PDF został otwarty, ale nie udało się rozpoznać danych recepty. Możesz sprawdzić oryginał PDF.',
        ]);
      }
      var items = parsed.items;
      if (items.isNotEmpty) {
        onProgress?.call(
          'Sprawdzanie nazw leków w Rejestrze Produktów Leczniczych…',
        );
        try {
          final products = await _repository.prescriptionProducts();
          items = items
              .map((item) => matchPrescriptionToRpl(item, products))
              .toList();
        } catch (error) {
          _logFailure('wczytywanie RPL', error);
          warnings.add(
            'Nie udało się wczytać bazy RPL. Dane pochodzą z PDF i wymagają sprawdzenia.',
          );
        }
      }
      return PrescriptionImport(
        items: items,
        warnings: [...warnings, ...parsed.warnings],
        pdfBytes: bytes,
        usedOcr: usedOcr,
      );
    } on PrescriptionReadException {
      rethrow;
    } catch (error) {
      _logFailure(stage, error);
      throw PrescriptionReadException(
        'Nie udało się wczytać PDF (etap: $stage, typ: ${error.runtimeType}). Spróbuj ponownie. Jeśli problem się powtórzy, przekaż ten komunikat do sprawdzenia.',
      );
    } finally {
      try {
        await document?.dispose();
      } catch (error) {
        _logFailure('zamykanie PDF', error);
      }
    }
  }

  void _logFailure(String stage, Object error) {
    // Do not log prescription text, file paths or exception messages with PHI.
    debugPrint('Prescription import: $stage (${error.runtimeType})');
  }

  Future<String> _ocr(PdfPage page) async {
    final scale = 2400 / math.max(page.width, page.height);
    final rendered = await page.render(
      fullWidth: page.width * scale,
      fullHeight: page.height * scale,
    );
    if (rendered == null) {
      throw const PrescriptionReadException(
        'Nie udało się odczytać obrazu strony PDF.',
      );
    }
    ui.Image? image;
    Directory? directory;
    try {
      image = await rendered.createImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) {
        throw const PrescriptionReadException(
          'Nie udało się odczytać obrazu strony PDF.',
        );
      }
      directory = await (await getTemporaryDirectory()).createTemp(
        'mcare-recepta-',
      );
      final file = File('${directory.path}/page.png');
      await file.writeAsBytes(png.buffer.asUint8List());
      final text = await const MethodChannel(
        'm_opiekun/prescription_ocr',
      ).invokeMethod<String>('recognizeText', {'path': file.path});
      if (text == null) {
        throw const PrescriptionReadException(
          'System nie zwrócił tekstu rozpoznanego na obrazie.',
        );
      }
      return text;
    } finally {
      image?.dispose();
      rendered.dispose();
      if (directory != null) await directory.delete(recursive: true);
    }
  }
}
