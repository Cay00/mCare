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
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('mOpiekun', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Zaloguj się, aby kontynuować',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Hasło',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Zaloguj się'),
                  ),
                  const SizedBox(height: 12),
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
                            'Chory: User1 / helpMe',
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
