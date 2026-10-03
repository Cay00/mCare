/// Recognises notation, not an independently chosen treatment or clock times.
class PrescriptionDosing {
  const PrescriptionDosing(this.amounts, this.periods, {this.everyDays = 1});
  final int everyDays;
  final List<String> amounts;
  final List<String> periods;
  int get dailyCount => amounts.length;
  String get description =>
      '${everyDays == 1 ? 'Codziennie' : 'Co $everyDays dni'}: ${periods.isEmpty ? '$dailyCount przyjęć, po ${amounts.first} (jednostka według recepty)' : List.generate(amounts.length, (i) => '${periods[i]}: ${amounts[i]}').join(', ')}';
}

PrescriptionDosing? recognizePrescriptionDosing(String source) {
  var text = source
      .toLowerCase()
      .trim()
      .replaceFirst(
        RegExp(r'^D\s*\.?\s*S\s*\.?\s*:?\s*', caseSensitive: false),
        '',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('×', 'x')
      .replaceAll('–', '-')
      .replaceAll('−', '-');
  var everyDays = 1;
  final interval = RegExp(
    r'\s+co\s+(drugi dzień|dwa dni|trzy dni|\d+ dni)\s*$',
  ).firstMatch(text);
  if (interval != null) {
    final value = interval[1]!;
    everyDays = switch (value) {
      'drugi dzień' || 'dwa dni' => 2,
      'trzy dni' => 3,
      _ => int.tryParse(value.split(' ').first) ?? 0,
    };
    if (everyDays < 1 || everyDays > 365) return null;
    text = text.substring(0, interval.start).trim();
  }
  final unitPattern = RegExp(
    r'\s+(tabl\.?|tabletka|tabletki|tabletek|kaps\.?|kapsułka|kapsułki|ml|dawka|dawki)$',
  );
  final explicitUnit = unitPattern.hasMatch(text);
  text = text.replaceFirst(unitPattern, '');
  const amount = r'(?:\d+(?:[.,]\d+)?|\d+\s*/\s*\d+)';
  final times = RegExp('^(\\d{1,2})\\s*[xX*]\\s*($amount)\$').firstMatch(text);
  bool positive(String value) {
    final parts = value.replaceAll(' ', '').replaceAll(',', '.').split('/');
    final number = double.tryParse(parts.first);
    return number != null &&
        number > 0 &&
        (parts.length == 1 || (double.tryParse(parts.last) ?? 0) > 0);
  }

  if (interval != null &&
      explicitUnit &&
      RegExp('^$amount\$').hasMatch(text) &&
      positive(text)) {
    return PrescriptionDosing([text], const [], everyDays: everyDays);
  }

  if (times != null) {
    final count = int.parse(times[1]!);
    if (count >= 1 && count <= 24 && positive(times[2]!)) {
      return PrescriptionDosing(
        List.filled(count, times[2]!),
        const [],
        everyDays: everyDays,
      );
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
  return amounts.isEmpty
      ? null
      : PrescriptionDosing(amounts, periods, everyDays: everyDays);
}
