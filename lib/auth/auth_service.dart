import 'package:flutter/material.dart';

enum UserRole {
  patient('Chory'),
  caregiver('Opiekun');

  const UserRole(this.label);

  final String label;
}

/// Stały identyfikator w kodzie QR. Sam kod nie daje dostępu —
/// chory musi jeszcze potwierdzić, co udostępnia.
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

enum Gender { female, male }

String roleLabel(UserRole role) => role == UserRole.patient ? 'Użytkownik' : 'Opiekun';

String genderLabel(Gender gender) => gender == Gender.female ? 'Kobieta' : 'Mężczyzna';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String password;
  final UserRole role;
  final int age;
  final Gender gender;
  final double weight;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.age,
    required this.gender,
    required this.weight,
  });

  String get codePayload => '$userCodePrefix$id';
}

class AuthService extends ChangeNotifier {
  final List<AppUser> _users = [
    const AppUser(
      id: 'JKB-1042',
      name: 'Jakub B',
      email: 'user1',
      password: 'helpMe',
      role: UserRole.patient,
      age: 72,
      gender: Gender.male,
      weight: 80,
    ),
    const AppUser(
      id: 'ANN-2208',
      name: 'Anna Kowalska',
      email: 'caregiver',
      password: 'careme',
      role: UserRole.caregiver,
      age: 45,
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
    required int age,
    required Gender gender,
    required double weight,
  }) {
    final normalized = email.trim().toLowerCase();
    if (name.trim().isEmpty) return 'Podaj imię i nazwisko';
    if (!normalized.contains('@')) return 'Podaj poprawny adres e-mail';
    if (password.length < 6) return 'Hasło musi mieć co najmniej 6 znaków';
    if (age < 0 || age > 120) return 'Podaj poprawny wiek';
    if (weight <= 0 || weight > 300) return 'Podaj poprawną wagę';
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
        age: age,
        gender: gender,
        weight: weight,
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
