import 'package:flutter/material.dart';

import 'package:m_opiekun/models/wellness_guide.dart';

/// Tekst jednej porady: wstęp i kolejne kroki ćwiczenia.
class WellnessGuideScreen extends StatelessWidget {
  const WellnessGuideScreen({super.key, required this.guide});

  final WellnessGuide guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(guide.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  guide.icon,
                  size: 30,
                  color: theme.colorScheme.primary,
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
          const SizedBox(height: 20),
          Text(guide.intro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 20),
          for (var i = 0; i < guide.steps.length; i++) ...[
            _Step(number: i + 1, text: guide.steps[i]),
            if (i < guide.steps.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 24),
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
          width: 32,
          height: 32,
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
