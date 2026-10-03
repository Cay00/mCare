import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class HealthPdfVital {
  const HealthPdfVital({
    required this.label,
    required this.value,
    required this.detail,
    required this.status,
  });

  final String label;
  final String value;
  final String detail;
  final String status;
}

class HealthPdfFact {
  const HealthPdfFact({required this.label, required this.value});

  final String label;
  final String value;
}

class HealthCardPdfData {
  const HealthCardPdfData({
    required this.patientName,
    required this.generatedAt,
    required this.latest,
    required this.glucoseHistory,
    required this.medicalFacts,
    required this.advice,
  });

  final String patientName;
  final DateTime generatedAt;
  final List<HealthPdfVital> latest;
  final List<HealthPdfVital> glucoseHistory;
  final List<HealthPdfFact> medicalFacts;
  final List<String> advice;
}

pw.Font? _regular;
pw.Font? _bold;

Future<void> _ensureFonts() async {
  _regular ??= pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
  );
  _bold ??= pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
  );
}

Future<Uint8List> buildHealthCardPdf(HealthCardPdfData data) async {
  await _ensureFonts();
  final doc = pw.Document();
  final when = _formatGeneratedAt(data.generatedAt);

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 40),
        theme: pw.ThemeData.withFont(base: _regular!, bold: _bold!),
      ),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Karta zdrowia',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${data.patientName} · wygenerowano $when',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.teal700, thickness: 1.2),
          pw.SizedBox(height: 12),
        ],
      ),
      build: (context) => [
        _sectionTitle('Ostatnie pomiary'),
        if (data.latest.isEmpty)
          pw.Text('Brak zapisanych pomiarów.')
        else
          _vitalsTable(data.latest),
        pw.SizedBox(height: 16),
        _sectionTitle('Historia cukru'),
        if (data.glucoseHistory.isEmpty)
          pw.Text('Brak zapisanych pomiarów cukru.')
        else
          _vitalsTable(data.glucoseHistory),
        pw.SizedBox(height: 16),
        _sectionTitle('Dane medyczne'),
        ...data.medicalFacts.map(
          (fact) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 140,
                  child: pw.Text(
                    fact.label,
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    fact.value,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 16),
        _sectionTitle('Zalecenia'),
        ...data.advice.map(
          (text) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('•  '),
                pw.Expanded(child: pw.Text(text)),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _sectionTitle(String title) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 8),
  child: pw.Text(
    title,
    style: pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.teal800,
    ),
  ),
);

pw.Widget _vitalsTable(List<HealthPdfVital> rows) {
  return pw.TableHelper.fromTextArray(
    headers: const ['Pomiar', 'Wynik', 'Szczegóły', 'Ocena'],
    data: [
      for (final row in rows) [row.label, row.value, row.detail, row.status],
    ],
    headerDecoration: const pw.BoxDecoration(color: PdfColors.teal50),
    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
    cellStyle: const pw.TextStyle(fontSize: 10),
    cellAlignments: {
      0: pw.Alignment.centerLeft,
      1: pw.Alignment.centerLeft,
      2: pw.Alignment.centerLeft,
      3: pw.Alignment.centerLeft,
    },
  );
}

String _formatGeneratedAt(DateTime at) {
  final dd = at.day.toString().padLeft(2, '0');
  final mm = at.month.toString().padLeft(2, '0');
  final hh = at.hour.toString().padLeft(2, '0');
  final min = at.minute.toString().padLeft(2, '0');
  return '$dd.$mm.${at.year}, $hh:$min';
}
