import 'package:flutter/material.dart';

import 'package:m_opiekun/widgets/prototype_page.dart';
import 'package:m_opiekun/widgets/section_card.dart';
import 'package:m_opiekun/widgets/status_pill.dart';

/// Leki.
///
/// Do zbudowania: katalog leków, harmonogram dawek, potwierdzenie
/// przyjęcia, przypomnienia i historia. Dane poniżej są przykładowe.
class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrototypePage(
      lead:
          'Dawki na dziś i lista leków stałych. Później: dodawanie leku, '
          'godziny, potwierdzenie przyjęcia i historia.',
      children: [
        Text('Dziś', style: Theme.of(context).textTheme.titleLarge),
        const _DoseCard(
          time: '08:00',
          name: 'Acard 75 mg',
          details: '1 tabletka · po śniadaniu',
          status: 'Przyjęty',
          tone: StatusTone.done,
        ),
        const _DoseCard(
          time: '08:00',
          name: 'Prestarium 5 mg',
          details: '1 tabletka · po śniadaniu',
          status: 'Przyjęty',
          tone: StatusTone.done,
        ),
        const _DoseCard(
          time: '14:00',
          name: 'Metformax 500 mg',
          details: '1 tabletka · w trakcie obiadu',
          status: 'Do przyjęcia',
          tone: StatusTone.ready,
        ),
        const _DoseCard(
          time: '20:00',
          name: 'Metformax 500 mg',
          details: '1 tabletka · w trakcie kolacji',
          status: 'Wieczorem',
          tone: StatusTone.neutral,
        ),
        const SectionCard(
          title: 'Leki stałe',
          icon: Icons.medication_outlined,
          child: Column(
            children: [
              _StandingMed(name: 'Acard 75 mg', schedule: 'Codziennie rano'),
              _StandingMed(
                name: 'Prestarium 5 mg',
                schedule: 'Codziennie rano',
              ),
              _StandingMed(
                name: 'Metformax 500 mg',
                schedule: 'Obiad i kolacja',
                isLast: true,
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () => showPrototypeHint(context, 'Dodawanie leku'),
          icon: const Icon(Icons.add),
          label: const Text('Dodaj lek'),
        ),
      ],
    );
  }
}

class _DoseCard extends StatelessWidget {
  const _DoseCard({
    required this.time,
    required this.name,
    required this.details,
    required this.status,
    required this.tone,
  });

  final String time;
  final String name;
  final String details;
  final String status;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Text(time, style: theme.textTheme.titleMedium),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleMedium),
                  Text(details, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusPill(label: status, tone: tone),
          ],
        ),
      ),
    );
  }
}

class _StandingMed extends StatelessWidget {
  const _StandingMed({
    required this.name,
    required this.schedule,
    this.isLast = false,
  });

  final String name;
  final String schedule;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.bodyLarge),
                Text(
                  schedule,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
