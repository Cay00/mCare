import 'package:flutter/material.dart';

import 'package:m_opiekun/auth/auth_service.dart';
import 'package:m_opiekun/screens/appointments_screen.dart';
import 'package:m_opiekun/screens/health_screen.dart';
import 'package:m_opiekun/screens/home_screen.dart';
import 'package:m_opiekun/screens/medications_screen.dart';
import 'package:m_opiekun/screens/profile_screen.dart';
import 'package:m_opiekun/sharing/sharing_service.dart';

class AppShell extends StatefulWidget {
  final AuthService auth;
  final SharingService sharing;

  const AppShell({super.key, required this.auth, required this.sharing});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _tabs = [
    (label: 'Dziś', icon: Icons.wb_sunny_outlined, selected: Icons.wb_sunny),
    (
      label: 'Leki',
      icon: Icons.medication_outlined,
      selected: Icons.medication,
    ),
    (
      label: 'Zdrowie',
      icon: Icons.medical_information_outlined,
      selected: Icons.medical_information,
    ),
    (label: 'Wizyty', icon: Icons.event_outlined, selected: Icons.event),
    (label: 'Profil', icon: Icons.person_outline, selected: Icons.person),
  ];

  void _openTab(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenTab: _openTab),
      const MedicationsScreen(),
      const HealthScreen(),
      const AppointmentsScreen(),
      ProfileScreen(auth: widget.auth, sharing: widget.sharing),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_tabs[_index].label),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.auth.logout,
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: _openTab,
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selected),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
