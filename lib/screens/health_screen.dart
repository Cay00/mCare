import 'package:flutter/material.dart';

import 'package:m_opiekun/widgets/prototype_page.dart';
import 'package:m_opiekun/widgets/section_card.dart';

/// Zdrowie: dane medyczne, zalecenia i eksport PDF.
///
/// Do zbudowania: edycja karty, lista zaleceń od lekarza oraz
/// generowanie jednego PDF z tych informacji. Przycisk nic nie eksportuje.
class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrototypePage(
      lead:
          'Karta medyczna, zalecenia lekarza i eksport tych informacji do PDF '
          'dla wizyty albo opiekuna.',
      children: [
        const SectionCard(
          title: 'Dane medyczne',
          icon: Icons.medical_information_outlined,
          child: Column(
            children: [
              _Fact(label: 'Osoba', value: 'Maria Kowalska'),
              _Fact(label: 'Grupa krwi', value: 'A Rh+'),
              _Fact(label: 'Alergie', value: 'Penicylina'),
              _Fact(label: 'Choroby', value: 'Nadciśnienie, cukrzyca typu 2'),
              _Fact(label: 'Lekarz prowadzący', value: 'dr Anna Nowak'),
              _Fact(
                label: 'Kontakt alarmowy',
                value: 'Jan Kowalski, syn · 500 100 200',
                isLast: true,
              ),
            ],
          ),
        ),
        const SectionCard(
          title: 'Zalecenia',
          icon: Icons.favorite_outline,
          child: Column(
            children: [
              _Advice(text: 'Mierz ciśnienie każdego ranka, przed lekami.'),
              _Advice(text: 'Metformax bierz w trakcie posiłku.'),
              _Advice(text: 'Pij około 1,5 litra wody dziennie.'),
              _Advice(text: 'Krótki spacer, jeśli ciśnienie jest w normie.'),
              _Advice(text: 'Ogranicz sól.', isLast: true),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () => showPrototypeHint(context, 'Eksport karty do PDF'),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Eksportuj kartę do PDF'),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.isLast = false});

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
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

class _Advice extends StatelessWidget {
  const _Advice({required this.text, this.isLast = false});

  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(
              Icons.circle,
              size: 8,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
