import 'package:flutter/material.dart';

import 'package:m_opiekun/auth/auth_service.dart';
import 'package:m_opiekun/screens/appointments_screen.dart';
import 'package:m_opiekun/screens/health_screen.dart';
import 'package:m_opiekun/screens/home_screen.dart';
import 'package:m_opiekun/screens/medications_screen.dart';
import 'package:m_opiekun/screens/profile_screen.dart';
import 'package:m_opiekun/services/safe_zone_store.dart';
import 'package:m_opiekun/sharing/sharing_service.dart';
import 'package:m_opiekun/theme/app_theme.dart';

class AppShell extends StatefulWidget {
  final AuthService auth;
  final SharingService sharing;

  const AppShell({super.key, required this.auth, required this.sharing});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  int _knownAlerts = 0;

  @override
  void initState() {
    super.initState();
    _knownAlerts = SafeZoneStore.instance.alerts.length;
    widget.auth.addListener(_bindZone);
    widget.sharing.addListener(_bindZone);
    SafeZoneStore.instance.addListener(_onZoneAlert);
    _bindZone();
  }

  @override
  void dispose() {
    widget.auth.removeListener(_bindZone);
    widget.sharing.removeListener(_bindZone);
    SafeZoneStore.instance.removeListener(_onZoneAlert);
    SafeZoneStore.instance.pauseTracking();
    super.dispose();
  }

  void _bindZone() {
    SafeZoneStore.instance.bind(auth: widget.auth, sharing: widget.sharing);
  }

  void _onZoneAlert() {
    if (!mounted) return;
    final alerts = SafeZoneStore.instance.alerts;
    if (alerts.length > _knownAlerts && alerts.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(alerts.first.message)));
    }
    _knownAlerts = alerts.length;
  }

  static const _tabs = [
    (label: 'Dziś', icon: Icons.wb_sunny_outlined, selected: Icons.wb_sunny),
    (
      label: 'Leki',
      icon: Icons.medication_outlined,
      selected: Icons.medication,
    ),
    (
      label: 'Zdrowie',
      icon: Icons.monitor_heart_outlined,
      selected: Icons.monitor_heart,
    ),
    (label: 'Porady', icon: Icons.favorite_border, selected: Icons.favorite),
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
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ClipRect(
            key: const Key('tabContentViewport'),
            child: IndexedStack(index: _index, children: pages),
          ),
        ),
      ),
      bottomNavigationBar: MediaQuery.textScalerOf(context).scale(14) > 20
          ? _largeTextNavigation(context)
          : DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: CareColors.line)),
              ),
              child: NavigationBar(
                selectedIndex: _index,
                backgroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.white,
                indicatorColor: CareColors.soft,
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
            ),
    );
  }

  Widget _largeTextNavigation(BuildContext context) => Material(
    color: Colors.white,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (var i = 0; i < _tabs.length; i++)
                SizedBox(
                  width: (constraints.maxWidth - 8) / 3,
                  child: Semantics(
                    selected: i == _index,
                    child: TextButton(
                      key: ValueKey('nav-${_tabs[i].label}'),
                      onPressed: () => _openTab(i),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                        backgroundColor: i == _index
                            ? CareColors.soft
                            : Colors.white,
                        foregroundColor: i == _index
                            ? CareColors.primary
                            : CareColors.muted,
                      ),
                      child: Column(
                        children: [
                          Icon(i == _index ? _tabs[i].selected : _tabs[i].icon),
                          const SizedBox(height: 4),
                          Text(
                            _tabs[i].label,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
