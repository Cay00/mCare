import 'package:flutter/material.dart';

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
      lead:
          'Wybierz poradę i przeczytaj krótkie ćwiczenie. '
          'Możesz wracać do nich, kiedy potrzebujesz chwili spokoju.',
      children: [
        Text('Porady', style: Theme.of(context).textTheme.titleLarge),
        for (var i = 0; i < wellnessGuides.length; i += 2)
          _GuideRow(
            left: wellnessGuides[i],
            right: i + 1 < wellnessGuides.length ? wellnessGuides[i + 1] : null,
          ),
        const SizedBox(height: 8),
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

class _GuideRow extends StatelessWidget {
  const _GuideRow({required this.left, required this.right});

  final WellnessGuide left;
  final WellnessGuide? right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _GuideTile(guide: left)),
          const SizedBox(width: 12),
          Expanded(
            child: right == null
                ? const SizedBox.shrink()
                : _GuideTile(guide: right!),
          ),
        ],
      ),
    );
  }
}

class _GuideTile extends StatelessWidget {
  const _GuideTile({required this.guide});

  final WellnessGuide guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => WellnessGuideScreen(guide: guide),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(guide.icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Text(guide.title, style: theme.textTheme.titleMedium),
              const Spacer(),
              const SizedBox(height: 6),
              Text(
                guide.duration,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
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
