import 'package:flutter/material.dart';

import 'package:m_opiekun/widgets/prototype_page.dart';

/// Pulpit dnia.
///
/// Docelowo skrót tego, co senior ma zrobić teraz: lek, wizyta,
/// status strefy i zalecenie. Karty tylko przełączają zakładki.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  /// Indeksy jak w dolnej nawigacji: 1 leki, 2 zdrowie, 3 wizyty, 4 strefa.
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return PrototypePage(
      lead:
          'Skrót dnia: najbliższy lek, wizyta, bezpieczna strefa i zalecenie. '
          'Reszta szczegółów jest w kolejnych zakładkach.',
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dzień dobry',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Maria Kowalska',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              _polishToday(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        _SummaryTile(
          icon: Icons.medication_outlined,
          kicker: 'Następny lek',
          title: 'Prestarium 5 mg',
          subtitle: 'Dziś o 14:00 · 1 tabletka',
          onTap: () => onOpenTab(1),
        ),
        _SummaryTile(
          icon: Icons.event_outlined,
          kicker: 'Najbliższa wizyta',
          title: 'Jutro, 10:30',
          subtitle: 'dr Anna Nowak · kardiolog',
          onTap: () => onOpenTab(3),
        ),
        _SummaryTile(
          icon: Icons.location_on_outlined,
          kicker: 'Bezpieczna strefa',
          title: 'W domu',
          subtitle: 'ul. Lipowa 12 · promień 200 m',
          onTap: () => onOpenTab(4),
        ),
        _SummaryTile(
          icon: Icons.favorite_outline,
          kicker: 'Zalecenie na dziś',
          title: 'Zmierz ciśnienie rano',
          subtitle: 'Przed przyjęciem leków',
          onTap: () => onOpenTab(2),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String kicker;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kicker,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(subtitle, style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

String _polishToday() {
  const weekdays = [
    'poniedziałek',
    'wtorek',
    'środa',
    'czwartek',
    'piątek',
    'sobota',
    'niedziela',
  ];
  const months = [
    'stycznia',
    'lutego',
    'marca',
    'kwietnia',
    'maja',
    'czerwca',
    'lipca',
    'sierpnia',
    'września',
    'października',
    'listopada',
    'grudnia',
  ];
  final now = DateTime.now();
  final weekday = weekdays[now.weekday - 1];
  final capitalized = '${weekday[0].toUpperCase()}${weekday.substring(1)}';
  return '$capitalized, ${now.day} ${months[now.month - 1]}';
}
