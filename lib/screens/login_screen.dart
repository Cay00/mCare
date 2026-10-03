import 'package:flutter/material.dart';

import 'package:m_opiekun/auth/auth_service.dart';
import 'package:m_opiekun/screens/register_screen.dart';
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
      backgroundColor: LiquidColors.bg,
      body: SafeArea(
        child: LiquidBackground(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 30,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xEB006B63),
                            Color(0xEB004D47),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(44),
                          topRight: Radius.circular(44),
                          bottomRight: Radius.circular(14),
                          bottomLeft: Radius.circular(44),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'mOpiekun',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Zaloguj się, aby kontynuować',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      LiquidError(message: _error!),
                    ],
                    const SizedBox(height: 16),
                    LiquidButton(label: 'Zaloguj się', onPressed: _submit),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RegisterScreen(auth: widget.auth),
                          ),
                        );
                      },
                      child: const Text(
                        'Nie masz konta? Zarejestruj się',
                        style: TextStyle(
                          color: LiquidColors.teal,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Szybkie logowanie', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    for (final user in demoUsers)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(24),
                            bottomLeft: Radius.circular(8),
                          ),
                          child: InkWell(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(24),
                              bottomLeft: Radius.circular(8),
                            ),
                            onTap: () =>
                                widget.auth.login(user.email, user.password),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: LiquidColors.mint,
                                    child: Icon(
                                      user.role == UserRole.patient
                                          ? Icons.person_outline
                                          : Icons.favorite_outline,
                                      color: const Color(0xFF003B36),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: LiquidColors.ink,
                                        ),
                                      ),
                                      Text(
                                        roleLabel(user.role),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: LiquidColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: LiquidColors.muted,
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
