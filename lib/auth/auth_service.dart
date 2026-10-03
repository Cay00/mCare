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

class AppUser {
  final String id;
  final String name;
  final String email;
  final String password;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
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
    ),
    const AppUser(
      id: 'ANN-2208',
      name: 'Anna Kowalska',
      email: 'caregiver',
      password: 'careme',
      role: UserRole.caregiver,
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

  void logout() {
    currentUser = null;
    notifyListeners();
  }
}
