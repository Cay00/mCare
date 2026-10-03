import 'package:m_opiekun/widgets/care_components.dart';
import 'package:flutter/material.dart';

import 'package:m_opiekun/widgets/prototype_page.dart';
import 'package:m_opiekun/widgets/section_card.dart';

/// Bezpieczna strefa, otwierana z profilu.
///
/// Do zbudowania: mapa, zapis środka i promienia strefy, odczyt GPS
/// oraz alert do opiekuna po wyjściu ze strefy. Tu jest tylko podgląd.
void openSafeZone(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => Scaffold(
        appBar: careAppBar(context, 'Strefa'),
        body: const SafeZoneScreen(),
      ),
    ),
  );
}

class SafeZoneScreen extends StatelessWidget {
  const SafeZoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PrototypePage(
      lead:
          'Status pobytu w bezpiecznej strefie i ostrzeżenie dla opiekuna, '
          'gdy osoba ją opuści.',
      children: [
        const CareHeading('Bezpieczna strefa'),
        const CareNotice(
          'Podgląd funkcji. Lokalizacja, mapa i wysyłanie alertów nie są jeszcze podłączone.',
        ),
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 36,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'W bezpiecznej strefie',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'Ostatnio: dziś, 11:05',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 200),
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Miejsce na mapę',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                'Okrąg strefy wokół domu',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SectionCard(
          title: 'Ustawienia strefy',
          icon: Icons.home_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ZoneFact(label: 'Miejsce', value: 'Dom, ul. Lipowa 12'),
              _ZoneFact(label: 'Promień', value: '200 m'),
              _ZoneFact(
                label: 'Kto dostaje alert',
                value: 'Jan Kowalski, syn',
                isLast: true,
              ),
            ],
          ),
        ),
        Card(
          color: theme.colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Podgląd ostrzeżenia',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Maria opuściła bezpieczną strefę (ul. Lipowa 12).',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Taki komunikat ma dostać opiekun. Wysyłka nie jest podłączona.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: () => showPrototypeHint(context, 'Edycja strefy'),
          icon: const Icon(Icons.edit_location_alt_outlined),
          label: const Text('Ustaw strefę'),
        ),
      ],
    );
  }
}

class _ZoneFact extends StatelessWidget {
  const _ZoneFact({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
