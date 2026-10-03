import 'package:flutter/material.dart';

enum UserRole { patient, caregiver }

class AppUser {
  final String name;
  final String email;
  final String password;
  final UserRole role;

  const AppUser({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });
}

class AuthService extends ChangeNotifier {
  final List<AppUser> _users = [
    const AppUser(
      name: 'Jakub B',
      email: 'user1',
      password: 'helpMe',
      role: UserRole.patient,
    ),
    const AppUser(
      name: 'Anna Kowalska',
      email: 'caregiver',
      password: 'careme',
      role: UserRole.caregiver,
    ),
  ];

  AppUser? currentUser;

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
