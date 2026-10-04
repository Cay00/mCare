import 'package:flutter/material.dart';

enum StatusTone { neutral, ready, done }

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (background, foreground) = switch (tone) {
      StatusTone.done => (const Color(0xFFE7F6EE), const Color(0xFF128A48)),
      StatusTone.ready => (const Color(0xFFFFF4E5), const Color(0xFFB45309)),
      StatusTone.neutral => (const Color(0xFFF1F3F2), const Color(0xFF5C675F)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
