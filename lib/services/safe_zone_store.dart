import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:m_opiekun/auth/auth_service.dart';
import 'package:m_opiekun/services/safe_zone.dart';
import 'package:m_opiekun/services/zone_notifications.dart';
import 'package:m_opiekun/sharing/sharing_service.dart';

enum LocationAccess { granted, denied, disabled }

abstract class LocationFeed {
  Future<LocationAccess> ensureAccess();
  Future<GeoFix> current();
  Stream<GeoFix> watch();
}

class GeolocatorLocationFeed implements LocationFeed {
  @override
  Future<LocationAccess> ensureAccess() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return LocationAccess.disabled;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        return LocationAccess.granted;
      }
      return LocationAccess.denied;
    } catch (error) {
      debugPrint('Brak dostępu do lokalizacji: $error');
      return LocationAccess.denied;
    }
  }

  @override
  Future<GeoFix> current() async {
    final position = await Geolocator.getCurrentPosition();
    return GeoFix(
      latitude: position.latitude,
      longitude: position.longitude,
      at: position.timestamp,
    );
  }

  @override
  Stream<GeoFix> watch() {
    return Geolocator.getPositionStream(
      locationSettings: _streamSettings(),
    ).map(
      (position) => GeoFix(
        latitude: position.latitude,
        longitude: position.longitude,
        at: position.timestamp,
      ),
    );
  }

  LocationSettings _streamSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Bezpieczna strefa',
          notificationText: 'Aplikacja sprawdza, czy pacjent jest w strefie.',
          notificationChannelName: 'Pilnowanie strefy',
          setOngoing: true,
        ),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    );
  }
}

class _WatchTarget {
  const _WatchTarget({
    required this.patientId,
    required this.patientName,
    required this.caregiverNames,
  });

  final String patientId;
  final String patientName;
  final List<String> caregiverNames;
}

class SafeZoneStore extends ChangeNotifier {
  SafeZoneStore({LocationFeed? location})
    : _location = location ?? GeolocatorLocationFeed();

  static final SafeZoneStore instance = SafeZoneStore();
  static const storageKey = 'safe_zone_state_v1';

  final LocationFeed _location;
  final Map<String, SafeZone> _zones = {};
  final Map<String, bool> _monitoring = {};
  final Map<String, ZonePresence> _presence = {};
  final Map<String, GeoFix> _fixes = {};
  final List<SafeZoneAlert> _alerts = [];

  ZoneSession session = ZoneSession.guest;
  String? locationMessage;
  bool isLoaded = false;
  Future<void>? _loading;
  Future<void> _pendingWrite = Future<void>.value();
  StreamSubscription<GeoFix>? _subscription;
  _WatchTarget? _active;

  List<SafeZoneAlert> get alerts => List.unmodifiable(_alerts);

  int get unreadCount => _alerts.where((alert) => !alert.seen).length;

  Future<void> load() => _loading ??= _read();

  SafeZone? zoneFor(String patientId) => _zones[patientId];

  ZonePresence presenceFor(String patientId) =>
      _presence[patientId] ?? ZonePresence.unknown;

  GeoFix? fixFor(String patientId) => _fixes[patientId];

  bool isMonitoring(String patientId) => _monitoring[patientId] ?? false;

  List<SafeZoneAlert> alertsForPatient(String patientId) {
    return _alerts.where((alert) => alert.patientId == patientId).toList();
  }

  ({String title, String subtitle, bool outside}) homeStatus() {
    if (session.signedIn && !session.canEdit && session.patientId.isEmpty) {
      return (
        title: 'Brak dostępu do strefy',
        subtitle: 'Pacjent może udostępnić pobyt w bezpiecznej strefie.',
        outside: false,
      );
    }
    final zone = session.patientId.isEmpty ? null : zoneFor(session.patientId);
    if (zone == null) {
      return (
        title: session.canEdit ? 'Ustaw strefę' : 'Strefa nieustawiona',
        subtitle: session.canEdit
            ? 'Wskaż dom i promień na mapie.'
            : '${session.patientName} nie wyznaczył jeszcze miejsca.',
        outside: false,
      );
    }
    final place = '${zone.label} · promień ${zone.radiusMeters} m';
    return switch (presenceFor(session.patientId)) {
      ZonePresence.inside => (
        title: 'W bezpiecznej strefie',
        subtitle: place,
        outside: false,
      ),
      ZonePresence.outside => (
        title: 'Poza bezpieczną strefą',
        subtitle: place,
        outside: true,
      ),
      ZonePresence.unknown => (
        title: zone.label,
        subtitle: isMonitoring(session.patientId)
            ? '$place · sprawdzam lokalizację'
            : '$place · pilnowanie wyłączone',
        outside: false,
      ),
    };
  }

  void bind({required AuthService auth, required SharingService sharing}) {
    final user = auth.currentUser;
    if (user == null) {
      session = ZoneSession.guest;
      notifyListeners();
      return;
    }
    if (user.role == UserRole.patient) {
      final names = [
        for (final link in sharing.forPatient(user.id))
          if (link.status == CareLinkStatus.accepted &&
              link.scopes.contains(ShareScope.zone))
            auth.userById(link.caregiverId)?.name ?? 'Opiekun',
      ];
      session = ZoneSession(
        patientId: user.id,
        patientName: user.name,
        caregiverNames: names,
        canEdit: true,
        signedIn: true,
      );
      if (_active?.patientId == user.id) {
        _active = _WatchTarget(
          patientId: user.id,
          patientName: user.name,
          caregiverNames: names,
        );
      }
      notifyListeners();
      unawaited(_resumeIfNeeded());
      return;
    }

    final links = [
      for (final link in sharing.forCaregiver(user.id))
        if (link.status == CareLinkStatus.accepted &&
            link.scopes.contains(ShareScope.zone))
          link,
    ];
    if (links.isEmpty) {
      session = ZoneSession(
        patientId: '',
        patientName: 'Pacjent',
        caregiverNames: [user.name],
        canEdit: false,
        signedIn: true,
      );
    } else {
      final link = links.first;
      session = ZoneSession(
        patientId: link.patientId,
        patientName: auth.userById(link.patientId)?.name ?? 'Pacjent',
        caregiverNames: [user.name],
        canEdit: false,
        signedIn: true,
      );
    }
    notifyListeners();
  }

  Future<void> pauseTracking() async {
    await _subscription?.cancel();
    _subscription = null;
    _active = null;
  }

  Future<String?> saveZone(SafeZone zone) async {
    await load();
    final label = zone.label.trim();
    if (label.isEmpty) return 'Podaj nazwę miejsca, na przykład Dom.';
    _zones[zone.patientId] = SafeZone(
      patientId: zone.patientId,
      label: label,
      latitude: zone.latitude,
      longitude: zone.longitude,
      radiusMeters: zone.radiusMeters
          .clamp(minSafeZoneRadius, maxSafeZoneRadius)
          .toInt(),
    );
    _presence[zone.patientId] = ZonePresence.unknown;
    await _persist();
    notifyListeners();
    if (isMonitoring(zone.patientId) && _active?.patientId == zone.patientId) {
      try {
        applyFix(await _location.current());
      } catch (error) {
        debugPrint('Nie udało się odświeżyć pozycji po zapisie strefy: $error');
      }
    }
    return null;
  }

  Future<String?> startMonitoring({
    required String patientId,
    required String patientName,
    required List<String> caregiverNames,
  }) async {
    await load();
    if (_zones[patientId] == null) {
      return 'Najpierw zapisz bezpieczną strefę.';
    }
    _active = _WatchTarget(
      patientId: patientId,
      patientName: patientName,
      caregiverNames: caregiverNames,
    );
    final error = await _beginUpdates();
    if (error != null) {
      _active = null;
      return error;
    }
    _monitoring[patientId] = true;
    await _persist();
    notifyListeners();
    return null;
  }

  Future<void> stopMonitoring(String patientId) async {
    _monitoring[patientId] = false;
    if (_active?.patientId == patientId) {
      await pauseTracking();
    }
    await _persist();
    notifyListeners();
  }

  Future<({GeoFix? fix, String? error})> readCurrentFix() async {
    final access = await _location.ensureAccess();
    if (access == LocationAccess.disabled) {
      return (fix: null, error: 'Włącz lokalizację w ustawieniach urządzenia.');
    }
    if (access != LocationAccess.granted) {
      return (
        fix: null,
        error: 'Zezwól na lokalizację, aby wskazać miejsce na mapie.',
      );
    }
    try {
      return (fix: await _location.current(), error: null);
    } catch (error) {
      debugPrint('Odczyt lokalizacji nie powiódł się: $error');
      return (fix: null, error: 'Nie udało się odczytać bieżącej lokalizacji.');
    }
  }

  void applyFix(GeoFix fix) {
    final active = _active;
    if (active == null) return;
    final zone = _zones[active.patientId];
    if (zone == null) return;
    final previous = _presence[active.patientId] ?? ZonePresence.unknown;
    final distance = distanceMeters(
      zone.latitude,
      zone.longitude,
      fix.latitude,
      fix.longitude,
    );
    final next = evaluatePresence(
      previous: previous,
      distanceMeters: distance,
      radiusMeters: zone.radiusMeters.toDouble(),
    );
    _fixes[active.patientId] = fix;
    _presence[active.patientId] = next;
    locationMessage = null;
    if (shouldNotifyCaregiver(previous, next)) {
      final alert = SafeZoneAlert(
        patientId: active.patientId,
        patientName: active.patientName,
        placeLabel: zone.label,
        radiusMeters: zone.radiusMeters,
        distanceMeters: distance.round(),
        at: fix.at,
        latitude: fix.latitude,
        longitude: fix.longitude,
        caregiverNames: List<String>.of(active.caregiverNames),
      );
      _alerts.insert(0, alert);
      if (_alerts.length > 20) _alerts.removeLast();
      unawaited(showZoneLeftNotification(alert));
    }
    unawaited(_persist());
    notifyListeners();
  }

  Future<void> markAllSeen() async {
    var changed = false;
    for (final alert in _alerts) {
      if (!alert.seen) {
        alert.seen = true;
        changed = true;
      }
    }
    if (!changed) return;
    await _persist();
    notifyListeners();
  }

  Future<void> _resumeIfNeeded() async {
    await load();
    final current = session;
    if (!current.signedIn || !current.canEdit) return;
    if (!isMonitoring(current.patientId)) return;
    if (zoneFor(current.patientId) == null) return;
    if (_subscription != null && _active?.patientId == current.patientId) {
      return;
    }
    _active = _WatchTarget(
      patientId: current.patientId,
      patientName: current.patientName,
      caregiverNames: current.caregiverNames,
    );
    final error = await _beginUpdates();
    if (error != null) {
      locationMessage = error;
      notifyListeners();
    }
  }

  Future<String?> _beginUpdates() async {
    final access = await _location.ensureAccess();
    if (access == LocationAccess.disabled) {
      return 'Włącz lokalizację w ustawieniach urządzenia.';
    }
    if (access != LocationAccess.granted) {
      return 'Zezwól na lokalizację, aby pilnować bezpiecznej strefy.';
    }
    await prepareZoneNotifications(requestPermission: true);
    try {
      applyFix(await _location.current());
    } catch (error) {
      locationMessage = 'Czekam na pierwszy odczyt lokalizacji.';
      debugPrint('Pierwszy odczyt lokalizacji nie powiódł się: $error');
    }
    await _subscription?.cancel();
    _subscription = _location.watch().listen(
      applyFix,
      onError: (Object error) {
        locationMessage = 'Odczyt lokalizacji został przerwany.';
        debugPrint('Strumień lokalizacji: $error');
        notifyListeners();
      },
    );
    return null;
  }

  Future<void> _read() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(storageKey);
      if (stored != null) _decode(stored);
    } catch (error) {
      debugPrint('Nie udało się wczytać bezpiecznej strefy: $error');
    } finally {
      isLoaded = true;
      notifyListeners();
    }
  }

  void _decode(String stored) {
    final decoded = jsonDecode(stored);
    if (decoded is! Map) return;
    final json = Map<String, dynamic>.from(decoded);
    _zones.clear();
    final zones = json['zones'];
    if (zones is List) {
      for (final item in zones) {
        if (item is! Map) continue;
        final zone = SafeZone.fromJson(Map<String, dynamic>.from(item));
        if (zone != null) _zones[zone.patientId] = zone;
      }
    }
    _alerts.clear();
    final alerts = json['alerts'];
    if (alerts is List) {
      for (final item in alerts) {
        if (item is! Map) continue;
        final alert = SafeZoneAlert.fromJson(Map<String, dynamic>.from(item));
        if (alert != null) _alerts.add(alert);
      }
    }
    _monitoring.clear();
    final monitoring = json['monitoring'];
    if (monitoring is Map) {
      for (final entry in monitoring.entries) {
        if (entry.value == true) _monitoring[entry.key.toString()] = true;
      }
    }
    _presence.clear();
    final presence = json['presence'];
    if (presence is Map) {
      for (final entry in presence.entries) {
        final value = entry.value;
        if (value is! String) continue;
        for (final item in ZonePresence.values) {
          if (item.name == value) _presence[entry.key.toString()] = item;
        }
      }
    }
    _fixes.clear();
    final fixes = json['fixes'];
    if (fixes is Map) {
      for (final entry in fixes.entries) {
        if (entry.value is! Map) continue;
        final fix = GeoFix.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
        if (fix != null) _fixes[entry.key.toString()] = fix;
      }
    }
  }

  Future<void> _persist() {
    final next = _pendingWrite.then((_) => _writeBody());
    _pendingWrite = next.catchError((Object error) {
      debugPrint('Nie udało się zapisać bezpiecznej strefy: $error');
    });
    return next;
  }

  Future<void> _writeBody() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        storageKey,
        jsonEncode({
          'zones': _zones.values.map((zone) => zone.toJson()).toList(),
          'alerts': _alerts.map((alert) => alert.toJson()).toList(),
          'monitoring': _monitoring,
          'presence': {
            for (final entry in _presence.entries) entry.key: entry.value.name,
          },
          'fixes': {
            for (final entry in _fixes.entries) entry.key: entry.value.toJson(),
          },
        }),
      );
    } catch (error) {
      debugPrint('Nie udało się zapisać bezpiecznej strefy: $error');
    }
  }
}
