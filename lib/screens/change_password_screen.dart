import 'package:m_opiekun/widgets/care_components.dart';
import 'package:flutter/material.dart';

import 'package:m_opiekun/widgets/prototype_page.dart';

/// Formularz zmiany hasła. Przycisk niczego nie zapisuje.
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: careAppBar(context, 'Zmiana hasła'),
      body: PrototypePage(
        children: [
          Text(
            'Wpisz obecne hasło i nowe. Zapis nie jest jeszcze podłączony.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const CareField(
            label: 'Obecne hasło',
            child: TextField(obscureText: true),
          ),
          const CareField(
            label: 'Nowe hasło',
            child: TextField(obscureText: true),
          ),
          const CareField(
            label: 'Powtórz nowe hasło',
            child: TextField(obscureText: true),
          ),
          FilledButton(
            onPressed: () => showPrototypeHint(context, 'Zmiana hasła'),
            child: const Text('Zapisz hasło'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
        ],
      ),
    );
  }
}
