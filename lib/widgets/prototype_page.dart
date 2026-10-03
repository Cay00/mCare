import 'package:flutter/material.dart';

/// Wspólny układ ekranu prototypu: krótki opis zakresu i przewijana treść.
class PrototypePage extends StatelessWidget {
  const PrototypePage({
    super.key,
    required this.lead,
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
      Text(
        lead,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 20),
    ];

    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        items.add(const SizedBox(height: 12));
      }
      items.add(children[i]);
    }

    return ListView(
      key: listKey,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: items,
    );
  }
}

void showPrototypeHint(BuildContext context, String action) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$action — miejsce na implementację')));
}
