import 'package:flutter/material.dart';
import 'package:m_opiekun/services/vital_store.dart';
import 'package:m_opiekun/screens/safe_zone_screen.dart';
import 'package:m_opiekun/widgets/prototype_page.dart';
import 'package:m_opiekun/widgets/care_components.dart';
import 'package:m_opiekun/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vitalStore = VitalStore.instance;
    vitalStore.load();
    return PrototypePage(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dzień dobry',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Maria Kowalska',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _polishToday(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: CareColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Powiadomienia',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Brak nowych powiadomień.')),
                );
              },
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        Card(
          color: CareColors.primary,
          clipBehavior: Clip.antiAlias,
          child: Semantics(
            button: true,
            child: InkWell(
              onTap: () => onOpenTab(1),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CareIcon(
                          Icons.medication_outlined,
                          inverse: true,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Następny lek',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Prestarium 5 mg',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dziś o 14:00 · 1 tabletka',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFF729D93), height: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Zobacz leki',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const CareHeading(
          'Twój plan i opieka',
          subtitle: 'Najważniejsze informacje w jednym miejscu.',
        ),
        CareLinkCard(
          icon: Icons.event_outlined,
          kicker: 'Najbliższa wizyta',
          title: 'Jutro, 10:30',
          subtitle: 'dr Anna Nowak · kardiolog',
          onTap: () => onOpenTab(2),
        ),
        CareLinkCard(
          icon: Icons.location_on_outlined,
          kicker: 'Bezpieczna strefa',
          title: 'W domu',
          subtitle: 'ul. Lipowa 12 · promień 200 m',
          onTap: () => openSafeZone(context),
        ),
        AnimatedBuilder(
          animation: vitalStore.revision,
          builder: (context, _) {
            final missing = vitalStore.missingTodayCount();
            return CareLinkCard(
              icon: Icons.show_chart_outlined,
              kicker: 'Przypomnienie na dziś',
              title: missing == 0
                  ? 'Dzisiejsze pomiary uzupełnione'
                  : 'Uzupełnij pomiary ($missing)',
              subtitle: missing == 0
                  ? 'Wyniki trafiają do wykresów tygodniowych.'
                  : 'Zapisz cukier, ciśnienie, wagę i inne wyniki.',
              onTap: () => onOpenTab(2),
            );
          },
        ),
        const CareNotice('Podgląd dnia zawiera dane przykładowe.'),
      ],
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
  return '$weekday, ${now.day} ${months[now.month - 1]}';
}
