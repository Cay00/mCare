import 'package:m_opiekun/widgets/care_components.dart';
import 'package:flutter/material.dart';

import 'package:m_opiekun/auth/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final AuthService auth;

  const LoginScreen({super.key, required this.auth});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  void _submit() {
    final error = widget.auth.login(_email.text, _password.text);
    setState(() => _error = error);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: CareIcon(Icons.favorite_outline),
                  ),
                  const SizedBox(height: 24),
                  const CareHeading(
                    'Dobrze mieć wsparcie',
                    eyebrow: 'mCare',
                    subtitle: 'Twoje leki, zdrowie i bliscy w jednym miejscu.',
                  ),
                  const SizedBox(height: 32),
                  CareField(
                    label: 'Login',
                    child: TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  CareField(
                    label: 'Hasło',
                    child: TextField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    CareNotice(_error!, error: true),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Zaloguj się'),
                  ),
                  const SizedBox(height: 28),
                  const CareHeading(
                    'Wypróbuj aplikację',
                    subtitle: 'Wybierz przykładowe konto.',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => widget.auth.login('user1', 'helpMe'),
                    child: const Text('Zaloguj jako chory'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => widget.auth.login('caregiver', 'careme'),
                    child: const Text('Zaloguj jako opiekun'),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Konta demo',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chory: user1 / helpMe · kod JKB-1042',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            'Opiekun: caregiver / careme',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
