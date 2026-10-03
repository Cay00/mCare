import 'package:m_opiekun/widgets/care_components.dart';
import 'package:flutter/material.dart';
import '../theme/guide_colors.dart';

import 'package:m_opiekun/models/wellness_guide.dart';
import 'package:m_opiekun/screens/wellness_guide_screen.dart';
import 'package:m_opiekun/widgets/prototype_page.dart';

/// Porady zdrowotne i — tymczasowo na dole — lista wizyt.
///
/// Wizyty mają później trafić na osobny ekran. Karty terminów zostają
/// bez zmian, tylko poniżej porad.
class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrototypePage(
      children: [
        const CareHeading(
          'Porady',
          subtitle:
              'Wybierz krótkie ćwiczenie. Wróć do niego, kiedy potrzebujesz.',
        ),
        for (final guide in wellnessGuides)
          CareLinkCard(
            title: guide.title,
            subtitle: guide.duration,
            icon: guide.icon,
            iconForeground: guideColors(guide.icon).foreground,
            iconBackground: guideColors(guide.icon).background,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => WellnessGuideScreen(guide: guide),
              ),
            ),
          ),
        const SizedBox(height: 8),
        const CareHeading(
          'Nadchodzące',
          subtitle: 'Przykładowe terminy i przypomnienia.',
        ),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$day $month · $time',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(details, style: theme.textTheme.bodyLarge),
            const Divider(),
            Text(
              reminder,
              style: theme.textTheme.bodyMedium?.copyWith(color: mutedColor),
            ),
            if (muted)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Wizyta odbyta'),
              ),
          ],
        ),
      ),
    );
  }
}
