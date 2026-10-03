import 'package:flutter/material.dart';

import 'package:m_opiekun/widgets/prototype_page.dart';

/// Wizyty i przypomnienia.
///
/// Do zbudowania: dodawanie terminu, powiadomienia przed wizytą
/// i archiwum odbytych wizyt. Lista jest statyczna.
class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrototypePage(
      lead:
          'Nadchodzące wizyty i badania, przypomnienia przed terminem '
          'oraz krótka historia.',
      children: [
        Text('Nadchodzące', style: Theme.of(context).textTheme.titleLarge),
        const _VisitCard(
          day: '4',
          month: 'paź',
          title: 'dr Anna Nowak',
          details: 'Kardiolog · Przychodnia Lipowa',
          time: '10:30',
          reminder: 'Przypomnienie: dzień wcześniej i 2 godziny przed',
        ),
        const _VisitCard(
          day: '12',
          month: 'paź',
          title: 'Badanie krwi',
          details: 'Laboratorium · na czczo',
          time: '09:00',
          reminder: 'Przypomnienie: wieczór wcześniej',
        ),
        Text('Historia', style: Theme.of(context).textTheme.titleLarge),
        const _VisitCard(
          day: '12',
          month: 'wrz',
          title: 'Kontrola ciśnienia',
          details: 'dr Anna Nowak · odbyta',
          time: '11:00',
          reminder: 'Bez kolejnego przypomnienia',
          muted: true,
        ),
        FilledButton.icon(
          onPressed: () => showPrototypeHint(context, 'Dodawanie wizyty'),
          icon: const Icon(Icons.add),
          label: const Text('Dodaj wizytę'),
        ),
      ],
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.day,
    required this.month,
    required this.title,
    required this.details,
    required this.time,
    required this.reminder,
    this.muted = false,
  });

  final String day;
  final String month;
  final String title;
  final String details;
  final String time;
  final String reminder;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: muted
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(day, style: theme.textTheme.titleLarge),
                  Text(month, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  Text(details, style: theme.textTheme.bodyLarge),
                  Text(
                    time,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reminder,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
