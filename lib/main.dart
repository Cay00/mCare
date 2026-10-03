import 'package:flutter/material.dart';

import 'package:m_opiekun/app_shell.dart';
import 'package:m_opiekun/auth/auth_service.dart';
import 'package:m_opiekun/screens/login_screen.dart';
import 'package:m_opiekun/theme/app_theme.dart';

void main() {
  final auth = AuthService();
  runApp(OpiekunApp(auth: auth));
}

class OpiekunApp extends StatelessWidget {
  final AuthService auth;

  const OpiekunApp({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mOpiekun',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: AnimatedBuilder(
        animation: auth,
        builder: (context, _) {
          final user = auth.currentUser;
          if (user == null) return LoginScreen(auth: auth);
          return AppShell(auth: auth);
        },
      ),
    );
  }
}
