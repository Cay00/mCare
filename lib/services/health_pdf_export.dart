import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class HealthPdfExport {
  static Future<Uint8List> build({
    required String name,
    required String bloodType,
    required String allergies,
    required String conditions,
    required String doctor,
    required String emergencyContact,
    required List<String> readings,
  }) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Text(
            'Karta medyczna pacjenta',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Wygenerowano: ${_formatDate(DateTime.now())}'),
          pw.SizedBox(height: 20),
          _section('Dane pacjenta', [
            ('Imię i nazwisko', name),
            ('Grupa krwi', bloodType),
            ('Alergie', allergies),
            ('Choroby i schorzenia', conditions),
            ('Lekarz prowadzący', doctor),
            ('Kontakt alarmowy', emergencyContact),
          ]),
          pw.SizedBox(height: 20),
          pw.Text(
            'Pomiary i wpisy zdrowotne',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (readings.isEmpty)
            pw.Text('Brak zapisanych pomiarów.')
          else
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: readings
                  .map((reading) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Text('• $reading'),
                      ))
                  .toList(),
            ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Dokument zawiera informacje wprowadzone przez użytkownika.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
    return document.save();
  }

  static pw.Widget _section(String title, List<(String, String)> fields) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          ...fields.map((field) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.RichText(
                  text: pw.TextSpan(children: [
                    pw.TextSpan(
                      text: '${field.$1}: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.TextSpan(text: field.$2),
                  ]),
                ),
              )),
        ],
      );

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
