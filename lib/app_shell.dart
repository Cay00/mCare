import 'package:flutter/material.dart';

import 'package:m_opiekun/screens/appointments_screen.dart';
import 'package:m_opiekun/screens/health_screen.dart';
import 'package:m_opiekun/screens/home_screen.dart';
import 'package:m_opiekun/screens/medications_screen.dart';
import 'package:m_opiekun/screens/safe_zone_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

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
    (
      label: 'Strefa',
      icon: Icons.location_on_outlined,
      selected: Icons.location_on,
    ),
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
      const SafeZoneScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_tabs[_index].label)),
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
