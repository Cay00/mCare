import 'package:flutter/material.dart';

import 'package:m_opiekun/auth/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final AuthService auth;

  const RegisterScreen({super.key, required this.auth});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.patient;
  String? _error;
  AppUser? _registered;

  void _submit() {
    final error = widget.auth.register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      role: _role,
    );
    if (error == null) {
      final normalized = _email.text.trim().toLowerCase();
      final user = widget.auth.demoUsers.firstWhere(
        (u) => u.email == normalized,
      );
      setState(() {
        _registered = user;
        _error = null;
      });
    } else {
      setState(() => _error = error);
    }
  }

  void _loginAutomatically() {
    final user = _registered;
    if (user == null) return;
    widget.auth.login(user.email, user.password);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final registered = _registered;

    return Scaffold(
      appBar: AppBar(title: const Text('Rejestracja')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: registered == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Imię i nazwisko',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 16),
                        SegmentedButton<UserRole>(
                          segments: const [
                            ButtonSegment(
                              value: UserRole.patient,
                              label: Text('Użytkownik'),
                              icon: Icon(Icons.person_outline),
                            ),
                            ButtonSegment(
                              value: UserRole.caregiver,
                              label: Text('Opiekun'),
                              icon: Icon(Icons.favorite_outline),
                            ),
                          ],
                          selected: {_role},
                          onSelectionChanged: (selection) =>
                              setState(() => _role = selection.first),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _submit,
                          child: const Text('Zarejestruj się'),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 48,
                                color: colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Konto utworzone',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${registered.name} · ${roleLabel(registered.role)}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _loginAutomatically,
                          child: const Text('Zaloguj się automatycznie'),
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
