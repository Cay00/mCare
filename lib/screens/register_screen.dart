import 'package:flutter/material.dart';

import 'package:m_opiekun/auth/auth_service.dart';
import 'package:m_opiekun/widgets/liquid.dart';

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
  final _age = TextEditingController();
  final _weight = TextEditingController();
  UserRole _role = UserRole.patient;
  Gender _gender = Gender.female;
  String? _error;
  AppUser? _registered;

  void _submit() {
    final age = int.tryParse(_age.text.trim());
    final weight = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    if (age == null || weight == null) {
      setState(() => _error = 'Podaj poprawny wiek i wagę');
      return;
    }
    final error = widget.auth.register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      role: _role,
      age: age,
      gender: _gender,
      weight: weight,
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
    _age.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final registered = _registered;

    return Scaffold(
      backgroundColor: LiquidColors.bg,
      appBar: AppBar(
        backgroundColor: LiquidColors.bg,
        title: const Text('Rejestracja'),
      ),
      body: SafeArea(
        child: LiquidBackground(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: registered == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LiquidField(controller: _name, label: 'Imię i nazwisko'),
                          const SizedBox(height: 14),
                          LiquidField(
                            controller: _email,
                            label: 'E-mail',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          LiquidField(
                            controller: _password,
                            label: 'Hasło',
                            obscureText: true,
                          ),
                          const SizedBox(height: 14),
                          SegmentedButton<Gender>(
                            segments: const [
                              ButtonSegment(
                                value: Gender.female,
                                label: Text('Kobieta'),
                              ),
                              ButtonSegment(
                                value: Gender.male,
                                label: Text('Mężczyzna'),
                              ),
                            ],
                            selected: {_gender},
                            onSelectionChanged: (selection) =>
                                setState(() => _gender = selection.first),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: LiquidField(
                                  controller: _age,
                                  label: 'Wiek',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: LiquidField(
                                  controller: _weight,
                                  label: 'Waga (kg)',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
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
                          LiquidButton(
                            label: 'Zarejestruj się',
                            onPressed: _submit,
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: LiquidColors.mint.withValues(alpha: 0.35),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(44),
                                topRight: Radius.circular(44),
                                bottomRight: Radius.circular(14),
                                bottomLeft: Radius.circular(44),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 48,
                                  color: LiquidColors.teal,
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
                                Text(
                                  '${registered.age} lat · ${genderLabel(registered.gender)} · ${registered.weight} kg',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          LiquidButton(
                            label: 'Zaloguj się automatycznie',
                            onPressed: _loginAutomatically,
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
