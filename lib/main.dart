import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:m_opiekun/app_shell.dart';
import 'package:m_opiekun/theme/app_theme.dart';

const supabaseUrl = 'https://zkrbcxlozggztmvcrid.supabase.co';
const supabaseAnonKey = 'sb_publishable_GVeGCHqiXndiX3Pq_TC5Lg_Mxz8MVRO';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);

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
