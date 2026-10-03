import 'package:m_opiekun/widgets/prototype_page.dart';
import 'package:m_opiekun/widgets/care_components.dart';
import 'package:flutter/material.dart';
import '../theme/guide_colors.dart';

import 'package:m_opiekun/models/wellness_guide.dart';

/// Tekst jednej porady: wstęp i kolejne kroki ćwiczenia.
class WellnessGuideScreen extends StatelessWidget {
  const WellnessGuideScreen({super.key, required this.guide});

  final WellnessGuide guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: careAppBar(context, guide.title),
      body: PrototypePage(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: guideColors(guide.icon).background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  guide.icon,
                  size: 30,
                  color: guideColors(guide.icon).foreground,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  guide.duration,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          Text(guide.intro, style: theme.textTheme.bodyLarge),
          for (var i = 0; i < guide.steps.length; i++) ...[
            _Step(number: i + 1, text: guide.steps[i]),
            if (i < guide.steps.length - 1) const SizedBox(height: 10),
          ],
          Text(
            'To propozycja ćwiczenia, nie porada lekarska. '
            'Przy złym samopoczuciu skontaktuj się z lekarzem albo bliską osobą.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(text, style: theme.textTheme.bodyLarge),
          ),
        ),
      ],
    );
  }
}
