/// Recognises notation, not an independently chosen treatment or clock times.
class PrescriptionDosing {
  const PrescriptionDosing(this.amounts, this.periods);
  final List<String> amounts;
  final List<String> periods;
  int get dailyCount => amounts.length;
  String get description => periods.isEmpty
      ? '$dailyCount razy dziennie, po ${amounts.first} (jednostka według recepty)'
      : List.generate(
          amounts.length,
          (i) => '${periods[i]}: ${amounts[i]}',
        ).join(', ');
}

PrescriptionDosing? recognizePrescriptionDosing(String source) {
  final text = source
      .trim()
      .replaceFirst(
        RegExp(r'^D\s*\.?\s*S\s*\.?\s*:?\s*', caseSensitive: false),
        '',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('×', 'x')
      .replaceAll('–', '-')
      .replaceAll('−', '-');
  const amount = r'(?:\d+(?:[.,]\d+)?|\d+\s*/\s*\d+)';
  final times = RegExp('^(\\d{1,2})\\s*[xX*]\\s*($amount)\$').firstMatch(text);
  bool positive(String value) {
    final parts = value.replaceAll(' ', '').replaceAll(',', '.').split('/');
    final number = double.tryParse(parts.first);
    return number != null &&
        number > 0 &&
        (parts.length == 1 || (double.tryParse(parts.last) ?? 0) > 0);
  }

  if (times != null) {
    final count = int.parse(times[1]!);
    if (count >= 1 && count <= 24 && positive(times[2]!)) {
      return PrescriptionDosing(List.filled(count, times[2]!), const []);
    }
  }
  final slots = RegExp(
    '^($amount)\\s*-\\s*($amount)\\s*-\\s*($amount)\$',
  ).firstMatch(text);
  if (slots == null) return null;
  final amounts = <String>[];
  final periods = <String>[];
  for (var i = 1; i <= 3; i++) {
    final value = slots[i]!;
    if (positive(value)) {
      amounts.add(value);
      periods.add(['rano', 'w południe', 'wieczorem'][i - 1]);
    } else if (!RegExp(r'^0(?:[.,]0+)?$').hasMatch(value)) {
      return null;
    }
  }
  return amounts.isEmpty ? null : PrescriptionDosing(amounts, periods);
}
