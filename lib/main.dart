import 'package:flutter/material.dart';

import 'package:m_opiekun/app_shell.dart';
import 'package:m_opiekun/theme/app_theme.dart';

void main() {
  runApp(const OpiekunApp());
}

class OpiekunApp extends StatelessWidget {
  const OpiekunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mOpiekun',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppShell(),
    );
  }
}
