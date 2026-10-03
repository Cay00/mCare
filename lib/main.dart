import 'package:flutter/material.dart';

import 'package:m_opiekun/app_shell.dart';
import 'package:m_opiekun/auth/auth_service.dart';
import 'package:m_opiekun/screens/login_screen.dart';
import 'package:m_opiekun/sharing/sharing_service.dart';
import 'package:m_opiekun/theme/app_theme.dart';

void main() {
  final auth = AuthService();
  final sharing = SharingService();
  runApp(OpiekunApp(auth: auth, sharing: sharing));
}

class OpiekunApp extends StatelessWidget {
  final AuthService auth;
  final SharingService sharing;

  OpiekunApp({super.key, required this.auth, SharingService? sharing})
    : sharing = sharing ?? SharingService();

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
          return AppShell(auth: auth, sharing: sharing);
        },
      ),
    );
  }
}
