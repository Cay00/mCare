import 'package:flutter/material.dart';

import 'package:m_opiekun/auth/auth_service.dart';
import 'package:m_opiekun/theme/app_theme.dart';
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
  final _birthDateText = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  UserRole _role = UserRole.patient;
  Gender _gender = Gender.female;
  DateTime? _birthDate;
  String? _error;
  AppUser? _registered;

  void _submit() {
    final error = widget.auth.register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      role: _role,
      birthDate: _birthDate,
      gender: _gender,
      heightText: _height.text,
      weightText: _weight.text,
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

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = DateTime(today.year - 120, 1, 1);
    final fallback = DateTime(today.year - 70, today.month, today.day);
    final initial = _birthDate ?? fallback;
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('pl'),
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: today,
      helpText: 'Data urodzenia',
      cancelText: 'Anuluj',
      confirmText: 'Wybierz',
    );
    if (picked == null) return;
    setState(() {
      _birthDate = DateTime(picked.year, picked.month, picked.day);
      _birthDateText.text = formatBirthDate(_birthDate!);
      _error = null;
    });
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
    _birthDateText.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registered = _registered;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: const Text('Rejestracja'),
      ),
      body: SafeArea(
        child: LiquidBackground(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: registered == null
                    ? _form()
                    : _success(registered),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LiquidField(controller: _name, label: 'Imię'),
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
        const SizedBox(height: 16),
        const Text(
          'Płeć',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: CareColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        _ChoiceRow<Gender>(
          value: _gender,
          options: const [Gender.female, Gender.male, Gender.other],
          label: genderLabel,
          onChanged: (gender) => setState(() => _gender = gender),
        ),
        const SizedBox(height: 16),
        LiquidField(
          controller: _birthDateText,
          label: 'Data urodzenia',
          readOnly: true,
          hintText: 'Wybierz datę',
          onTap: _pickBirthDate,
          suffixIcon: const Icon(
            Icons.calendar_today_outlined,
            color: CareColors.muted,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Typ konta',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: CareColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        _ChoiceRow<UserRole>(
          value: _role,
          options: const [UserRole.patient, UserRole.caregiver],
          label: roleLabel,
          onChanged: (role) => setState(() => _role = role),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: LiquidField(
                controller: _height,
                label: 'Wzrost (cm)',
                keyboardType: TextInputType.number,
                hintText: 'Opcjonalnie',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: LiquidField(
                controller: _weight,
                label: 'Waga (kg)',
                keyboardType: TextInputType.number,
                hintText: 'Opcjonalnie',
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          LiquidError(message: _error!),
        ],
        const SizedBox(height: 16),
        LiquidButton(label: 'Zarejestruj się', onPressed: _submit),
      ],
    );
  }

  Widget _success(AppUser registered) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: CareColors.primary,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 84,
              height: 84,
              child: Icon(Icons.check_rounded, color: Colors.white, size: 44),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Konto utworzone',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 18),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CareColors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: CareColors.soft,
                      child: Text(
                        _initials(registered.name),
                        style: const TextStyle(
                          color: CareColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: registered.name,
                              style: theme.textTheme.titleMedium,
                            ),
                            TextSpan(
                              text: ' · ${roleLabel(registered.role)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: CareColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                _SummaryRow(
                  label: 'Data urodzenia',
                  value: formatBirthDate(registered.birthDate),
                ),
                _SummaryRow(label: 'Wiek', value: '${registered.age} lat'),
                _SummaryRow(
                  label: 'Płeć',
                  value: genderLabel(registered.gender),
                ),
                _SummaryRow(
                  label: 'Wzrost',
                  value: registered.heightCm == null
                      ? '—'
                      : '${_measure(registered.heightCm!)} cm',
                ),
                _SummaryRow(
                  label: 'Waga',
                  value: registered.weight == null
                      ? '—'
                      : '${_measure(registered.weight!)} kg',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        LiquidButton(
          label: 'Zaloguj się automatycznie',
          onPressed: _loginAutomatically,
        ),
      ],
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.value,
    required this.options,
    required this.label,
    required this.onChanged,
  });

  final T value;
  final List<T> options;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(label(option)),
            selected: option == value,
            showCheckmark: false,
            onSelected: (_) => onChanged(option),
            selectedColor: CareColors.primary,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: option == value ? Colors.white : CareColors.ink,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(
              color: option == value ? CareColors.primary : CareColors.line,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: CareColors.muted,
              ),
            ),
          ),
          Text(value, style: theme.textTheme.titleSmall),
        ],
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

String _measure(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1).replaceAll('.', ',');
}
