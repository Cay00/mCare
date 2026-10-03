/// A user-selected daily plan, not an interpretation of medical instructions.
List<int> evenlySpacedDoseMinutes(int firstMinute, int count) {
  if (firstMinute < 0 || firstMinute >= 1440 || count < 1 || count > 24) {
    throw ArgumentError('Invalid daily schedule');
  }
  return List.generate(
    count,
    (i) => (firstMinute + (1440 * i / count).round()) % 1440,
  );
}

String doseTimeLabel(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
