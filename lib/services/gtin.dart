/// EAN-13 and GTIN-14 share a canonical 14-digit key. Never strip a
/// non-zero packaging indicator, or guess a product from a partial code.
String? normalizeGtin(String input) {
  final code = input.trim();
  if (!RegExp(r'^(\d{13}|\d{14})$').hasMatch(code)) return null;
  if (RegExp(r'^0+$').hasMatch(code)) return null;
  var sum = 0;
  var weight = 3;
  for (var i = code.length - 2; i >= 0; i--) {
    sum += int.parse(code[i]) * weight;
    weight = weight == 3 ? 1 : 3;
  }
  if ((10 - sum % 10) % 10 != int.parse(code[code.length - 1])) return null;
  return code.padLeft(14, '0');
}

/// Accepts plain EAN/GTIN, GS1 human-readable (01), and scanner GS1 element
/// strings (optional ]d2 / ]C1 symbology identifier, ASCII GS separators).
/// A variable-length lot/serial is never searched for a coincidental "01".
String? gtinFromBarcode(String input) {
  var code = input.trim();
  final plain = normalizeGtin(code);
  if (plain != null) return plain;
  if (code.startsWith(']d2') || code.startsWith(']C1')) {
    code = code.substring(3);
  }
  if (code.startsWith('(')) {
    final fields = RegExp(r'\((\d{2,4})\)([^()]*)').allMatches(code);
    var end = 0;
    String? gtin;
    for (final field in fields) {
      if (field.start != end) return null;
      end = field.end;
      if (field[1] == '01') {
        if (gtin != null || field[2]!.length != 14) return null;
        gtin = normalizeGtin(field[2]!);
        if (gtin == null) return null;
      }
    }
    return end == code.length ? gtin : null;
  }
  const fixedLengths = {
    '00': 18,
    '02': 14,
    '11': 6,
    '12': 6,
    '13': 6,
    '15': 6,
    '16': 6,
    '17': 6,
    '20': 2,
  };
  const variableLengths = {'10': 20, '21': 20, '22': 29, '30': 8, '37': 8};
  var position = 0;
  while (position < code.length) {
    if (code[position] == '\u001d') {
      position++;
      continue;
    }
    if (position + 2 > code.length) return null;
    final ai = code.substring(position, position + 2);
    position += 2;
    if (ai == '01') {
      if (position + 14 > code.length) return null;
      return normalizeGtin(code.substring(position, position + 14));
    }
    final fixed = fixedLengths[ai];
    if (fixed != null) {
      if (position + fixed > code.length ||
          !RegExp(
            r'^\d+$',
          ).hasMatch(code.substring(position, position + fixed))) {
        return null;
      }
      position += fixed;
    } else {
      final maximum = variableLengths[ai];
      if (maximum == null) return null;
      final separator = code.indexOf('\u001d', position);
      if (separator <= position || separator - position > maximum) return null;
      position = separator + 1;
    }
  }
  return null;
}
