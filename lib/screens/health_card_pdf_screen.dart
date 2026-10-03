import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'package:m_opiekun/services/health_card_pdf.dart';

class HealthCardPdfScreen extends StatelessWidget {
  const HealthCardPdfScreen({super.key, required this.data});

  final HealthCardPdfData data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Karta PDF')),
      body: PdfPreview(
        build: (_) => buildHealthCardPdf(data),
        pdfFileName: 'karta_zdrowia.pdf',
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}
