import 'package:flutter/material.dart';

import 'package:m_opiekun/auth/auth_service.dart';
import 'package:m_opiekun/screens/register_screen.dart';
import 'package:m_opiekun/theme/app_theme.dart';
import 'package:m_opiekun/widgets/liquid.dart';

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
    final demoUsers = widget.auth.demoUsers;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LiquidBackground(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'mOpiekun',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Zaloguj się, aby kontynuować',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: CareColors.muted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    LiquidField(
                      controller: _email,
                      label: 'E-mail',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    LiquidField(
                      controller: _password,
                      label: 'Hasło',
                      obscureText: true,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Odzyskiwanie hasła nie jest jeszcze podłączone.',
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        child: const Text(
                          'Nie pamiętasz hasła?',
                          style: TextStyle(
                            color: CareColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      LiquidError(message: _error!),
                      const SizedBox(height: 12),
                    ],
                    LiquidButton(label: 'Zaloguj się', onPressed: _submit),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RegisterScreen(auth: widget.auth),
                          ),
                        );
                      },
                      child: const Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 15,
                            color: CareColors.muted,
                          ),
                          children: [
                            TextSpan(text: 'Nie masz konta? '),
                            TextSpan(
                              text: 'Zarejestruj się',
                              style: TextStyle(
                                color: CareColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Szybkie logowanie',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: CareColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final user in demoUsers)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: CareColors.line),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () =>
                                widget.auth.login(user.email, user.password),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: CareColors.soft,
                                    child: Text(
                                      _initials(user.name),
                                      style: const TextStyle(
                                        color: CareColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: CareColors.ink,
                                          ),
                                        ),
                                        Text(
                                          roleLabel(user.role),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: CareColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: CareColors.muted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  String letter(String word) => word[0].toUpperCase();
  if (parts.length == 1) return letter(parts.first);
  return '${letter(parts.first)}${letter(parts.last)}';
}
