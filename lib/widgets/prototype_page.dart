import 'package:flutter/material.dart';

/// Wspólny układ ekranu prototypu: krótki opis zakresu i przewijana treść.
class PrototypePage extends StatelessWidget {
  const PrototypePage({
    super.key,
    this.lead = '',
    required this.children,
    this.listKey,
  });

  final String lead;
  final List<Widget> children;
  final Key? listKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <Widget>[
      if (lead.isNotEmpty)
        Text(
          lead,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      if (lead.isNotEmpty) const SizedBox(height: 24),
    ];

    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        items.add(const SizedBox(height: 20));
      }
      items.add(children[i]);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = constraints.maxWidth > 760
            ? (constraints.maxWidth - 720) / 2
            : 20.0;
        return ListView(
          key: listKey,
          padding: EdgeInsets.fromLTRB(inset, 12, inset, 32),
          children: items,
        );
      },
    );
  }
}

void showPrototypeHint(BuildContext context, String action) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$action — miejsce na implementację')));
}
