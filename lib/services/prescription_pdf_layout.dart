import 'package:pdfrx/pdfrx.dart';

/// PDF object order need not match the printed reading order.
String prescriptionReadingOrder(PdfPageText text) {
  final fragments =
      text.fragments.where((f) => f.text.trim().isNotEmpty).toList()
        ..sort((a, b) => b.bounds.top.compareTo(a.bounds.top));
  if (fragments.isEmpty) return text.fullText;
  final rows = <List<PdfPageTextFragment>>[];
  for (final fragment in fragments) {
    if (rows.isEmpty ||
        (rows.last.first.bounds.top - fragment.bounds.top).abs() > 3) {
      rows.add([]);
    }
    rows.last.add(fragment);
  }
  return rows
      .map((row) {
        row.sort((a, b) => a.bounds.left.compareTo(b.bounds.left));
        final line = StringBuffer();
        for (var i = 0; i < row.length; i++) {
          if (i > 0) {
            // Keep separate columns (e.g. reimbursement) out of the title.
            line.write(
              row[i].bounds.left - row[i - 1].bounds.right > 24 ? '\n' : ' ',
            );
          }
          line.write(row[i].text.trim());
        }
        return line.toString();
      })
      .join('\n');
}
