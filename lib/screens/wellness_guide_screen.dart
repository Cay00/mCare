import 'package:m_opiekun/widgets/prototype_page.dart';
import 'package:m_opiekun/widgets/care_components.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/guide_colors.dart';

import 'package:m_opiekun/models/wellness_guide.dart';

/// Tekst jednej porady: wstęp i kolejne kroki ćwiczenia.
class WellnessGuideScreen extends StatelessWidget {
  const WellnessGuideScreen({super.key, required this.guide});

  final WellnessGuide guide;

  @override
  Widget build(BuildContext context) {
    final colors = guideColors(guide.icon);

    return Scaffold(
      appBar: careAppBar(context, guide.title),
      body: PrototypePage(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  constraints.maxWidth /
                          MediaQuery.textScalerOf(context).scale(1) >=
                      300
                  ? 2
                  : 1;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Intro(guide: guide, colors: colors),
                  const SizedBox(height: 16),
                  for (var i = 0; i < guide.steps.length; i += columns) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _StepRow(
                      color: colors.background,
                      accent: colors.foreground,
                      steps: [
                        for (
                          var j = i;
                          j < guide.steps.length && j < i + columns;
                          j++
                        )
                          (number: j + 1, text: guide.steps[j]),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  const CareNotice(
                    'To propozycja ćwiczenia, nie porada lekarska. '
                    'Przy złym samopoczuciu skontaktuj się z lekarzem albo bliską osobą.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.guide, required this.colors});

  final WellnessGuide guide;
  final ({Color foreground, Color background}) colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(guide.icon, size: 28, color: colors.foreground),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  guide.duration,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            guide.intro,
            style: theme.textTheme.bodyLarge?.copyWith(color: CareColors.ink),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.steps,
    required this.color,
    required this.accent,
  });

  final List<({int number, String text})> steps;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: _Step(
                number: steps[i].number,
                text: steps[i].text,
                color: color,
                accent: accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.text,
    required this.color,
    required this.accent,
  });

  final int number;
  final String text;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '$number',
                style: theme.textTheme.titleMedium?.copyWith(color: accent),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(color: CareColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
