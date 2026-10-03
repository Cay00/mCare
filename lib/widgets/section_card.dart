import 'package:flutter/material.dart';
import 'care_components.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
  });

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (MediaQuery.textScalerOf(context).scale(20) > 28) ...[
              if (icon != null) ...[
                Align(alignment: Alignment.centerLeft, child: CareIcon(icon!)),
                const SizedBox(height: 16),
              ],
              Semantics(
                header: true,
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
            ] else
              Row(
                children: [
                  if (icon != null) ...[
                    CareIcon(icon!),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(title, style: theme.textTheme.titleMedium),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
