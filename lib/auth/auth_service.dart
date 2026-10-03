import 'package:flutter/material.dart';

enum UserRole {
  patient('Pacjent'),
  caregiver('Opiekun');

  const UserRole(this.label);

  final String label;
}

/// Stały identyfikator w kodzie QR. Sam kod nie daje dostępu —
/// pacjent musi jeszcze potwierdzić, co udostępnia.
const userCodePrefix = 'mopiekun:user:';

String? userIdFromScan(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  if (value.toLowerCase().startsWith(userCodePrefix)) {
    final id = value.substring(userCodePrefix.length).trim();
    return id.isEmpty ? null : id;
  }
  return value;
}

enum Gender { female, male, other }

String roleLabel(UserRole role) => role.label;

String genderLabel(Gender gender) => switch (gender) {
  Gender.female => 'Kobieta',
  Gender.male => 'Mężczyzna',
  Gender.other => 'Inne',
};

int ageFromBirthDate(DateTime birthDate, {DateTime? today}) {
  final now = today ?? DateTime.now();
  var years = now.year - birthDate.year;
  final birthdayPassed =
      now.month > birthDate.month ||
      (now.month == birthDate.month && now.day >= birthDate.day);
  if (!birthdayPassed) years -= 1;
  return years;
}

String formatBirthDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String password;
  final UserRole role;
  final DateTime birthDate;
  final Gender gender;
  final double? weight;
  final double? heightCm;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.birthDate,
    required this.gender,
    this.weight,
    this.heightCm,
  });

  int get age => ageFromBirthDate(birthDate);

  String get codePayload => '$userCodePrefix$id';
}

class AuthService extends ChangeNotifier {
  final List<AppUser> _users = [
    AppUser(
      id: 'JKB-1042',
      name: 'Jakub B',
      email: 'user1',
      password: 'helpMe',
      role: UserRole.patient,
      birthDate: DateTime(1954, 6, 15),
      gender: Gender.male,
      weight: 80,
    ),
    AppUser(
      id: 'ANN-2208',
      name: 'Anna Kowalska',
      email: 'caregiver',
      password: 'careme',
      role: UserRole.caregiver,
      birthDate: DateTime(1981, 3, 20),
      gender: Gender.female,
      weight: 65,
    ),
  ];

  AppUser? currentUser;

  AppUser? userById(String id) {
    for (final user in _users) {
      if (user.id == id) return user;
    }
    return null;
  }

  AppUser? userByCode(String raw) {
    final id = userIdFromScan(raw);
    if (id == null) return null;
    final normalized = id.toUpperCase();
    for (final user in _users) {
      if (user.id.toUpperCase() == normalized) return user;
    }
    return null;
  }

  List<AppUser> get demoUsers => List.unmodifiable(_users);

  String? login(String email, String password) {
    final normalized = email.trim().toLowerCase();
    for (final user in _users) {
      if (user.email == normalized && user.password == password) {
        currentUser = user;
        notifyListeners();
        return null;
      }
    }
    return 'Nieprawidłowy e-mail lub hasło';
  }

  String? register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    DateTime? birthDate,
    required Gender gender,
    String heightText = '',
    String weightText = '',
  }) {
    final normalized = email.trim().toLowerCase();
    if (name.trim().isEmpty) return 'Podaj imię';
    if (!normalized.contains('@')) return 'Podaj poprawny adres e-mail';
    if (password.length < 6) return 'Hasło musi mieć co najmniej 6 znaków';
    if (birthDate == null) return 'Podaj datę urodzenia';
    final age = ageFromBirthDate(birthDate);
    if (age < 0 || age > 120) return 'Podaj poprawną datę urodzenia';
    final height = _optionalMeasure(heightText);
    if (height.invalid) return 'Podaj poprawny wzrost';
    if (height.value != null && (height.value! < 50 || height.value! > 250)) {
      return 'Podaj wzrost w zakresie 50–250 cm';
    }
    final weight = _optionalMeasure(weightText);
    if (weight.invalid ||
        (weight.value != null && (weight.value! <= 0 || weight.value! > 300))) {
      return 'Podaj poprawną wagę';
    }
    if (_users.any((user) => user.email == normalized)) {
      return 'Konto z tym adresem e-mail już istnieje';
    }
    _users.add(
      AppUser(
        id: 'USR-${_users.length + 1}',
        name: name.trim(),
        email: normalized,
        password: password,
        role: role,
        birthDate: DateTime(birthDate.year, birthDate.month, birthDate.day),
        gender: gender,
        weight: weight.value,
        heightCm: height.value,
      ),
    );
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }
}

({double? value, bool invalid}) _optionalMeasure(String raw) {
  final text = raw.trim().replaceAll(',', '.');
  if (text.isEmpty) return (value: null, invalid: false);
  final value = double.tryParse(text);
  if (value == null) return (value: null, invalid: true);
  return (value: value, invalid: false);
}
